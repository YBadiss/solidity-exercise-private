//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

interface IBossEvents {
    /// @dev This emits when the Boss is created.
    event BossSpawned(string indexed bossName, uint256 maxHp, uint256 damage, uint256 xpReward);
    /// @dev This emits when the Boss is hit.
    event BossIsHit(string indexed bossName, address indexed characterAddress, uint256 bossHp, uint256 damageDealt);
    /// @dev This emits when the Boss dies.
    event BossKilled(string indexed bossName, address indexed characterAddress);
}

interface IBoss is IBossEvents {
    /// @notice Boss structure
    /// @param name Name of the Boss
    /// @param maxHp Max HP of the Boss
    /// @param hp Curernt HP of the Boss
    /// @param damage Damage inflicted by the Boss on each attack
    /// @param xpReward Experience reward split between all fighters
    struct Boss {
        string name;
        uint256 maxHp;
        uint256 hp;
        uint256 damage;
        uint256 xpReward;
    }

    /// Errors
    error BossIsNotDead();
    error BossIsDead();
}

contract _Boss is IBoss {
    /// @notice Current Boss characters can fight against
    Boss public boss;

    /// @notice Set a new Boss
    /// @dev Only if the boss is already dead
    /// @param _boss New boss to set
    function _setBoss(Boss memory _boss) internal {
        if (!this.isBossDead()) revert BossIsNotDead();

        boss = _boss;
        emit BossSpawned({
            bossName: boss.name,
            maxHp: boss.maxHp,
            damage: boss.damage,
            xpReward: boss.xpReward
        });
    }

    /// @notice Get the name of the boss
    /// @return string Name of the boss
    function bossName() external view returns(string memory) {
        return boss.name;
    }
    
    /// @notice Get the max HP of the boss
    /// @return uint256 Max HP of the boss
    function bossMaxHp() external view returns(uint256) {
        return boss.maxHp;
    }
    
    /// @notice Get the hp of the boss
    /// @return uint256 Current HP of the boss
    function bossHp() external view returns(uint256) {
        return boss.hp;
    }
    
    /// @notice Get the damage inflicted by the boss on each attack
    /// @return uint256 Damage inflicted
    function bossDamage() external view returns(uint256) {
        return boss.damage;
    }
    
    /// @notice Get the xp reward split between all fighters when the boss dies
    /// @return uint256 XP reward
    function bossXpReward() external view returns(uint256) {
        return boss.xpReward;
    }

    /// @notice Check if the Boss is dead
    /// @dev hp is unsigned, we don't check negative values
    /// @return bool true if dead, false otherwise
    function isBossDead() view public returns(bool) {
        return boss.hp == 0;
    }
}