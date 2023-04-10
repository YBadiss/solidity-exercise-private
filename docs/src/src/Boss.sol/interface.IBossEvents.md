# IBossEvents
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/f14e48d2011704a0c8a698b843deeed8a3b64a94/src/Boss.sol)


## Events
### BossSpawned
*This emits when the Boss is created.*


```solidity
event BossSpawned(string indexed bossName, uint32 maxHp, uint32 damage, uint32 xpReward);
```

### BossIsHit
*This emits when the Boss is hit.*


```solidity
event BossIsHit(string indexed bossName, address indexed characterAddress, uint32 bossHp, uint32 damageDealt);
```

### BossKilled
*This emits when the Boss dies.*


```solidity
event BossKilled(string indexed bossName, address indexed characterAddress);
```

