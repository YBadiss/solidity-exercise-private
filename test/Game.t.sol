// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";

contract GameTest is Test {
    Game public game;
    address public owner = address(1);

    function setUp() public {
        game = new Game(owner);
    }

    function test_ownerIsSet() public {
        assertEq(game.owner(), owner);
    }

    function test_setOwner() public {
        address newOwner = address(0);

        vm.prank(owner);
        game.setOwner(newOwner);
        assertEq(game.owner(), newOwner);

        vm.prank(newOwner);
        game.setOwner(owner);
        assertEq(game.owner(), owner);
    }

    function test_setOwner_RevertIf_notOwner() public {
        address notOwner = address(0);
        vm.startPrank(notOwner);

        vm.expectRevert(Ownable.NotOwner.selector);
        game.setOwner(notOwner);
    }
}

contract BossTest is Test {
    Game public game;
    Game.Boss boss = Game.Boss("Test Boss", 1000, 50, 10000);
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
        address notOwner = address(0);
        vm.startPrank(notOwner);

        vm.expectRevert(Ownable.NotOwner.selector);
        game.setBoss(boss);
    }

    function test_setBoss_RevertIf_notDead() public {
        vm.startPrank(owner);
        game.setBoss(boss);

        vm.expectRevert(Game.BossIsNotDead.selector);
        game.setBoss(boss);
    }

    function test_bossTakesHit() public {
        vm.startPrank(owner);
        game.setBoss(boss);

        uint256 startHp = game.bossHp();
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

        assertFalse(game.isBossDead());
        game.hitBoss(game.bossHp());
        assertTrue(game.isBossDead());
    }
}