// SPDX-License-Identifier: MIT
pragma solidity = 0.8.23;

import "../libraries/PackedArray.sol";
import "../interfaces/IVRFManager.sol";

/**
 * @title Interface of HierarchicalDrawing.sol
 */
interface IHierarchicalDrawing {

    event SetTokenPool(uint256[] ids);
    event SetTokenMaxAmount(uint32[] maxAmounts);
    event SetUnitPool(uint32 unitPoolID);
    event SetDrawingPool(uint32 drawingPoolID);
    event RequestSent(uint256 requestId, address _requester);
    event RequestFulfilled(uint256 indexed requestId, uint256[] randomWords);
    event RequestCompleted(uint256 indexed requestId, address indexed requester);
    
    error EmptyIDs();
    error LengthNotMatch();
    error TokenExisted(uint256);
    error TokenNotExist(uint256);
    error UnitPoolExisted(uint32);
    error UnitPoolNotExist(uint32);
    error DrawingPoolExisted(uint32);
    error DrwaingPoolNotExist(uint32);
    error DrawableNotEnough(address, uint32);
    error RequestNotExist(uint256);
    error RequestNotFulfilled(uint256);
    error NoPendingRequest();
    error HasRoleAlready(address, bytes32);
    error ZeroAmount();

    struct UnitPoolInfo {
        bool enable;
        uint8 treeHeight;
        uint32[] probs;
        PackedArray.PackedArray32 tree;
    }

    struct DrawingPoolInfo {
        bool enable;
        uint32[] units;
        uint32[] probs;
        uint32[] accumulatedProbs;
    }

    struct RequestInfo {
        bool exists;
        bool fulfilled;
        bool completed;
        address requestSender;
        uint32[] poolsID;
        uint32[] amounts;
        uint256[] randomWords;
    }

    /** 
     * @notice set vrf generator
     * @notice Only admin role can call this function
     * @param _vrfGenerator address of vrf generator contract
     */
    function setVRFGenerator(address _vrfGenerator) external;

    /** 
     * @notice set token pool
     * @notice Only manager role can call this function
     * @param _ids array of token ID
     * @dev Token IDs should not be duplicated.
     */
    function setTokenPool(uint256[] calldata _ids) external;
    
    /** 
     * @notice set token max amount
     * @notice Only manager role can call this function
     * @param _maxAmounts max amount of token ID
     * @dev If the amount sets as 2**32-1, it means there is no limit on the quantity, max amount will be 2**256-1.
     */
    function setTokenMaxAmount(uint32[] calldata _maxAmounts) external;

    /** 
     * @notice set unit pool
     * @notice Only manager role can call this function
     * @param _unitID uint pool ID
     * @param _probs array of probabilites corresponding to token IDs
     * @dev if some tokens should not draw from this unit pool, just set the probability as 0.
     */
    function setUnitPool(uint32 _unitID, uint32[] calldata _probs) external;
    
    /** 
     * @notice set drawing pool
     * @notice Only manager role can call this function
     * @param _poolID drawing pool ID
     * @param _unitIDs array of the unit pool IDs
     * @param _probs array of probabilites corresponding to unit pools
     */
    function setDrawingPool(uint32 _poolID, uint32[] calldata _unitIDs, uint32[] calldata _probs) external;

    /** 
     * @notice Increase the drawable amount of specified user
     * @notice Only seller role can call this function
     * @param _user the address of the user
     * @param _poolsID array of the request drawing pools
     * @param _increaseAmounts array of the increasing amounts corresponding to drawing pools
     * @dev manager can call this function to increase the drawble amount after player bought the pack.
     */
    function increaseDrawable(address _user, uint32[] calldata _poolsID, uint32[] calldata _increaseAmounts) external;

    /** 
     * @notice send request
     * @param _poolsID array of drawing pool IDs
     * @param _drawAmounts array of the draw amount 
     * @dev player can call this function to request the draw.
     */
    function sendRequest(uint32[] calldata _poolsID, uint32[] calldata _drawAmounts) external;
    

    function sendRequestBatch(uint32 requestNum, uint32[] calldata _poolsID, uint32[] calldata _drawAmounts) external;
    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) external;
    function execRequest() external returns (uint256[] memory);
    function execRequestBatch() external;

    /**
     * @notice get user drawable amount
     */
    function getUserDrawable(address _user, uint32 _poolID) external view returns(uint32);
    function getTokenPoolInfo() external view returns(uint256[] memory ids);    
    function getTokenMaxAmounts() external view returns(uint32[] memory maxAmounts);
    function getTokenRemainings() external view returns(uint32[] memory remainings);
    function getTokenInfo(uint256 _id) external view returns(bool existed, uint256 index, uint32 maxAmount, uint32 remaining);
    function getExistedUnitPool() external view returns(uint32[] memory unitPools);
    function getExistedDrawingPool() external view returns(uint32[] memory drawingPools);
    function getUnitPoolInfo(uint32 _unitID) external view returns(uint32[] memory probs, PackedArray.PackedArray32 memory tree);
    function getPoolInfo(uint32 _poolID) external view returns(uint32[] memory unitPools, uint32[] memory probs, uint32[] memory accumulatedProbs);
    function pendingRequestNum() external view returns(uint256 pending);
    function getReuqestQueue() external view returns(uint256[] memory queue);
    function getLastRequestId() external view returns(uint256 requestId);
    function getRequestInfo(uint256 _requestId) external view returns(RequestInfo memory);
}