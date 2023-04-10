# Ownable
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/e73d628aa9e06b66cb5c5a9c7957ecc26a49dec1/src/utils/Ownable.sol)

**Inherits:**
[IOwnable](/src/utils/Ownable.sol/interface.IOwnable.md)


## State Variables
### owner

```solidity
address public owner;
```


## Functions
### constructor

Instantiate a new contract and set its owner


```solidity
constructor(address _owner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|New owner of the contract|


### onlyOwner

Modifier to enforce ownership control


```solidity
modifier onlyOwner();
```

### transferOwnership

Set the address of the new owner of the contract

*Set _newOwner to address(0) to renounce any ownership.*


```solidity
function transferOwnership(address _newOwner) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newOwner`|`address`|The address of the new owner of the contract|


