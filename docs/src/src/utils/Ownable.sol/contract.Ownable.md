# Ownable
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/f14e48d2011704a0c8a698b843deeed8a3b64a94/src/utils/Ownable.sol)

**Inherits:**
[IOwnable](/src/utils/Ownable.sol/interface.IOwnable.md)

There are multiple extensions from OpenZepplin, 0x, etc. that we could use.
But since Ownable is rather simple to implement, I wanted to do it myself once.


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


