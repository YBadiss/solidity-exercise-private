//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.19;

import "./utils/Ownable.sol";
import "./Character.sol";
import "./Boss.sol";

/// @title World Of Ledger
/// @author Yacine B. Badiss
/// @notice Create a character linked to your address and fight monsters!
/// @dev Main contract controlling the game flow
///
/// In this contract, you'll find all the logic of interaction between Characters and Bosses.
/// We inherit from _Boss and _Character contracts. They should not be used directly: They are
/// merely code grouping to allow simpler testing and separation of concerns.
///
/// I have added several utilities to ease interactions between dApps and the Game contract.
/// Among those are arrays of addresses tracking Characters, and methods to fetch lists of Characters
/// with their address. This allows, in very few RPC calls, to get a full state of the game.
///
/// ## Rules:
/// - As an owner I want to inherit the admin permissions of the smart contract once it is deployed.
/// - As an admin I want to be the only one able to populate the contract with customizable bosses.
///   - A new boss can't be populated if the current one isn't defeated.
///   - A dead character can no longer do anything but can be healed.
/// - As a user I want to be able to pseudo-randomly generate **one** character per address.
/// - As a user I want to be able to attack the current boss with my character.
///   - Everytime a player attacks the boss, the boss will counterattack. Both will lose life points.
/// - As a user I should be able to heal other characters with my character.
///   - Players can't heal themselves.
///   - Only players who have already earned experience can cast the heal spell.
/// - As a user I want to be able to claim rewards, such as experience, when defeating bosses.
///   - Only characters who attacked a boss can receive experience as reward.
///   - The experience reward is split between fighting characters, on the basis of how much damage they have dealt.
///   - Only characters who are alive can receive experience as reward.
contract Game is Ownable, _Boss, _Character {
    /// @notice Track damage dealt to the current boss by the characters.
    /// @dev Used for rewards, reset after distributing rewards.
    /// The total damage dealt by individual characters is always smaller than boss.maxHp, so uint32 is enough.
    mapping(address => uint32) public damageDealtToBoss;

    /// @notice Tracks addresses that have hit the current boss.
    /// @dev Used for rewards, reset after distributing rewards.
    address[] public addressesInvolvedInFight;

    /// @notice Get all the characters involved in the current fight
    /// @return AddressedCharacter[] Characters involved in the current fight
    function getCharactersInvolvedInFight() external view returns (AddressedCharacter[] memory) {
        return getAddressedCharacters(addressesInvolvedInFight);
    }

    /// @notice Instantiate a new contract and set its owner
    /// @param _owner New owner of the contract
    /// @param _baseEndurance Base modifier for characters' max hp and physical damage
    /// @param _baseIntelligence Base modifier for characters' magical ability
    constructor(address _owner, uint8 _baseEndurance, uint8 _baseIntelligence)
        Ownable(_owner)
        _Character(_baseEndurance, _baseIntelligence)
    {}

    ////////////////////////////////////////////////////////////////////////
    /// Character actions
    ////////////////////////////////////////////////////////////////////////

    /// @notice Fight with the Boss using the character of the caller
    function fightBoss() external override onlyAliveCharacter {
        // Don't allow hitting a boss that is dead
        if (isBossDead()) revert BossIsDead();

        address characterAddress = msg.sender;
        Character memory character = characters[characterAddress];

        uint32 damageDealtByCharacter = calculateDamageDealt(character.physicalDamage, boss.hp);
        boss.hp -= damageDealtByCharacter;

        uint32 damageDealtByBoss = calculateDamageDealt(boss.damage, character.hp);
        character.hp -= damageDealtByBoss;
        characters[characterAddress] = character;

        if (damageDealtToBoss[characterAddress] == 0) {
            addressesInvolvedInFight.push(characterAddress);
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
    function healCharacter(address _targetCharacter) external override onlyAliveCharacter onlyExperiencedCharacter {
        if (_targetCharacter == msg.sender) revert CharacterCannotSelfHeal();
        if (!isCharacterCreated(_targetCharacter)) revert CharacterNotCreated();

        uint32 healAmount = calculateHpHealed(characters[msg.sender].heal, characters[_targetCharacter]);
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

    ////////////////////////////////////////////////////////////////////////
    /// Owner actions
    ////////////////////////////////////////////////////////////////////////

    /// @notice Set a new Boss
    /// @dev Only for the owner, and if the boss is already dead
    /// @param _name Name of the new boss
    /// @param _maxHp Starting and max hp of the new boss
    /// @param _damage Damage inflicted by the new boss
    /// @param _xpReward Experience reward given by the new boss
    function setBoss(string memory _name, uint32 _maxHp, uint32 _damage, uint32 _xpReward) public override onlyOwner {
        distributeRewards();
        super.setBoss(_name, _maxHp, _damage, _xpReward);
    }

    /// @notice Distribute rewards to all characters that fought the boss, and are still alive
    /// @dev Can cost a lot of gas if many characters fought the boss. It is paid by the owner, not the players.
    function distributeRewards() public onlyOwner {
        if (!this.isBossDead()) revert BossIsNotDead();

        for (uint256 index = 0; index < addressesInvolvedInFight.length; index++) {
            address characterAddress = addressesInvolvedInFight[index];

            if (isCharacterAlive(characterAddress)) {
                // Only give out XP if the character is still alive
                uint32 totalDamageDealt = damageDealtToBoss[characterAddress];
                // `xpReward` is always smaller than `boss.xpReward` since `(totalDamageDealt / boss.maxHp) <= 1`
                // so it will always fit in a uint32.
                // We however need to explicitely cast `totalDamageDealt` to a larger number to be able to do the computation.
                uint32 xpReward = uint32((uint64(totalDamageDealt) * boss.xpReward) / boss.maxHp);
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
        delete addressesInvolvedInFight;
    }
}
