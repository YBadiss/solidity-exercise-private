# Game
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/e73d628aa9e06b66cb5c5a9c7957ecc26a49dec1/src/Game.sol)

**Inherits:**
[Ownable](/src/utils/Ownable.sol/contract.Ownable.md), [_Boss](/src/Boss.sol/contract._Boss.md), [_Character](/src/Character.sol/contract._Character.md)

**Author:**
Yacine B. Badiss

Create a character linked to your address and fight monsters!

*Main contract controlling the game flow
Rules:
1. As an owner I want to inherit the admin permissions of the smart contract once it is deployed.
2. As an admin I want to be the only one able to populate the contract with customizable bosses.
- A new boss can't be populated if the current one isn't defeated.
- A dead character can no longer do anything but can be healed.
3. As a user I want to be able to pseudo-randomly generate **one** character per address.
4. As a user I want to be able to attack the current boss with my character.
- Everytime a player attacks the boss, the boss will counterattack. Both will lose life points.
5. As a user I should be able to heal other characters with my character.
- Players can't heal themselves.
- Only players who have already earned experience can cast the heal spell.
6. As a user I want to be able to claim rewards, such as experience, when defeating bosses.
- Only characters who attacked a boss can receive experience as reward.
- Only characters who are alive can receive experience as reward.*


## State Variables
### damageDealtToBoss
Track damage dealt to the current boss by the characters.

*Used for rewards, reset after distributing rewards.
The total damage dealt by individual characters is always smaller than boss.maxHp, so uint32 is enough.*


```solidity
mapping(address => uint32) public damageDealtToBoss;
```


### addressesInvolvedInFight
Tracks addresses that have hit the current boss.

*Used for rewards, reset after distributing rewards.*


```solidity
address[] public addressesInvolvedInFight;
```


## Functions
### getCharactersInvolvedInFight

Get all the characters involved in the current fight


```solidity
function getCharactersInvolvedInFight() external view returns (AddressedCharacter[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`AddressedCharacter[]`|AddressedCharacter[] Characters involved in the current fight|


### constructor

Instantiate a new contract and set its owner


```solidity
constructor(address _owner, uint8 _baseEndurance, uint8 _baseIntelligence)
    Ownable(_owner)
    _Character(_baseEndurance, _baseIntelligence);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|New owner of the contract|
|`_baseEndurance`|`uint8`|Base modifier for characters' max hp and physical damage|
|`_baseIntelligence`|`uint8`|Base modifier for characters' magical ability|


### fightBoss

Character actions

Fight with the Boss using the character of the caller


```solidity
function fightBoss() external override onlyAliveCharacter;
```

### healCharacter

Heal a character

*Only for characters alive, and cannot self-heal*


```solidity
function healCharacter(address _targetCharacter) external override onlyAliveCharacter onlyExperiencedCharacter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_targetCharacter`|`address`|Character to heal|


### setBoss

Owner actions

Set a new Boss

*Only for the owner, and if the boss is already dead*


```solidity
function setBoss(string memory _name, uint32 _maxHp, uint32 _damage, uint32 _xpReward) public override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_name`|`string`|Name of the new boss|
|`_maxHp`|`uint32`|Starting and max hp of the new boss|
|`_damage`|`uint32`|Damage inflicted by the new boss|
|`_xpReward`|`uint32`|Experience reward given by the new boss|


### distributeRewards

Distribute rewards to all characters that fought the boss, and are still alive

*Can cost a lot of gas if many characters fought the boss. It is paid by the owner, not the players.*


```solidity
function distributeRewards() public onlyOwner;
```

