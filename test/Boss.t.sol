// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Boss.sol";

contract BossTest is Test, _Boss {
    function setUp() public {
    }

    function test_bossIsDeadByDefault() public {
        assertEq(isBossDead(), true);
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
        _setBoss(boss);
        assertFalse(isBossDead());
    }
}