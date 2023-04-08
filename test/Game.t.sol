// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";

contract OwnableTest is Test, IOwnableEvents {
    Game public game;
    address public owner = address(1);

    function setUp() public {
        vm.expectEmit();
        emit OwnershipTransferred({
            previousOwner: address(0),
            newOwner: owner
        });

        game = new Game(owner);
    }

    function test_transferOwnership() public {
        address newOwner = address(2);

        vm.expectEmit();
        emit OwnershipTransferred({
            previousOwner: owner,
            newOwner: newOwner
        });
        vm.prank(owner);
        game.transferOwnership(newOwner);
        assertEq(game.owner(), newOwner);

        vm.expectEmit();
        emit OwnershipTransferred({
            previousOwner: newOwner,
            newOwner: owner
        });
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
        character = game.buildCharacter(block.prevrandao);
    }

    function test_newCharacter() public {
        vm.startPrank(characterAddress);

        vm.expectEmit();
        emit CharacterSpawned({
            characterAddress: characterAddress,
            maxHp: character.maxHp,
            physicalDamage: character.physicalDamage,
            heal: character.heal
        });
        assertFalse(game.isCharacterCreated(characterAddress));
        game.newCharacter();
        assertTrue(game.isCharacterCreated(characterAddress));
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
        emit BossSpawned({
            bossName: boss.name,
            hp: boss.hp,
            damage: boss.damage,
            xpReward: boss.xpReward
        });
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
    }

    function test_bossTakesHit() public {
        vm.prank(owner);
        game.setBoss(boss);

        uint256 newBossHp = game.bossHp() - game.characterPhysicalDamage(characterAddress);
        uint256 newCharacterHp = game.characterHp(characterAddress) - game.bossDamage();
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
        game.setBoss(weakBoss);

        uint256 newCharacterHp = game.characterHp(characterAddress) - game.bossDamage();
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

        uint256 newBossHp = game.bossHp() - game.characterPhysicalDamage(characterAddress);
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
        assertEq(game.characterHp(characterAddress), 0);

        address healerAddress = address(3);
        vm.startPrank(healerAddress);
        game.newCharacter();
        vm.expectEmit();
        emit CharacterHealed(characterAddress, healerAddress, game.characterHeal(healerAddress), game.characterHeal(healerAddress));
        game.healCharacter(characterAddress);
        assertEq(game.characterHp(characterAddress), game.characterHeal(healerAddress));
    }

    function test_healCharacterNeverAboveMaxHp() public {
        address healerAddress = address(3);
        vm.startPrank(healerAddress);
        game.newCharacter();

        assertEq(game.characterHp(characterAddress), game.characterMaxHp(characterAddress));
        game.healCharacter(characterAddress);
        assertEq(game.characterHp(characterAddress), game.characterMaxHp(characterAddress));
    }

    function test_healCharacter_RevertsIf_selfHeal() public {
        vm.prank(characterAddress);
        vm.expectRevert(ICharacter.CharacterCannotSelfHeal.selector);
        game.healCharacter(characterAddress);
    }
}
