// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";

// TODO Simplify several of these function by better using `vm` and cheats to setup test cases

contract GameTest is Test, IOwnable, IBoss, ICharacter {
    using stdStorage for StdStorage;

    Game public game;
    address public owner = address(1);
    Boss boss = Boss({name: "Test Boss", maxHp: 1000, hp: 1000, damage: 50, xpReward: 10000});
    Boss weakBoss = Boss({name: "Weak Boss", maxHp: 1, hp: 1, damage: 50, xpReward: 600});
    Boss strongBoss = Boss({name: "Strong Boss", maxHp: 1000, hp: 1000, damage: 10000, xpReward: 100000000});
    address public characterAddress = address(2);
    Character public character;
    address public casterAddress = address(3);

    function setUp() public {
        game = new Game({_owner: owner, _baseEndurance: 10, _baseIntelligence: 10, _baseLevelXp: 100});
        vm.prank(characterAddress);
        game.newCharacter();

        // The character must be level 2 or more to heal others
        // and level 3 or more to cast fireballs
        // Give some xp to the caster
        vm.prank(owner);
        game.setBoss({_name: weakBoss.name, _maxHp: weakBoss.maxHp, _damage: weakBoss.damage, _xpReward: weakBoss.xpReward});

        vm.startPrank(casterAddress);
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
        assertEq(game.getCharactersInvolvedInFight().length, 0);

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
        assertEq(game.getCharactersInvolvedInFight().length, 1);
        assertEq(game.getCharactersInvolvedInFight()[0].addr, characterAddress);
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

    function test_castFireball_RevertsIf_bossIsDead() public {
        vm.prank(casterAddress);

        vm.expectRevert(IBoss.BossIsDead.selector);
        game.castFireball();
    }

    function test_canCastFireball() public {
        assertFalse(game.canCharacterCastFireball(characterAddress));
        assertTrue(game.canCharacterCastFireball(casterAddress));
    }

    function test_castFireball_RevertsIf_characterNotCreated() public {
        vm.prank(owner);
        game.setBoss({_name: boss.name, _maxHp: boss.maxHp, _damage: boss.damage, _xpReward: boss.xpReward});

        address notCharacterAddress = address(0);
        vm.prank(notCharacterAddress);

        vm.expectRevert(ICharacter.CharacterNotCreated.selector);
        game.castFireball();
    }

    function test_castFireball_RevertsIf_characterNotExperienced() public {
        vm.prank(owner);
        game.setBoss({_name: boss.name, _maxHp: boss.maxHp, _damage: boss.damage, _xpReward: boss.xpReward});

        vm.prank(characterAddress);

        vm.expectRevert(ICharacter.CharacterNotExperienced.selector);
        game.castFireball();
    }

    function test_castFireball_RevertsIf_characterIsDead() public {
        vm.prank(owner);
        game.setBoss({_name: strongBoss.name, _maxHp: strongBoss.maxHp, _damage: strongBoss.damage, _xpReward: strongBoss.xpReward});

        vm.startPrank(casterAddress);
        game.castFireball();
        vm.expectRevert(ICharacter.CharacterIsDead.selector);
        game.castFireball();
    }

    function test_canCharacterHeal() public {
        assertFalse(game.canCharacterHeal(characterAddress));
        assertTrue(game.canCharacterHeal(casterAddress));
    }

    function test_healCharacter() public {
        vm.prank(owner);
        game.setBoss({_name: strongBoss.name, _maxHp: strongBoss.maxHp, _damage: strongBoss.damage, _xpReward: strongBoss.xpReward});

        vm.prank(characterAddress);
        game.fightBoss();
        assertEq(game.characterHp(characterAddress), 0);


        vm.expectEmit();
        emit CharacterHealed(characterAddress, casterAddress, game.characterHeal(casterAddress), game.characterHeal(casterAddress));
        vm.prank(casterAddress);
        game.healCharacter(characterAddress);
        assertEq(game.characterHp(characterAddress), game.characterHeal(casterAddress));
    }

    function test_healCharacterNeverAboveMaxHp() public {
        assertEq(game.characterHp(characterAddress), game.characterMaxHp(characterAddress));
        vm.prank(casterAddress);
        game.healCharacter(characterAddress);
        assertEq(game.characterHp(characterAddress), game.characterMaxHp(characterAddress));
    }

    function test_healCharacter_RevertsIf_selfHeal() public {
        vm.prank(casterAddress);
        vm.expectRevert(ICharacter.CharacterCannotSelfHeal.selector);
        game.healCharacter(casterAddress);
    }

    function test_healCharacter_RevertsIf_characterNotExperienced() public {
        vm.prank(characterAddress);
        vm.expectRevert(ICharacter.CharacterNotExperienced.selector);
        game.healCharacter(casterAddress);
    }

    function test_healCharacter_RevertsIf_characterDoesNotExist() public {
        vm.prank(casterAddress);
        vm.expectRevert(ICharacter.CharacterNotCreated.selector);
        game.healCharacter(address(0));
    }

    function test_distributeRewards() public {
        vm.prank(owner);
        game.setBoss({_name: strongBoss.name, _maxHp: strongBoss.maxHp, _damage: strongBoss.damage, _xpReward: strongBoss.xpReward});

        // We hit the boss until it's about to die
        uint160 numberOfDeadCharacters;
        while (game.bossHp() > 2 * game.characterPhysicalDamage(characterAddress)) {
            address deadCharacter = address(numberOfDeadCharacters + 4);
            numberOfDeadCharacters++;
            vm.startPrank(deadCharacter);
            game.newCharacter();
            game.fightBoss();
            vm.stopPrank();
        }
        
        uint32 expectedDamageDealt = game.bossHp();
        uint32 expectedReward = uint32(uint64(expectedDamageDealt) * game.bossXpReward() / game.bossMaxHp());
        // Finish the boss with our character
        while (!game.isBossDead()) {
            vm.prank(characterAddress);
            game.fightBoss();
            // Heal our character because it's dead
            vm.prank(casterAddress);
            game.healCharacter(characterAddress);
        }
        uint64 healerXp = game.characterXp(casterAddress);

        vm.expectEmit();
        emit CharacterRewarded({
            characterAddress: characterAddress,
            bossName: game.bossName(),
            xpReward: expectedReward,
            totalDamageDealt: expectedDamageDealt
        });

        vm.prank(owner);
        game.distributeRewards();
        // The only fighter alive gets its xp based on the damage dealt
        assertEq(game.characterXp(characterAddress), expectedReward);
        // The healer didn't fight, no additional xp
        assertEq(game.characterXp(casterAddress), healerXp);
        // The other fighters are all dead, no xp
        for (uint160 index = 0; index < numberOfDeadCharacters; index++) {
            address deadCharacter = address(index + 4);
            assertEq(game.characterXp(deadCharacter), 0);
        }
    }
}
