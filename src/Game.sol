//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

contract Boss {
    string public name;
    uint256 public hp;
    uint256 public damage;
    uint256 public xpReward;

    /// @notice Instantiate a new Boss object
    /// @dev The parameters should be generated randomly
    /// @param _name Name of the Boss
    /// @param _hp Life points of the Boss
    /// @param _damage Damage inflicted by the Boss on each attack
    /// @param _xpReward Experience reward split between all fighters
    constructor(string memory _name, uint256 _hp, uint256 _damage, uint256 _xpReward) {
        name = _name;
        hp = _hp;
        damage = _damage;
        xpReward = _xpReward;
    }

    /// @notice Check if the Boss is dead
    /// @dev hp is unsigned, we don't check negative values
    /// @return bool true if dead, false otherwise
    function isDead() view public returns(bool) {
        return hp == 0;
    }

    /// @notice Hit the Boss
    /// @dev We make sure that hp does not go below 0 since it is unsigned
    /// @param _damage The amount of hp the Boss must lose
    function hit(uint256 _damage) public {
        hp = _damage >= hp ? 0 : hp - _damage;
    }
}

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
