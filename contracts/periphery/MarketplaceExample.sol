// SPDX-License-Identifier: MIT
pragma solidity = 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IHierarchicalDrawing.sol";

contract MarketplaceReceiver is Ownable {

    error InvalidAmount();
    error InsufficientAllowance();
    error InsufficientBalance();

    event PackPurchased(address indexed buyer, uint32 amount);

    struct PackInfo {
        uint256 basePrice;
        uint32[] poolsID;
        uint32[] amounts;
    }

    mapping (address => uint256) public totalAmount;
    mapping (uint32 => PackInfo) public packsInfo;

    address public basePaymentToken;
    IHierarchicalDrawing public drawContract;
    
    constructor(
        address _basePaymentToken,
        address _initialAdmin
    ) Ownable(_initialAdmin){
        basePaymentToken = _basePaymentToken;
    }
    
    function setDrawContract(address _drawContract) public onlyOwner {
        drawContract = IHierarchicalDrawing(_drawContract);
    }

    // @dev Function to set the pack
    function setPack(uint32 _packID, uint256 _packPrice, uint32[] calldata _poolsID, uint32[] calldata _amounts) external onlyOwner {
        packsInfo[_packID].basePrice = _packPrice;
        packsInfo[_packID].poolsID = _poolsID;
        packsInfo[_packID].amounts = _amounts;
    }

    // Function to purchase a game pack
    function purchasePack(address _token, uint32 _packID, uint32 _packAmounts) external {
        uint256 basePrice = packsInfo[_packID].basePrice;
        uint256 totalPayment;
        address purchaser = msg.sender;
        ERC20 paymentToken = ERC20(_token);

        if(_packAmounts == 0) revert InvalidAmount();

        totalPayment = _packAmounts*basePrice;
        
        /// @notice Check if the purchaser has enough allowance and balance
        if(paymentToken.allowance(purchaser, address(this)) < totalPayment) revert InsufficientAllowance();
        if(paymentToken.balanceOf(purchaser) < totalPayment) revert InsufficientBalance();

        // Transfer tokens from buyer to contract
        paymentToken.transferFrom(purchaser, address(this), totalPayment);
        setPurchasedInfo(purchaser, _packID, _packAmounts);

        emit PackPurchased(purchaser, _packAmounts);
    }

    function setPurchasedInfo(
        address _purchaser, 
        uint32 _packID,
        uint32 _packAmounts
    ) internal {
        uint32[] memory _amounts = packsInfo[_packID].amounts;
        uint32[] memory totalAmounts = new uint32[](_amounts.length);

        for(uint256 i; i<_amounts.length; i++) {
            totalAmounts[i] = _amounts[i]*_packAmounts;
        }

        // Call the increaseDrawable function in the Drawing contract
        drawContract.increaseDrawable(_purchaser, packsInfo[_packID].poolsID, totalAmounts); 
    }
    
    // Function for the owner to withdraw funds from the contract
    function withdrawFunds(address _token, uint256 _amount) external onlyOwner {
        ERC20 withdrawToken = ERC20(_token);

        if(withdrawToken.balanceOf(address(this)) < _amount) revert InsufficientBalance();

        // Transfer funds to the owner
        withdrawToken.transfer(owner(), _amount);
    }

    /// @notice Function to withdraw Native from the contract
    function withdrawNative() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}