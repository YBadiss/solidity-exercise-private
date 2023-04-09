// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Boss.sol";

contract BossTest is Test, IBoss {
    _Boss bossContract;

    function setUp() public {
        bossContract = new _Boss();
    }

    function test_bossIsDeadByDefault() public {
        assertEq(bossContract.isBossDead(), true);
    }

    function test_setBoss() public {
        Boss memory boss = Boss({name: "Test Boss", maxHp: 1000, hp: 1000, damage: 50, xpReward: 10000});
        vm.expectEmit();
        emit BossSpawned({
            bossName: boss.name,
            maxHp: boss.hp,
            damage: boss.damage,
            xpReward: boss.xpReward
        });
        bossContract.setBoss(boss);
        assertFalse(bossContract.isBossDead());
    }
}