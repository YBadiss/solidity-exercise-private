// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";
import "../src/Boss.sol";

contract BossTest is Test, IBoss {
    Game public game;
    address public owner = address(1);
    Boss boss = Boss({name: "Test Boss", maxHp: 1000, hp: 1000, damage: 50, xpReward: 10000});

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
            maxHp: boss.hp,
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