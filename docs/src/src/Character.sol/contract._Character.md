# _Character
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/e73d628aa9e06b66cb5c5a9c7957ecc26a49dec1/src/Character.sol)

**Inherits:**
[ICharacter](/src/Character.sol/interface.ICharacter.md)

**Author:**
Yacine B. Badiss

Internal contract to handle characters

*Internal contract to handle characters*


## State Variables
### characters
Track all the characters of the game


```solidity
mapping(address => Character) public characters;
```


### activeAddresses
Tracks characters are active


```solidity
address[] public activeAddresses;
```


### baseEndurance
Base modifier for characters' max hp and physical damage


```solidity
uint8 public immutable baseEndurance;
```


### baseIntelligence
Base modifier for characters' magical ability


```solidity
uint8 public immutable baseIntelligence;
```


## Functions
### getActiveCharacters

Get all the active characters


```solidity
function getActiveCharacters() external view returns (AddressedCharacter[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`AddressedCharacter[]`|AddressedCharacter[] Active characters and their addresses|


### constructor

Instantiate a new contract and set the base modifiers

*Not meant to be deployed by itself, use with `Game` contract*


```solidity
constructor(uint8 _baseEndurance, uint8 _baseIntelligence);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_baseEndurance`|`uint8`|Base modifier for characters' max hp and physical damage|
|`_baseIntelligence`|`uint8`|Base modifier for characters' magical ability|


### fightBoss

Character actions

Fight with the Boss using the character of the caller

*Implement in the main contract.*


```solidity
function fightBoss() external virtual onlyAliveCharacter;
```

### healCharacter

Heal a character

*Only for characters alive, and cannot self-heal. Implement in the main contract.*


```solidity
function healCharacter(address _targetCharacter) external virtual onlyAliveCharacter onlyExperiencedCharacter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_targetCharacter`|`address`|Character to heal|


### newCharacter

Register a new character for the caller


```solidity
function newCharacter() external;
```

### onlyAliveCharacter

Helper functions

Modifier to only allow characters that exist and are currently alive


```solidity
modifier onlyAliveCharacter();
```

### onlyExperiencedCharacter

Modifier to only allow characters that have earned xp


```solidity
modifier onlyExperiencedCharacter();
```

### buildCharacter

Helper function to build character attributes given a seed


```solidity
function buildCharacter(uint256 _seed) public view returns (Character memory);
```

### isCharacterCreated

Indicates if the target address has already created a Character


```solidity
function isCharacterCreated(address _characterAddress) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_characterAddress`|`address`|Address of the Character to check|


### isCharacterAlive

Indicates if the target Character is alive


```solidity
function isCharacterAlive(address _characterAddress) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_characterAddress`|`address`|Address of the Character to check|


### canCharacterHeal

Indicates if the target Character can heal others


```solidity
function canCharacterHeal(address _characterAddress) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_characterAddress`|`address`|Address of the Character to check|


### characterMaxHp

Get the max HP of the character


```solidity
function characterMaxHp(address _characterAddress) public view returns (uint32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_characterAddress`|`address`|Address of the Character to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32 Max HP of the character|


### characterPhysicalDamage

Get the physical damage the character deals


```solidity
function characterPhysicalDamage(address _characterAddress) public view returns (uint32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_characterAddress`|`address`|Address of the Character to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32 Physical Damage of the character|


### characterHeal

Get the amount of healing provided by the character


```solidity
function characterHeal(address _characterAddress) public view returns (uint32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_characterAddress`|`address`|Address of the Character to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32 Heal of the character|


### characterHp

Get the current HP of the character


```solidity
function characterHp(address _characterAddress) public view returns (uint32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_characterAddress`|`address`|Address of the Character to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32 Current HP of the character|


### characterXp

Get the current XP of the character


```solidity
function characterXp(address _characterAddress) public view returns (uint64);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_characterAddress`|`address`|Address of the Character to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint64`|uint64 Current XP of the character|


### calculateDamageDealt

Calculate the amount of damage dealt based on remaining hp

*Always use to avoid arithmetic errors*


```solidity
function calculateDamageDealt(uint32 _damage, uint32 _hp) public pure returns (uint32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_damage`|`uint32`|Amount of damage we're trying to deal|
|`_hp`|`uint32`|Remaining hp|


### calculateHpHealed

Calculate the amount of healing the target character will receive

*Always use to avoid arithmetic errors*


```solidity
function calculateHpHealed(uint32 _heal, Character memory _targetCharacter) public pure returns (uint32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_heal`|`uint32`|Amount of healing we're trying to provide|
|`_targetCharacter`|`Character`|Character to heal|


### getAddressedCharacters

For a list of addresses, retrieve the associated characters


```solidity
function getAddressedCharacters(address[] memory _characterAddresses)
    internal
    view
    returns (AddressedCharacter[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_characterAddresses`|`address[]`|Addresses of the characters to retrieve|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`AddressedCharacter[]`|AddressedCharacter[]|


