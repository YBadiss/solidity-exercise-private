//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

interface ICharacterEvents {
    /// @dev This emits when the Character is created.
    event CharacterSpawned(address indexed characterAddress, uint32 maxHp, uint32 physicalDamage, uint32 heal);
    /// @dev This emits when the Character is hit.
    event CharacterIsHit(address indexed characterAddress, string indexed bossName, uint32 characterHp, uint32 damageDealt);
    /// @dev This emits when the Character is hit.
    event CharacterHealed(address indexed characterAddress, address indexed healerAddress, uint32 characterHp, uint32 healAmount);
    /// @dev This emits when the Character receives xp rewards.
    event CharacterRewarded(address indexed characterAddress, string indexed bossName, uint32 xpReward, uint32 totalDamageDealt);
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
        uint32 maxHp;
        uint32 physicalDamage;
        uint32 heal;
        uint32 hp;
        // The xp will grow by a max of uint32 for each Boss killed, which means a Character has to kill
        // 2^32 Bosses with `xpReward == uint32.max` alone to fill up this XP counter.
        // That's beyond the scope of this project.
        uint64 xp;
    }

    /// @notice Wrapper structure to return characters with their address
    /// @param addr Address of the character
    /// @param Character Character
    struct AddressedCharacter {
        address addr;
        Character character;
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

    /// @notice Tracks characters are active
    address[] public activeAddresses;

    /// @notice Get all the active characters
    /// @return AddressedCharacter[] Active characters and their addresses
    function getActiveCharacters() external view returns (AddressedCharacter[] memory) {
        return getAddressedCharacters(activeAddresses);
    }

    /// @notice Base modifier for characters' max hp and physical damage
    uint8 public immutable baseEndurance;
    /// @notice Base modifier for characters' magical ability
    uint8 public immutable baseIntelligence;

    /// @notice Instantiate a new contract and set the base modifiers
    /// @dev Not meant to be deployed by itself, use with `Game` contract
    /// @param _baseEndurance Base modifier for characters' max hp and physical damage
    /// @param _baseIntelligence Base modifier for characters' magical ability
    constructor(uint8 _baseEndurance, uint8 _baseIntelligence) {
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
        activeAddresses.push(msg.sender);
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
        // Conversion ok since max is 5. Using uint32 since we will be adding to it later.
        uint32 enduranceBonus = uint32(_seed % 6);
        uint32 intelligenceBonus = 5 - enduranceBonus;

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
    /// @return uint32 Max HP of the character
    function characterMaxHp(address _characterAddress) public view returns (uint32) {
        return characters[_characterAddress].maxHp;
    }

    /// @notice Get the physical damage the character deals
    /// @param _characterAddress Address of the Character to check
    /// @return uint32 Physical Damage of the character
    function characterPhysicalDamage(address _characterAddress) public view returns (uint32) {
        return characters[_characterAddress].physicalDamage;
    }

    /// @notice Get the amount of healing provided by the character
    /// @param _characterAddress Address of the Character to check
    /// @return uint32 Heal of the character
    function characterHeal(address _characterAddress) public view returns (uint32) {
        return characters[_characterAddress].heal;
    }

    /// @notice Get the current HP of the character
    /// @param _characterAddress Address of the Character to check
    /// @return uint32 Current HP of the character
    function characterHp(address _characterAddress) public view returns (uint32) {
        return characters[_characterAddress].hp;
    }

    /// @notice Get the current XP of the character
    /// @param _characterAddress Address of the Character to check
    /// @return uint64 Current XP of the character
    function characterXp(address _characterAddress) public view returns (uint64) {
        return characters[_characterAddress].xp;
    }

    /// @notice Calculate the amount of damage dealt based on remaining hp
    /// @dev Always use to avoid arithmetic errors
    /// @param _damage Amount of damage we're trying to deal
    /// @param _hp Remaining hp
    function calculateDamageDealt(uint32 _damage, uint32 _hp) public pure returns (uint32) {
        return _damage >= _hp ? _hp : _damage;
    }

    /// @notice Calculate the amount of healing the target character will receive
    /// @dev Always use to avoid arithmetic errors
    /// @param _heal Amount of healing we're trying to provide
    /// @param _targetCharacter Character to heal
    function calculateHpHealed(uint32 _heal, Character memory _targetCharacter) public pure returns (uint32) {
        uint32 missingHp = _targetCharacter.maxHp - _targetCharacter.hp;
        return missingHp >= _heal ? _heal : missingHp;
    }

    /// @notice For a list of addresses, retrieve the associated characters
    /// @param _characterAddresses Addresses of the characters to retrieve
    /// @return AddressedCharacter[]
    function getAddressedCharacters(address[] memory _characterAddresses) internal view returns (AddressedCharacter[] memory) {
        AddressedCharacter[] memory addressedCharacters = new AddressedCharacter[](_characterAddresses.length);
        for (uint256 i = 0; i < addressedCharacters.length; i++) {
            addressedCharacters[i] = AddressedCharacter({
                addr: _characterAddresses[i],
                character: characters[_characterAddresses[i]]
            });
        }
        return addressedCharacters;
    }
}