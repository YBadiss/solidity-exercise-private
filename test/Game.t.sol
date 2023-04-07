// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";

contract GameTest is Test {
    Game public game;
    address public owner;

    function setUp() public {
        owner = address(1);
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
