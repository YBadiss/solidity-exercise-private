# IBoss
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/f14e48d2011704a0c8a698b843deeed8a3b64a94/src/Boss.sol)

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

