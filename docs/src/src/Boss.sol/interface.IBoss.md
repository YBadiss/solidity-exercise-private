# IBoss
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/e73d628aa9e06b66cb5c5a9c7957ecc26a49dec1/src/Boss.sol)

**Inherits:**
[IBossEvents](/src/Boss.sol/interface.IBossEvents.md)


## Errors
### BossIsNotDead
Errors


```solidity
error BossIsNotDead();
```

### BossIsDead

```solidity
error BossIsDead();
```

## Structs
### Boss
Boss structure


```solidity
struct Boss {
    string name;
    uint32 maxHp;
    uint32 hp;
    uint32 damage;
    uint32 xpReward;
}
```

