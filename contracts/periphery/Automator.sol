// SPDX-License-Identifier: MIT
pragma solidity = 0.8.23;

import "../interfaces/IHierarchicalDrawing.sol";
import "@chainlink/contracts/src/v0.8/automation/interfaces/ILogAutomation.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";

/** 
 * @notice This contract uses Chainlink product: Automation
 * @notice This Automation contract monitors the event RequestFulfilled from our drawing contract,
 * @notice when the event is emitted, this contract will automatically call execRequest to execute the request.
 */

contract Automator is ILogAutomation, OwnerIsCreator {

    IHierarchicalDrawing drawingContract;

    constructor(address _upkeepContract) {
        drawingContract = IHierarchicalDrawing(_upkeepContract);
    }
    
    function setUpKeepContract(address _upkeepContract) external onlyOwner {
        drawingContract = IHierarchicalDrawing(_upkeepContract);
    }

    function checkLog(
        Log calldata /*log*/,
        bytes memory /*checkData*/
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        drawingContract.execRequest();
    }

    function bytes32ToAddress(bytes32 _address) public pure returns (address) {
        return address(uint160(uint256(_address)));
    }

    function bytes32ToUint256(bytes32 data) public pure returns (uint256) {
        // Convert bytes32 to uint256 by reinterpreting the raw bytes
        return uint256(data);
    }
}