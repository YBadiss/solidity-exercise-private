# ICharacter
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/f14e48d2011704a0c8a698b843deeed8a3b64a94/src/Character.sol)

**Inherits:**
[ICharacterEvents](/src/Character.sol/interface.ICharacterEvents.md)


## Errors
### CharacterNotCreated
Errors


```solidity
error CharacterNotCreated();
```

### CharacterAlreadyCreated

```solidity
error CharacterAlreadyCreated();
```

### CharacterCannotSelfHeal

```solidity
error CharacterCannotSelfHeal();
```

### CharacterNotExperienced

```solidity
error CharacterNotExperienced();
```

### CharacterIsDead

```solidity
error CharacterIsDead();
```

## Structs
### Character
Character structure

*The parameters should be generated randomly*


```solidity
struct Character {
    bool created;
    uint32 maxHp;
    uint32 physicalDamage;
    uint32 heal;
    uint32 hp;
    uint64 xp;
}
```

### AddressedCharacter
Wrapper structure to return characters with their address


```solidity
struct AddressedCharacter {
    address addr;
    Character character;
}
```

