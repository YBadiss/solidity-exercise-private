# IBossEvents
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/e73d628aa9e06b66cb5c5a9c7957ecc26a49dec1/src/Boss.sol)


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

