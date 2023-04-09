//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

interface IOwnableEvents {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract Ownable is IOwnableEvents {
    // TODO how do I properly define that we support interface 0x7f5828d0?

    address public owner;

    /// Errors
    error NotOwner();

    /// @notice Modifier to enforce ownership control
    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external onlyOwner {
        address previousOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred({
            previousOwner: previousOwner,
            newOwner: owner
        });
    }
}