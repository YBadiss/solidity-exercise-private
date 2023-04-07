//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

contract Ownable {
    address public owner;

    error NotOwner();

    /// @notice Modifier to enforce ownership control
    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Set owner of contract, can only be done by the current owner
    /// @param newOwner New owner of the contract
    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

/// @title World Of Ledger
/// @author Yacine B. Badiss
/// @notice Create a character linked to your address and fight monsters!
/// @dev Main contract controlling the game flow
contract Game is Ownable {

    /// @notice Instantiate a new contract and set its owner
    /// @dev `owner` is defined in the Ownable interface
    /// @param _owner New owner of the contract
    constructor(address _owner) {
        owner = _owner;
    }
}
