# ICharacterEvents
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/e73d628aa9e06b66cb5c5a9c7957ecc26a49dec1/src/Character.sol)


## Events
### CharacterSpawned
*This emits when the Character is created.*


```solidity
event CharacterSpawned(address indexed characterAddress, uint32 maxHp, uint32 physicalDamage, uint32 heal);
```

### CharacterIsHit
*This emits when the Character is hit.*


```solidity
event CharacterIsHit(address indexed characterAddress, string indexed bossName, uint32 characterHp, uint32 damageDealt);
```

### CharacterHealed
*This emits when the Character is hit.*


```solidity
event CharacterHealed(
    address indexed characterAddress, address indexed healerAddress, uint32 characterHp, uint32 healAmount
);
```

### CharacterRewarded
*This emits when the Character receives xp rewards.*


```solidity
event CharacterRewarded(
    address indexed characterAddress, string indexed bossName, uint32 xpReward, uint32 totalDamageDealt
);
```

### CharacterKilled
*This emits when the Character dies.*


```solidity
event CharacterKilled(address indexed characterAddress, string indexed bossName);
```

