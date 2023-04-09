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
