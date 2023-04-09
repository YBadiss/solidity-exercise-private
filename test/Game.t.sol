// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";

contract GameTest is Test, IOwnable, IBoss, ICharacter {
    Game public game;
    address public owner = address(1);
    Boss boss = Boss({name: "Test Boss", maxHp: 1000, hp: 1000, damage: 50, xpReward: 10000});
    Boss weakBoss = Boss({name: "Weak Boss", maxHp: 1, hp: 1, damage: 50, xpReward: 10});
    Boss strongBoss = Boss({name: "Strong Boss", maxHp: 1000, hp: 1000, damage: 10000, xpReward: 100000000});
    address public characterAddress = address(2);
    Character public character;
    address public healerAddress = address(3);

    function setUp() public {
        game = new Game({_owner: owner, _baseEndurance: 10, _baseIntelligence: 10});
        vm.prank(characterAddress);
        game.newCharacter();

        // Give some xp to the healer
        vm.prank(owner);
        game.setBoss({_name: weakBoss.name, _maxHp: weakBoss.maxHp, _damage: weakBoss.damage, _xpReward: weakBoss.xpReward});

        vm.startPrank(healerAddress);
        game.newCharacter();
        game.fightBoss();
        vm.stopPrank();
        
        vm.prank(owner);
        game.distributeRewards();
    }

    function test_setBoss_RevertIf_notOwner() public {
        address notOwner = address(2);
        vm.startPrank(notOwner);

        vm.expectRevert(IOwnable.NotOwner.selector);
        game.setBoss({_name: boss.name, _maxHp: boss.maxHp, _damage: boss.damage, _xpReward: boss.xpReward});
    }

    function test_setBoss_RevertIf_notDead() public {
        vm.startPrank(owner);
        game.setBoss({_name: boss.name, _maxHp: boss.maxHp, _damage: boss.damage, _xpReward: boss.xpReward});

        vm.expectRevert(IBoss.BossIsNotDead.selector);
        game.setBoss({_name: boss.name, _maxHp: boss.maxHp, _damage: boss.damage, _xpReward: boss.xpReward});
    }

    function test_bossTakesHit() public {
        vm.prank(owner);
        game.setBoss({_name: boss.name, _maxHp: boss.maxHp, _damage: boss.damage, _xpReward: boss.xpReward});

        uint32 newBossHp = game.bossHp() - game.characterPhysicalDamage(characterAddress);
        uint32 newCharacterHp = game.characterHp(characterAddress) - game.bossDamage();
        vm.expectEmit();
        emit BossIsHit(game.bossName(), characterAddress, newBossHp, game.characterPhysicalDamage(characterAddress));
        vm.expectEmit();
        emit CharacterIsHit(characterAddress, game.bossName(), newCharacterHp, game.bossDamage());

        vm.prank(characterAddress);
        game.fightBoss();

        assertEq(game.bossHp(), newBossHp);
        assertEq(game.characterHp(characterAddress), newCharacterHp);
        assertEq(game.charactersInvolvedInFight(0), characterAddress);
        assertEq(game.damageDealtToBoss(characterAddress), game.characterPhysicalDamage(characterAddress));
    }

    function test_bossHpAlwaysAboveZero() public {
        vm.prank(owner);
        game.setBoss({_name: weakBoss.name, _maxHp: weakBoss.maxHp, _damage: weakBoss.damage, _xpReward: weakBoss.xpReward});

        uint32 newCharacterHp = game.characterHp(characterAddress) - game.bossDamage();
        vm.expectEmit();
        emit BossIsHit(game.bossName(), characterAddress, 0, game.bossHp());
        vm.expectEmit();
        emit CharacterIsHit(characterAddress, game.bossName(), newCharacterHp, game.bossDamage());
        vm.expectEmit();
        emit BossKilled(game.bossName(), characterAddress);

        vm.prank(characterAddress);
        game.fightBoss();
        assertEq(game.bossHp(), 0);
    }

    function test_characterHpAlwaysAboveZero() public {
        vm.prank(owner);
        game.setBoss({_name: strongBoss.name, _maxHp: strongBoss.maxHp, _damage: strongBoss.damage, _xpReward: strongBoss.xpReward});

        uint32 newBossHp = game.bossHp() - game.characterPhysicalDamage(characterAddress);
        vm.expectEmit();
        emit BossIsHit(game.bossName(), characterAddress, newBossHp, game.characterPhysicalDamage(characterAddress));
        vm.expectEmit();
        emit CharacterIsHit(characterAddress, game.bossName(), 0, game.characterHp(characterAddress));
        vm.expectEmit();
        emit CharacterKilled(characterAddress, game.bossName());

        vm.prank(characterAddress);
        game.fightBoss();
        assertEq(game.characterHp(characterAddress), 0);
    }

    function test_fightBoss_RevertsIf_bossIsDead() public {
        vm.prank(characterAddress);

        vm.expectRevert(IBoss.BossIsDead.selector);
        game.fightBoss();
    }

    function test_fightBoss_RevertsIf_characterNotCreated() public {
        vm.prank(owner);
        game.setBoss({_name: boss.name, _maxHp: boss.maxHp, _damage: boss.damage, _xpReward: boss.xpReward});

        address notCharacterAddress = address(0);
        vm.prank(notCharacterAddress);

        vm.expectRevert(ICharacter.CharacterNotCreated.selector);
        game.fightBoss();
    }

    function test_fightBoss_RevertsIf_characterIsDead() public {
        vm.prank(owner);
        game.setBoss({_name: strongBoss.name, _maxHp: strongBoss.maxHp, _damage: strongBoss.damage, _xpReward: strongBoss.xpReward});

        vm.startPrank(characterAddress);
        game.fightBoss();
        vm.expectRevert(ICharacter.CharacterIsDead.selector);
        game.fightBoss();
    }

    function test_healCharacter() public {
        vm.prank(owner);
        game.setBoss({_name: strongBoss.name, _maxHp: strongBoss.maxHp, _damage: strongBoss.damage, _xpReward: strongBoss.xpReward});

        vm.prank(characterAddress);
        game.fightBoss();
        assertEq(game.characterHp(characterAddress), 0);


        vm.expectEmit();
        emit CharacterHealed(characterAddress, healerAddress, game.characterHeal(healerAddress), game.characterHeal(healerAddress));
        vm.prank(healerAddress);
        game.healCharacter(characterAddress);
        assertEq(game.characterHp(characterAddress), game.characterHeal(healerAddress));
    }

    function test_healCharacterNeverAboveMaxHp() public {
        assertEq(game.characterHp(characterAddress), game.characterMaxHp(characterAddress));
        vm.prank(healerAddress);
        game.healCharacter(characterAddress);
        assertEq(game.characterHp(characterAddress), game.characterMaxHp(characterAddress));
    }

    function test_healCharacter_RevertsIf_selfHeal() public {
        vm.prank(healerAddress);
        vm.expectRevert(ICharacter.CharacterCannotSelfHeal.selector);
        game.healCharacter(healerAddress);
    }

    function test_distributeRewards() public {
        vm.prank(owner);
        game.setBoss({_name: strongBoss.name, _maxHp: strongBoss.maxHp, _damage: strongBoss.damage, _xpReward: strongBoss.xpReward});

        // We hit the boss until it's about to die
        uint160 size = game.bossHp() / game.characterPhysicalDamage(characterAddress) - 1;
        address[] memory deadCharacters = new address[](size);
        for (uint160 index = 0; index < size; index++) {
            address deadCharacter = address(index + 4);
            vm.startPrank(deadCharacter);
            game.newCharacter();
            game.fightBoss();
            vm.stopPrank();
            deadCharacters[index] = deadCharacter;
        }
        
        // Finish the boss with our character
        vm.prank(characterAddress);
        game.fightBoss();

        // Heal our character because it's dead
        vm.prank(healerAddress);
        game.healCharacter(characterAddress);
        uint64 healerXp = game.characterXp(healerAddress);
        uint32 expectedReward = uint32(uint64(game.characterPhysicalDamage(characterAddress)) * game.bossXpReward() / game.bossMaxHp());

        vm.expectEmit();
        emit CharacterRewarded({
            characterAddress: characterAddress,
            bossName: game.bossName(),
            xpReward: expectedReward,
            totalDamageDealt: game.characterPhysicalDamage(characterAddress)
        });

        vm.prank(owner);
        game.distributeRewards();
        // The only fighter alive gets its xp based on the damage dealt
        assertEq(game.characterXp(characterAddress), expectedReward);
        // The healer didn't fight, no additional xp
        assertEq(game.characterXp(healerAddress), healerXp);
        // The other fighters are all dead, no xp
        for (uint160 index = 0; index < deadCharacters.length; index++) {
            assertEq(game.characterXp(deadCharacters[index]), 0);
        }
    }
}
