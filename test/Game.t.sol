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

contract BossTest is Test, IBoss {
    Game public game;
    Boss boss = Boss("Test Boss", 1000, 50, 10000);
    address public owner = address(1);

    function setUp() public {
        game = new Game(owner);
    }

    function test_bossIsDeadByDefault() public {
        assertEq(game.isBossDead(), true);
    }

    function test_setBoss() public {
        vm.startPrank(owner);
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

    function test_bossTakesHit() public {
        vm.startPrank(owner);
        game.setBoss(boss);

        uint256 startHp = game.bossHp();
        vm.expectEmit();
        emit BossHit(boss.name, startHp - 10, 10);
        game.hitBoss(10);
        assertEq(game.bossHp(), startHp - 10);
    }

    function test_bossHpAlwaysAboveZero() public {
        vm.startPrank(owner);
        game.setBoss(boss);

        game.hitBoss(game.bossHp() + 1);
        assertEq(game.bossHp(), 0);
    }

    function test_bossIsDead() public {
        vm.startPrank(owner);
        game.setBoss(boss);

        vm.expectEmit();
        emit BossHit(boss.name, 0, boss.hp);
        vm.expectEmit();
        emit BossDied(boss.name);
        assertFalse(game.isBossDead());
        game.hitBoss(game.bossHp());
        assertTrue(game.isBossDead());
    }
}