// SPDX-License-Identifier: MIT
pragma solidity = 0.8.23;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IHierarchicalDrawing.sol";
import "./interfaces/IMyNFT.sol";
import "./libraries/Sorting.sol";

/** 
 * @title Hierarchical drawing pools
 * @author SeekersAlliance
 * @notice This smart contract mitigates the problem of pull rates being dependent on the NFT supply counts,
 * @notice allowing for more freedom in game design while increasing long-term viability.
 * @notice Here we introduce a flexible hierarchical drawing pools architecture built upon the ERC-1155 standard,
 * @notice the game developers can customize pool probabilities according to their game use cases
 * @notice and launch updates and new releases while maintaining constant and fair pull rates.
 */
contract HierarchicalDrawing is AccessControl, IHierarchicalDrawing {

    uint32 constant UINT32_MAX = type(uint32).max;

    IMyNFT public nftContract;
    IVRFManager public vrfGenerator;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant FULFILLER_ROLE = keccak256("FULFILLER_ROLE");

    mapping (address => mapping (uint32 => uint32)) public usersDrawable;
    mapping (uint32 => UnitPoolInfo) public unitPoolsInfo;
    mapping (uint32 => DrawingPoolInfo) public drawingPoolsInfo;
    mapping (uint256 => RequestInfo) public requestsInfo;

    uint256 public requestNonce;
    uint32[] public existedUnit;
    uint32[] public existedDrawing;
    uint32[] public maxAmounts;
    uint32[] public remainings;
    uint256[] public ids;
    uint256[] public requestsQueue;

    constructor(
        address _initialAdmin, 
        address _nftContract
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdmin);
        _grantRole(MANAGER_ROLE, _initialAdmin);
        nftContract = IMyNFT(_nftContract);
    }

    /// @inheritdoc IHierarchicalDrawing
    function setVRFGenerator(address _vrfGenerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(hasRole(FULFILLER_ROLE, _vrfGenerator)) revert HasRoleAlready(_vrfGenerator, FULFILLER_ROLE);
        if(address(vrfGenerator) != address(0)) {
            revokeRole(FULFILLER_ROLE, address(vrfGenerator));
        }
        vrfGenerator = IVRFManager(_vrfGenerator);
        grantRole(FULFILLER_ROLE, _vrfGenerator);
    }

    /// @inheritdoc IHierarchicalDrawing
    function setTokenPool(uint256[] calldata _ids) external onlyRole(MANAGER_ROLE) {
        ids = _ids;
        emit SetTokenPool(_ids);
    }

    /// @inheritdoc IHierarchicalDrawing
    function setTokenMaxAmount(uint32[] calldata _maxAmounts) external onlyRole(MANAGER_ROLE) {
        if(ids.length == 0) revert EmptyIDs();
        if(ids.length != _maxAmounts.length) revert LengthNotMatch();
        
        maxAmounts = _maxAmounts;
        remainings = _maxAmounts;

        emit SetTokenMaxAmount(_maxAmounts);
    }

    /// @inheritdoc IHierarchicalDrawing
    function setUnitPool(uint32 _unitID, uint32[] calldata _probs) external onlyRole(MANAGER_ROLE) {
        UnitPoolInfo storage unit = unitPoolsInfo[_unitID];
        if(_probs.length != ids.length) revert LengthNotMatch();
        if (unit.enable) revert UnitPoolExisted(_unitID);

        unit.enable = true;
        unit.tree = buildOcTree(_probs);
        unit.treeHeight = getOctreeHeight(_probs.length);
        unit.probs = _probs;
        existedUnit.push(_unitID);

        emit SetUnitPool(_unitID);
    }

    /// @inheritdoc IHierarchicalDrawing
    function setDrawingPool(uint32 _poolID, uint32[] calldata _unitIDs, uint32[] calldata _probs) external onlyRole(MANAGER_ROLE) {
        DrawingPoolInfo storage pool = drawingPoolsInfo[_poolID];
        if(_unitIDs.length != _probs.length) revert LengthNotMatch();
        if (pool.enable) revert DrawingPoolExisted(_poolID);

        UnitPoolInfo memory unit;
        for(uint32 i;i<_unitIDs.length;i++) {
            unit = unitPoolsInfo[_unitIDs[i]];
            if(!unit.enable) revert UnitPoolExisted(_unitIDs[i]);
        }

        pool.accumulatedProbs = getAccumulatedArr(_probs);
        pool.enable = true;
        pool.units = _unitIDs;
        pool.probs = _probs;
        existedDrawing.push(_poolID);

        emit SetDrawingPool(_poolID);
    }

    /// @inheritdoc IHierarchicalDrawing
    function increaseDrawable(address _user, uint32[] calldata _poolsID, uint32[] calldata _increaseAmounts) external onlyRole(SELLER_ROLE) {
        if(_poolsID.length != _increaseAmounts.length) revert LengthNotMatch();
        for(uint256 i;i<_poolsID.length;i++) {
            usersDrawable[_user][_poolsID[i]] += _increaseAmounts[i];
        }
    }

    function decreaseDrawable(address _user, uint32[] calldata _poolsID, uint32[] calldata _decreaseAmounts) internal {
        if(_poolsID.length != _decreaseAmounts.length) revert LengthNotMatch();
        uint32 _poolID;
        for(uint256 i;i<_poolsID.length;i++) {
            if(_decreaseAmounts[i] == 0) revert ZeroAmount();
            _poolID = _poolsID[i];
            if(usersDrawable[_user][_poolID] < _decreaseAmounts[i]) revert DrawableNotEnough(_user, _poolID);
            usersDrawable[_user][_poolID] -= _decreaseAmounts[i];
        }
    }

    /// @inheritdoc IHierarchicalDrawing
    function sendRequest(uint32[] calldata _poolsID, uint32[] calldata _drawAmounts) public {
        address _requester = msg.sender;
        decreaseDrawable(_requester, _poolsID, _drawAmounts);

        uint256 _requestId = vrfGenerator.requestRandomWords(_requester);
        RequestInfo storage request = requestsInfo[_requestId];
        request.exists = true;
        request.requestSender = _requester;
        request.poolsID = _poolsID;
        request.amounts = _drawAmounts;

        requestsQueue.push(_requestId);
        emit RequestSent(_requestId, _requester);
    }

    /// @inheritdoc IHierarchicalDrawing
    function sendRequestBatch(uint32 requestNum, uint32[] calldata _poolsID, uint32[] calldata _drawAmounts) external {
        for(uint32 i;i<requestNum;i++) {
            sendRequest(_poolsID, _drawAmounts);
        }
    }

    /// @inheritdoc IHierarchicalDrawing
    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) external onlyRole(FULFILLER_ROLE) {
        RequestInfo storage request = requestsInfo[_requestId];
        if(!request.exists) revert RequestNotExist(_requestId);
        request.fulfilled = true;
        request.randomWords = _randomWords;

        emit RequestFulfilled(_requestId, _randomWords);
    }

    /// @inheritdoc IHierarchicalDrawing
    function execRequest() public onlyRole(EXECUTOR_ROLE) returns (uint256[] memory){
        if(pendingRequestNum() == 0) revert NoPendingRequest();

        uint256 _requestId = requestsQueue[requestNonce];
        RequestInfo storage request = requestsInfo[_requestId];
        if(!request.exists) revert RequestNotExist(_requestId);
        if(!request.fulfilled) revert RequestNotFulfilled(_requestId);

        address _receiver = request.requestSender;
        uint32[] memory _poolsID = request.poolsID;
        uint32[] memory _amounts = request.amounts;
        uint256 _randomWord = request.randomWords[0];
        uint256 totalAmount;
        for(uint256 i;i<_amounts.length;i++){
            totalAmount += _amounts[i];
        }

        uint256[] memory _ids = new uint256[](totalAmount);
        uint32 unitID;
        uint32 randomWord32;
        uint32 idx;
        uint256 idIndex;
        uint256 consumedRandomWord = _randomWord;
        for(uint256 i;i<_poolsID.length;i++) {
            for(uint256 j;j<_amounts[i];j++) {
                (consumedRandomWord, randomWord32) = getRandomWord32(consumedRandomWord);
                unitID = drawUnitPoolID(_poolsID[i], randomWord32);
                (consumedRandomWord, randomWord32) = getRandomWord32(consumedRandomWord);
                idIndex = drawTokenIndex(unitID, randomWord32);
                _ids[idx] = ids[idIndex];

                if(consumedRandomWord == 0) {
                    _randomWord = hash(_randomWord);
                    consumedRandomWord = _randomWord;
                }

                if(maxAmounts[idIndex] < UINT32_MAX) {
                    remainings[idIndex] --;
                    if(remainings[idIndex] == 0) {
                        removeTokenProb(idIndex);
                    }
                }
                idx ++;
            }
        }        
        
        if(totalAmount == 1) {
            nftContract.mint(_receiver, _ids[0], 1, "");
        } else {
            uint256[] memory sortedIDs = SortAlgorithms.quickSort(_ids);
            (uint256[] memory mintIDs, uint256[] memory mintAmounts) = count(sortedIDs);
            nftContract.mintBatch(_receiver, mintIDs, mintAmounts, "");
        }

        requestNonce ++;
        request.completed = true;

        emit RequestCompleted(_requestId, _receiver);
        return (_ids);
    }

    /// @inheritdoc IHierarchicalDrawing
    function execRequestBatch() external onlyRole(EXECUTOR_ROLE) {
        uint256 pending = pendingRequestNum();
        for(uint256 i; i<pending;i++) {
            execRequest();
        }
    }

    function drawUnitPoolID(uint32 _poolID, uint32 _randomWord) internal view returns(uint32 _unitID) {
        DrawingPoolInfo memory pool = drawingPoolsInfo[_poolID];
        uint32[] memory probs = pool.accumulatedProbs;

        uint256 unitsNum = pool.units.length;
        uint32 _randomNum = _randomWord % probs[unitsNum-1];
        for(uint256 i;i<unitsNum;i++) {
            _unitID = pool.units[i];
            if(_randomNum < probs[i]) {
                return _unitID;
            }
        }
    }
    
    function drawTokenIndex(uint32 _unitID, uint32 _randomWord) internal view returns(uint256 index) {
        UnitPoolInfo memory unit = unitPoolsInfo[_unitID];
        PackedArray.PackedArray32 memory tree = unit.tree;
        uint32[] memory probs = unit.probs;
        uint8 height = unit.treeHeight;
        uint32 cur_prob = _randomWord % PackedArray.get(tree,0);
        uint32 node_prob;
        uint256 tree_length = tree.nums;
        uint256 root_node_idx;
        uint256 next_node_idx;
 
        for(uint8 h; h<height; h++) {
            for(uint8 j=1;j<=8;j++) {
                if(h==height-1) {
                    next_node_idx = 8*root_node_idx+j-tree_length;
                    node_prob = probs[next_node_idx];
                    if(cur_prob >= node_prob) {
                        cur_prob -= node_prob;
                    } else {
                        return next_node_idx;
                    }
                } else {
                    next_node_idx = 8*root_node_idx+j;
                    node_prob = PackedArray.get(tree,next_node_idx);
                    if(cur_prob >= node_prob) {
                        cur_prob -= node_prob;
                    }
                    else {
                        root_node_idx = next_node_idx;
                        break;
                    }
                }
            }
        }
    }

    function removeTokenProb(uint256 _index) internal {
        uint32[] memory _existedUnit = existedUnit;

        uint32 _unitID;
        UnitPoolInfo memory unit;
        for(uint256 i;i<_existedUnit.length;i++) {
            _unitID = _existedUnit[i];
            unit = unitPoolsInfo[_unitID];

            if(unit.probs[_index] != 0) {
                updateTokenProb(_unitID, _index, 0);
                checkUnitStatus(_unitID);
            }
        }
    }

    function closeUnitPool(uint32 _unitID) internal {
        UnitPoolInfo storage unit = unitPoolsInfo[_unitID];

        uint32[] memory _units;
        for(uint256 i;i<existedDrawing.length;i++) {
            DrawingPoolInfo storage pool = drawingPoolsInfo[existedDrawing[i]];
            _units = pool.units;
            for(uint256 j;j<_units.length;j++) {
                if(_units[j] == _unitID) {
                    pool.probs[j] = 0;
                    pool.accumulatedProbs = getAccumulatedArr(pool.probs);
                    break;
                }
            }
        }

        pop(existedUnit, _unitID);
        unit.enable = false;
    }

    function updateTokenProb(uint32 _unitID, uint256 _index, uint32 _prob) internal {
        UnitPoolInfo storage unit = unitPoolsInfo[_unitID];
        PackedArray.PackedArray32 memory tree = unit.tree;

        uint8 height = unit.treeHeight;
        uint32 pre_prob = unit.probs[_index];
        uint32 root_prob;
        uint256 root_node = _index + tree.nums;
        for(uint8 i;i<height;i++) {
            root_node = (root_node-1) >> 3;
            root_prob = PackedArray.get(tree, root_node);
            tree = PackedArray.set(tree, root_node, root_prob+_prob-pre_prob);
        }
        unit.probs[_index] = _prob;
        unit.tree = tree;
    }

    function checkUnitStatus(uint32 _unitID) internal {
        UnitPoolInfo memory unit = unitPoolsInfo[_unitID];
        if(PackedArray.get(unit.tree,0) == 0) {
            closeUnitPool(_unitID);
        }
    }

    function getOctreeHeight(uint256 _nums) internal pure returns(uint8 h){
        h = 1;
        while(8**h < _nums) {
            h++;
        }
        return h;
    }

    function buildOcTree(uint32[] calldata _probs) internal pure returns (PackedArray.PackedArray32 memory) {
        // if(_probs.length != ids.length) revert LengthNotMatch();
        uint32 rootValue;
        uint32 treeHeight = getOctreeHeight(_probs.length);
        uint256 rootIndex;
        uint256 rowElements;
        uint256 shift_index;
        uint256 cur_index;
        uint256 nums = _probs.length;
        uint256 treeElements = (8**treeHeight-1)/7;
        uint32[] memory ocTree = new uint32[](treeElements);

        for(uint32 h; h<treeHeight; h++) {
            rowElements = 8**(treeHeight-h);
            shift_index = (rowElements-1)/7;
            for(uint256 i;i<rowElements;i++) {
                cur_index = i+shift_index;
                if(h!=0) {
                    rootValue += ocTree[cur_index];
                } else {
                    if(i == nums) break;
                    rootValue += _probs[i];
                }

                if(cur_index%8 == 0 || i == (nums-1)) {
                    rootIndex = (cur_index-1) >> 3;
                    ocTree[rootIndex] = rootValue;
                    rootValue = 0;
                }   
            }
        }

        PackedArray.PackedArray32 memory pooledResult = PackedArray.pack(ocTree);

        return pooledResult;
    }

    /// @inheritdoc IHierarchicalDrawing
    function getTokenPoolInfo() external view returns(uint256[] memory) {
        return (ids);
    }

    /// @inheritdoc IHierarchicalDrawing
    function getTokenMaxAmounts() external view returns(uint32[] memory) {
        return (maxAmounts);
    }

    /// @inheritdoc IHierarchicalDrawing
    function getTokenRemainings() external view returns(uint32[] memory) {
        return (remainings);
    }

    /// @inheritdoc IHierarchicalDrawing
    function getTokenInfo(uint256 _id) external view returns(bool existed, uint256 index, uint32 maxAmount, uint32 remaining) {
        for(uint256 i;i<ids.length;i++) {
            if(ids[i] == _id) {
                return(true, i, maxAmounts[i], remainings[i]);
            }
        }
        return (false, 0,0,0);
    }

    /// @inheritdoc IHierarchicalDrawing
    function getExistedUnitPool() external view returns(uint32[] memory unitPools) {
        return existedUnit;
    }

    /// @inheritdoc IHierarchicalDrawing
    function getExistedDrawingPool() external view returns(uint32[] memory drawingPools) {
        return existedDrawing;
    }
    
    /// @inheritdoc IHierarchicalDrawing
    function getUnitPoolInfo(uint32 _unitID) external view returns(uint32[] memory probs, PackedArray.PackedArray32 memory tree) {
        UnitPoolInfo memory unit = unitPoolsInfo[_unitID];
        return (unit.probs, unit.tree);
    }

    /// @inheritdoc IHierarchicalDrawing
    function getPoolInfo(uint32 _poolID) external view returns(uint32[] memory unitPools, uint32[] memory probs, uint32[] memory accumulatedProbs) {
        DrawingPoolInfo memory pool = drawingPoolsInfo[_poolID];
        return (pool.units, pool.probs, pool.accumulatedProbs);
    }

    /// @inheritdoc IHierarchicalDrawing
    function pendingRequestNum() public view returns(uint256 pending) {
        return (requestsQueue.length - requestNonce);
    }

    /// @inheritdoc IHierarchicalDrawing
    function getUserDrawable(address _user, uint32 _poolID) external view returns(uint32 amount) {
        return usersDrawable[_user][_poolID];
    }

    /// @inheritdoc IHierarchicalDrawing
    function getReuqestQueue() external view returns(uint256[] memory queue) {
        return requestsQueue;
    }

    /// @inheritdoc IHierarchicalDrawing
    function getLastRequestId() external view returns(uint256 requestId) {
        return requestsQueue[requestNonce];
    }

    /// @inheritdoc IHierarchicalDrawing
    function getRequestInfo(uint256 _requestId) external view returns(RequestInfo memory) {
        return requestsInfo[_requestId];
    }

    function getAccumulatedArr(uint32[] memory _arr) internal pure returns(uint32[] memory result) {
        uint32 _totalProb;
        result = new uint32[](_arr.length);
        for(uint256 i;i<_arr.length;i++) {
            _totalProb += _arr[i];
            result[i] = _totalProb;
        }
        return result;
    }

    function getRandomWord32(uint256 _randomWord) internal pure returns(uint256, uint32){
        uint32 randomWord32 = uint32(_randomWord);
        _randomWord >>= 32;
        return (_randomWord, randomWord32);
    }

    function hash(uint256 _randomWord) internal pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(_randomWord)));
    }

    function count(uint256[] memory _sortedArr) internal pure returns(uint256[] memory mintIDs, uint256[] memory mintAmounts) {
        if(_sortedArr.length == 0) {
            return(_sortedArr, _sortedArr);
        }
        
        uint256 uniqueIdNum = 1;
        for(uint256 i = 1; i < _sortedArr.length; i++) {
            if(_sortedArr[i] != _sortedArr[i-1]) {
                uniqueIdNum ++;
            }
        }

        mintIDs = new uint256[](uniqueIdNum);
        mintAmounts = new uint256[](uniqueIdNum);
        uint256 curID = _sortedArr[0];
        uint256 curIndex;
        mintIDs[curIndex] = curID;

        for(uint256 i; i < _sortedArr.length; i++) {
            if(_sortedArr[i] != curID) {
                curID = _sortedArr[i];
                curIndex ++;
                mintIDs[curIndex] = curID;
            }
            mintAmounts[curIndex] ++;
        }
        return (mintIDs, mintAmounts);
    }

    function pop(uint32[] storage _arr, uint32 _id) internal {
        uint256 nums = _arr.length;
        for(uint256 i; i<nums;i++) {
            if (_arr[i] == _id) {
                _arr[i] = _arr[nums-1];
                _arr.pop();
                break;
            }
        }
    }
}