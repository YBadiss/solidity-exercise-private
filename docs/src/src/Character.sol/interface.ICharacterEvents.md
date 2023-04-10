# ICharacterEvents
[Git Source](https://github.com/YBadiss/solidity-exercise-private/blob/f14e48d2011704a0c8a698b843deeed8a3b64a94/src/Character.sol)


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

