# _Boss
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/e73d628aa9e06b66cb5c5a9c7957ecc26a49dec1/src/Boss.sol)

**Inherits:**
[IBoss](/src/Boss.sol/interface.IBoss.md)


## State Variables
### boss
Current Boss characters can fight against


```solidity
Boss public boss;
```


## Functions
### setBoss

Owner functions

Set a new Boss

*Only if the boss is already dead*


```solidity
function setBoss(string memory _name, uint32 _maxHp, uint32 _damage, uint32 _xpReward) public virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_name`|`string`|Name of the new boss|
|`_maxHp`|`uint32`|Starting and max hp of the new boss|
|`_damage`|`uint32`|Damage inflicted by the new boss|
|`_xpReward`|`uint32`|Experience reward given by the new boss|


### bossName

Helper functions

Get the name of the boss


```solidity
function bossName() external view returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|string Name of the boss|


### bossMaxHp

Get the max HP of the boss


```solidity
function bossMaxHp() external view returns (uint32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32 Max HP of the boss|


### bossHp

Get the hp of the boss


```solidity
function bossHp() external view returns (uint32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32 Current HP of the boss|


### bossDamage

Get the damage inflicted by the boss on each attack


```solidity
function bossDamage() external view returns (uint32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32 Damage inflicted|


### bossXpReward

Get the xp reward split between all fighters when the boss dies


```solidity
function bossXpReward() external view returns (uint32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32 XP reward|


### isBossDead

Check if the Boss is dead

*hp is unsigned, we don't check negative values*


```solidity
function isBossDead() public view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool true if dead, false otherwise|


