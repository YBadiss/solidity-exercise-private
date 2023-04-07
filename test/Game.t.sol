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

    function test_setOwner_RevertIf_notOwner() public {
        vm.expectRevert(Ownable.NotOwner.selector);

        address notOwner = address(0);

        vm.prank(notOwner);
        game.setOwner(notOwner);
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
}

contract BossTest is Test {
    Boss public boss;
    string public name = "Test Boss";
    uint256 public hp = 1000;
    uint256 public damage = 50;
    uint256 public xpReward = 10000;

    function setUp() public {
        boss = new Boss(name, hp, damage, xpReward);
    }

    function test_bossIsSet() public {
        assertEq(boss.name(), name);
        assertEq(boss.hp(), hp);
        assertEq(boss.damage(), damage);
        assertEq(boss.xpReward(), xpReward);
    }

    function test_bossTakesHit() public {
        assertEq(boss.hp(), hp);
        boss.hit(10);
        assertEq(boss.hp(), hp - 10);
    }

    function test_bossHpAlwaysAboveZero() public {
        boss.hit(boss.hp() + 1);
        assertEq(boss.hp(), 0);
    }

    function test_bossIsDead() public {
        assertFalse(boss.isDead());
        boss.hit(boss.hp());
        assertTrue(boss.isDead());
    }
}