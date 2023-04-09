//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

interface ICharacterEvents {
    /// @dev This emits when the Character is created.
    event CharacterSpawned(address indexed characterAddress, uint256 maxHp, uint256 physicalDamage, uint256 heal);
    /// @dev This emits when the Character is hit.
    event CharacterIsHit(address indexed characterAddress, string indexed bossName, uint256 characterHp, uint256 damageDealt);
    /// @dev This emits when the Character is hit.
    event CharacterHealed(address indexed characterAddress, address indexed healerAddress, uint256 characterHp, uint256 healAmount);
    /// @dev This emits when the Character receives xp rewards.
    event CharacterRewarded(address indexed characterAddress, string indexed bossName, uint256 xpReward, uint256 totalDamageDealt);
    /// @dev This emits when the Character dies.
    event CharacterKilled(address indexed characterAddress, string indexed bossName);
}

interface ICharacter is ICharacterEvents {
    /// @notice Character structure
    /// @dev The parameters should be generated randomly
    /// @param created Whether the Character is empty or not
    /// @param maxHp Max HP of the character
    /// @param physicalDamage Damage the character deals on attack
    /// @param heal HP healed by the character
    /// @param hp Current HP of the character
    /// @param xp Experience earned by the Character
    struct Character {
        bool created;
        uint256 maxHp;
        uint256 physicalDamage;
        uint256 heal;
        uint256 hp;
        uint256 xp;
    }

    /// Errors
    error CharacterNotCreated();
    error CharacterAlreadyCreated();
    error CharacterCannotSelfHeal();
    error CharacterNotExperienced();
    error CharacterIsDead();
}
