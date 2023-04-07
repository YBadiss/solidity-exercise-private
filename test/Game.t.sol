// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";

contract OwnableTest is Test, IOwnableEvents {
    Game public game;
    address public owner = address(1);

    function setUp() public {
        vm.expectEmit();
        emit OwnershipTransferred(address(0), owner);

        game = new Game(owner);
    }

    function test_transferOwnership() public {
        address newOwner = address(2);

        vm.expectEmit();
        emit OwnershipTransferred(owner, newOwner);
        vm.prank(owner);
        game.transferOwnership(newOwner);
        assertEq(game.owner(), newOwner);

        vm.expectEmit();
        emit OwnershipTransferred(newOwner, owner);
        vm.prank(newOwner);
        game.transferOwnership(owner);
        assertEq(game.owner(), owner);
    }

    function test_transferOwnership_RevertIf_notOwner() public {
        address notOwner = address(2);
        vm.startPrank(notOwner);

        vm.expectRevert(Ownable.NotOwner.selector);
        game.transferOwnership(notOwner);
    }
}

contract CharacterTest is Test, ICharacter {
    Game public game;
    address public owner = address(1);
    address public characterAddress = address(2);
    Character public character;

    function setUp() public {
        game = new Game(owner);
        uint256 bonus = block.prevrandao % 5;
        uint256 hp = 1000 + 100 * bonus;
        uint256 damage = 100 + 10 * bonus;
        character = Character({created: true, hp: hp, damage: damage, xp: 0});
    }

    function test_newCharacter() public {
        vm.startPrank(characterAddress);

        vm.expectEmit();
        emit CharacterSpawned(characterAddress, character.hp, character.damage);
        (bool createdBefore, , ,) = game.characters(characterAddress);
        assertFalse(createdBefore);
        game.newCharacter();
        (bool createdAfter, , ,) = game.characters(characterAddress);
        assertTrue(createdAfter);
    }

    function test_RevertIf_alreadyCreated() public {
        vm.startPrank(characterAddress);
        game.newCharacter();

        vm.expectRevert(ICharacter.CharacterAlreadyCreated.selector);
        game.newCharacter();
    }
}

contract BossTest is Test, IBoss {
    Game public game;
    address public owner = address(1);
    Boss boss = Boss({name: "Test Boss", hp: 1000, damage: 50, xpReward: 10000});

    function setUp() public {
        game = new Game(owner);
    }

    function test_bossIsDeadByDefault() public {
        assertEq(game.isBossDead(), true);
    }

    function test_setBoss() public {
        vm.startPrank(owner);

        vm.expectEmit();
        emit BossSpawned(boss.name, boss.hp, boss.damage, boss.xpReward);
        game.setBoss(boss);
        assertFalse(game.isBossDead());
    }

    function test_setBoss_RevertIf_notOwner() public {
        address notOwner = address(2);
        vm.startPrank(notOwner);

        vm.expectRevert(Ownable.NotOwner.selector);
        game.setBoss(boss);
    }

    function test_setBoss_RevertIf_notDead() public {
        vm.startPrank(owner);
        game.setBoss(boss);

        vm.expectRevert(IBoss.BossIsNotDead.selector);
        game.setBoss(boss);
    }
}

contract GameTest is Test, IBoss, ICharacter {
    Game public game;
    address public owner = address(1);
    Boss boss = Boss({name: "Test Boss", hp: 1000, damage: 50, xpReward: 10000});
    Boss weakBoss = Boss({name: "Weak Boss", hp: 1, damage: 50, xpReward: 10});
    Boss strongBoss = Boss({name: "Strong Boss", hp: 1000, damage: 10000, xpReward: 100000000});
    address public characterAddress = address(2);
    Character public character;

    function setUp() public {
        game = new Game(owner);

        vm.prank(characterAddress);
        game.newCharacter();
        (bool created, uint256 hp, uint256 damage, uint256 xp) = game.characters(characterAddress);
        character = Character(created, hp, damage, xp);
    }

    function test_bossTakesHit() public {
        vm.prank(owner);
        game.setBoss(boss);

        uint256 newBossHp = game.bossHp() - character.damage;
        uint256 newCharacterHp = character.hp - game.bossDamage();
        vm.expectEmit();
        emit BossIsHit(game.bossName(), characterAddress, newBossHp, character.damage);
        vm.expectEmit();
        emit CharacterIsHit(characterAddress, game.bossName(), newCharacterHp, game.bossDamage());

        vm.prank(characterAddress);
        game.fightBoss();

        assertEq(game.bossHp(), newBossHp);
        (, uint256 characterHp, , ) = game.characters(characterAddress);
        assertEq(characterHp, newCharacterHp);
    }

    function test_bossHpAlwaysAboveZero() public {
        vm.prank(owner);
        game.setBoss(weakBoss);

        uint256 newCharacterHp = character.hp - game.bossDamage();
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
        game.setBoss(strongBoss);

        uint256 newBossHp = game.bossHp() - character.damage;
        vm.expectEmit();
        emit BossIsHit(game.bossName(), characterAddress, newBossHp, character.damage);
        vm.expectEmit();
        emit CharacterIsHit(characterAddress, game.bossName(), 0, character.hp);
        vm.expectEmit();
        emit CharacterKilled(characterAddress, game.bossName());

        vm.prank(characterAddress);
        game.fightBoss();
        (, uint256 characterHp, , ) = game.characters(characterAddress);
        assertEq(characterHp, 0);
    }

    function test_fightBoss_RevertsIf_bossIsDead() public {
        vm.prank(characterAddress);

        vm.expectRevert(IBoss.BossIsDead.selector);
        game.fightBoss();
    }

    function test_fightBoss_RevertsIf_characterNotCreated() public {
        vm.prank(owner);
        game.setBoss(boss);

        address notCharacterAddress = address(0);
        vm.prank(notCharacterAddress);

        vm.expectRevert(ICharacter.CharacterNotCreated.selector);
        game.fightBoss();
    }

    function test_fightBoss_RevertsIf_characterIsDead() public {
        vm.prank(owner);
        game.setBoss(strongBoss);

        vm.startPrank(characterAddress);
        game.fightBoss();
        vm.expectRevert(ICharacter.CharacterIsDead.selector);
        game.fightBoss();
    }

    function test_healCharacter() public {
        vm.prank(owner);
        game.setBoss(strongBoss);

        vm.prank(characterAddress);
        game.fightBoss();
        (, uint256 characterHp, , ) = game.characters(characterAddress);
        assertEq(characterHp, 0);

        address healerAddress = address(3);
        vm.startPrank(healerAddress);
        game.newCharacter();
        vm.expectEmit();
        emit CharacterHealed(characterAddress, healerAddress, game.baseHeal(), game.baseHeal());
        game.healCharacter(characterAddress);
        (, characterHp, , ) = game.characters(characterAddress);
        assertEq(characterHp, game.baseHeal());
    }

    function test_healCharacter_RevertsIf_selfHeal() public {
        vm.prank(characterAddress);
        vm.expectRevert(ICharacter.CharacterCannotSelfHeal.selector);
        game.healCharacter(characterAddress);
    }
}

// TODO
// define max hp for characters
