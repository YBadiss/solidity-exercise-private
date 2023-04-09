//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import "./utils/Ownable.sol";
import "./Character.sol";
import "./Boss.sol";

/// @title World Of Ledger
/// @author Yacine B. Badiss
/// @notice Create a character linked to your address and fight monsters!
/// @dev Main contract controlling the game flow
/// Rules:
/// 1. As an owner I want to inherit the admin permissions of the smart contract once it is deployed.
/// 2. As an admin I want to be the only one able to populate the contract with customizable bosses.
///      - A new boss can't be populated if the current one isn't defeated.
///      - A dead character can no longer do anything but can be healed.
/// 3. As a user I want to be able to pseudo-randomly generate **one** character per address.
/// 4. As a user I want to be able to attack the current boss with my character.
///      - Everytime a player attacks the boss, the boss will counterattack. Both will lose life points.
/// 5. As a user I should be able to heal other characters with my character.
///      - Players can't heal themselves.
///      - Only players who have already earned experience can cast the heal spell.
/// 6. As a user I want to be able to claim rewards, such as experience, when defeating bosses.
///      - Only characters who attacked a boss can receive experience as reward.
///      - Only characters who are alive can receive experience as reward.
contract Game is Ownable, IBoss, ICharacter {
    ////////////////////////////////////////////////////////////////////////
    /// Game mechanic
    ////////////////////////////////////////////////////////////////////////
    
    /// @notice Track damage dealt to the current boss by the characters.
    /// @dev Used for rewards, reset after distributing rewards.
    mapping(address => uint256) public damageDealtToBoss;

    /// @notice Tracks characters that have hit the current boss.
    /// @dev Used for rewards, reset after distributing rewards.
    address[] public charactersInvolvedInFight;

    uint256 public immutable baseEndurance;
    uint256 public immutable baseIntelligence;
    uint256 public immutable baseHeal;

    /// @notice Instantiate a new contract and set its owner
    /// @dev `owner` is defined in the Ownable interface
    /// @param _owner New owner of the contract
    constructor(address _owner) {
        owner = _owner;
        baseEndurance = 10;
        baseIntelligence = 10;
        baseHeal = 100;
        emit OwnershipTransferred({
            previousOwner: address(0),
            newOwner: owner
        });
    }

    /// @notice Set a new Boss
    /// @dev Only for the owner, and if the boss is already dead
    /// @param _boss New boss to set
    function setBoss(Boss memory _boss) external onlyOwner {
        if (!this.isBossDead()) revert BossIsNotDead();

        distributeRewards();
        boss = _boss;
        emit BossSpawned({
            bossName: boss.name,
            maxHp: boss.maxHp,
            damage: boss.damage,
            xpReward: boss.xpReward
        });
    }

    /// @notice Fight with the Boss using the character of the caller
    function fightBoss() external onlyAliveCharacter {
        // Don't allow hitting a boss that is dead
        if (isBossDead()) revert BossIsDead();

        address characterAddress = msg.sender;
        Character memory character = characters[characterAddress];

        uint256 damageDealtByCharacter = calculateDamageDealt(character.physicalDamage, boss.hp);
        boss.hp -= damageDealtByCharacter;

        uint256 damageDealtByBoss = calculateDamageDealt(boss.damage, character.hp);
        character.hp -= damageDealtByBoss;
        characters[characterAddress] = character;

        if (damageDealtToBoss[characterAddress] == 0) {
            charactersInvolvedInFight.push(characterAddress);
        }
        damageDealtToBoss[characterAddress] += damageDealtByCharacter;
        
        emit BossIsHit({
            bossName: boss.name,
            characterAddress: characterAddress,
            bossHp: boss.hp,
            damageDealt: damageDealtByCharacter
        });
        emit CharacterIsHit({
            characterAddress: characterAddress,
            bossName: boss.name,
            characterHp: character.hp,
            damageDealt: damageDealtByBoss
        });
        if (boss.hp == 0) {
            emit BossKilled({
                bossName: boss.name,
                characterAddress: characterAddress
            });
        }
        if (character.hp == 0) {
            emit CharacterKilled({
                characterAddress: characterAddress,
                bossName: boss.name
            });
        }
    }

    /// @notice Heal a character
    /// @dev Only for characters alive, and cannot self-heal
    /// @param _targetCharacter Character to heal
    function healCharacter(address _targetCharacter) public onlyAliveCharacter onlyExperiencedCharacter {
        if (_targetCharacter == msg.sender) revert CharacterCannotSelfHeal();
        if (!isCharacterCreated(_targetCharacter)) revert CharacterNotCreated();

        uint256 healAmount = calculateHpHealed(characters[msg.sender].heal, characters[_targetCharacter]);
        if (healAmount > 0) {
            characters[_targetCharacter].hp += healAmount;
            emit CharacterHealed({
                characterAddress: _targetCharacter,
                healerAddress: msg.sender,
                characterHp: characters[_targetCharacter].hp,
                healAmount: healAmount
            });
        }
    }

    /// @notice Distribute rewards to all characters that fought the boss, and are still alive
    /// @dev Can cost a lot of gas if many characters fought the boss. It is paid by the owner, not the players.
    function distributeRewards() public onlyOwner {
        if (!this.isBossDead()) revert BossIsNotDead();

        for (uint256 index = 0; index < charactersInvolvedInFight.length; index++) {
            address characterAddress = charactersInvolvedInFight[index];

            if (isCharacterAlive(characterAddress)) {
                // Only give out XP if the character is still alive
                uint256 totalDamageDealt = damageDealtToBoss[characterAddress];
                uint256 xpReward = (totalDamageDealt * boss.xpReward) / boss.maxHp;
                characters[characterAddress].xp += xpReward;
                emit CharacterRewarded({
                    characterAddress: characterAddress,
                    bossName: boss.name,
                    xpReward: xpReward,
                    totalDamageDealt: totalDamageDealt
                });
            }
            damageDealtToBoss[characterAddress] = 0;
        }
        // This can be expensive depending on how many characters were involved
        delete charactersInvolvedInFight;
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

    ////////////////////////////////////////////////////////////////////////
    /// All about the characters
    ////////////////////////////////////////////////////////////////////////

    /// @notice Track all the characters of the game
    mapping(address => Character) public characters;

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
            heal: baseHeal + 10 * (baseIntelligence + intelligenceBonus),
            hp: 100 * (baseEndurance + enduranceBonus),
            xp: 0
        });
    }

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

    ////////////////////////////////////////////////////////////////////////
    /// All about the boss
    ////////////////////////////////////////////////////////////////////////

    /// @notice Current Boss characters can fight against
    Boss public boss;

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
