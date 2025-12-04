// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Box
/// @notice A simple contract to store and retrieve a number, restricted to the owner.
contract Box is Ownable {
    /// @notice The stored number.
    uint256 private sNumber;

    /// @notice Emitted when the stored number is updated.
    /// @param newNumber The new value of the stored number.
    event NumberChanged(uint256 newNumber);

    /**
     * @notice Stores a new number in the contract.
     * @dev Only the owner can call this function.
     * @param newNumber The number to store.
     */
    function store(uint256 newNumber) public onlyOwner {
        sNumber = newNumber;
        emit NumberChanged(newNumber);
    }

    /**
     * @notice Retrieves the stored number.
     * @return The current value of the stored number.
     */
    function getNumber() external view returns (uint256) {
        return sNumber;
    }

    /**
     * @notice Initializes the contract. Sets the deployer as the initial owner.
     */
    constructor() Ownable(msg.sender){}
}