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

/// @title World Of Ledger - Characters
/// @author Yacine B. Badiss
/// @notice Internal contract to handle characters
/// @dev Internal contract to handle characters
contract _Character is ICharacter {
    /// @notice Track all the characters of the game
    mapping(address => Character) public characters;

    /// @notice Base modifier for characters' max hp and physical damage
    uint256 public immutable baseEndurance;
    /// @notice Base modifier for characters' magical ability
    uint256 public immutable baseIntelligence;

    /// @notice Instantiate a new contract and set the base modifiers
    /// @dev Not meant to be deployed by itself, use with `Game` contract
    /// @param _baseEndurance Base modifier for characters' max hp and physical damage
    /// @param _baseIntelligence Base modifier for characters' magical ability
    constructor(uint256 _baseEndurance, uint256 _baseIntelligence) {
        baseEndurance = _baseEndurance;
        baseIntelligence = _baseIntelligence;
    }

    ////////////////////////////////////////////////////////////////////////
    /// Character actions
    ////////////////////////////////////////////////////////////////////////

    /// @notice Fight with the Boss using the character of the caller
    /// @dev Implement in the main contract.
    function fightBoss() external virtual onlyAliveCharacter {}

    /// @notice Heal a character
    /// @dev Only for characters alive, and cannot self-heal. Implement in the main contract.
    /// @param _targetCharacter Character to heal
    function healCharacter(address _targetCharacter) external virtual onlyAliveCharacter onlyExperiencedCharacter {}

    /// @notice Register a new character for the caller
    function newCharacter() external {
        if (characters[msg.sender].created) revert CharacterAlreadyCreated();

        characters[msg.sender] = buildCharacter(block.prevrandao);
        emit CharacterSpawned({
            characterAddress: msg.sender,
            maxHp: characters[msg.sender].maxHp,
            physicalDamage: characters[msg.sender].physicalDamage,
            heal: characters[msg.sender].heal
        });
    }

    ////////////////////////////////////////////////////////////////////////
    /// Helper functions
    ////////////////////////////////////////////////////////////////////////

    /// @notice Modifier to only allow characters that exist and are currently alive
    modifier onlyAliveCharacter {
        // Don't allow using a character not created
        if (!isCharacterCreated(msg.sender)) revert CharacterNotCreated();
        // Don't allow using a character that is not alive
        if (!isCharacterAlive(msg.sender)) revert CharacterIsDead();
        _;
    }

    /// @notice Modifier to only allow characters that have earned xp
    modifier onlyExperiencedCharacter {
        if (characters[msg.sender].xp == 0) revert CharacterNotExperienced();
        _;
    }

    /// @notice Helper function to build character attributes given a seed
    function buildCharacter(uint256 _seed) public view returns (Character memory) {
        uint256 enduranceBonus = _seed % 6;
        uint256 intelligenceBonus = 5 - enduranceBonus;

        return Character({
            created: true,
            maxHp: 100 * (baseEndurance + enduranceBonus),
            physicalDamage: 10 * (baseEndurance + enduranceBonus),
            heal: 10 * (baseIntelligence + intelligenceBonus),
            hp: 100 * (baseEndurance + enduranceBonus),
            xp: 0
        });
    }

    /// @notice Indicates if the target address has already created a Character
    /// @param _characterAddress Address of the Character to check
    function isCharacterCreated(address _characterAddress) public view returns (bool) {
        return characters[_characterAddress].created;
    }

    /// @notice Indicates if the target Character is alive
    /// @param _characterAddress Address of the Character to check
    function isCharacterAlive(address _characterAddress) public view returns (bool) {
        return characters[_characterAddress].hp > 0;
    }

    /// @notice Indicates if the target Character can heal others
    /// @param _characterAddress Address of the Character to check
    function canCharacterHeal(address _characterAddress) public view returns (bool) {
        return characters[_characterAddress].xp > 0;
    }

    /// @notice Get the max HP of the character
    /// @param _characterAddress Address of the Character to check
    /// @return uint256 Max HP of the character
    function characterMaxHp(address _characterAddress) public view returns (uint256) {
        return characters[_characterAddress].maxHp;
    }

    /// @notice Get the physical damage the character deals
    /// @param _characterAddress Address of the Character to check
    /// @return uint256 Physical Damage of the character
    function characterPhysicalDamage(address _characterAddress) public view returns (uint256) {
        return characters[_characterAddress].physicalDamage;
    }

    /// @notice Get the amount of healing provided by the character
    /// @param _characterAddress Address of the Character to check
    /// @return uint256 Heal of the character
    function characterHeal(address _characterAddress) public view returns (uint256) {
        return characters[_characterAddress].heal;
    }

    /// @notice Get the current HP of the character
    /// @param _characterAddress Address of the Character to check
    /// @return uint256 Current HP of the character
    function characterHp(address _characterAddress) public view returns (uint256) {
        return characters[_characterAddress].hp;
    }

    /// @notice Get the current XP of the character
    /// @param _characterAddress Address of the Character to check
    /// @return uint256 Current XP of the character
    function characterXp(address _characterAddress) public view returns (uint256) {
        return characters[_characterAddress].xp;
    }

    /// @notice Calculate the amount of damage dealt based on remaining hp
    /// @dev Always use to avoid arithmetic errors
    /// @param _damage Amount of damage we're trying to deal
    /// @param _hp Remaining hp
    function calculateDamageDealt(uint256 _damage, uint256 _hp) public pure returns (uint256) {
        return _damage >= _hp ? _hp : _damage;
    }

    /// @notice Calculate the amount of healing the target character will receive
    /// @dev Always use to avoid arithmetic errors
    /// @param _heal Amount of healing we're trying to provide
    /// @param _targetCharacter Character to heal
    function calculateHpHealed(uint256 _heal, Character memory _targetCharacter) public pure returns (uint256) {
        uint256 missingHp = _targetCharacter.maxHp - _targetCharacter.hp;
        return missingHp >= _heal ? _heal : missingHp;
    }
}