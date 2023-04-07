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
    /// @notice Boss structure
    /// @dev The parameters should be generated randomly
    /// @param _name Name of the Boss
    /// @param _hp Life points of the Boss
    /// @param _damage Damage inflicted by the Boss on each attack
    /// @param _xpReward Experience reward split between all fighters
    struct Boss {
        string name;
        uint256 hp;
        uint256 damage;
        uint256 xpReward;
    }
    error BossIsNotDead();

    /// @notice Current Boss players can fight against
    Boss public boss;

    /// @notice Instantiate a new contract and set its owner
    /// @dev `owner` is defined in the Ownable interface
    /// @param _owner New owner of the contract
    constructor(address _owner) {
        owner = _owner;
    }

    //////////////////////
    /// All about the boss
    //////////////////////
    
    /// @notice Get the name of the boss
    /// @return string Name of the boss
    function bossName() public view returns(string memory) {
        return boss.name;
    }
    
    /// @notice Get the hp of the boss
    /// @return uint256 Current HP of the boss
    function bossHp() public view returns(uint256) {
        return boss.hp;
    }
    
    /// @notice Get the damage inflicted by the boss on each attack
    /// @return uint256 Damage inflicted
    function bossDamage() public view returns(uint256) {
        return boss.damage;
    }
    
    /// @notice Get the xp reward split between all fighters when the boss dies
    /// @return uint256 XP reward
    function bossXpReward() public view returns(uint256) {
        return boss.xpReward;
    }

    /// @notice Check if the Boss is dead
    /// @dev hp is unsigned, we don't check negative values
    /// @return bool true if dead, false otherwise
    function isBossDead() view public returns(bool) {
        return boss.hp == 0;
    }

    /// @notice Hit the Boss
    /// @dev We make sure that hp does not go below 0 since it is unsigned
    /// @param _damage The amount of hp the Boss must lose
    function hitBoss(uint256 _damage) public {
        boss.hp = _damage >= boss.hp ? 0 : boss.hp - _damage;
    }

    /// @notice Set a new Boss
    /// @dev Only for the owner, and if the boss is already dead
    /// @param _boss New boss to set
    function setBoss(Boss memory _boss) public onlyOwner {
        if (this.isBossDead()) {
            boss = _boss;
        } else {
            revert BossIsNotDead();
        }
    }
}
