# ICharacter
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/e73d628aa9e06b66cb5c5a9c7957ecc26a49dec1/src/Character.sol)

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

