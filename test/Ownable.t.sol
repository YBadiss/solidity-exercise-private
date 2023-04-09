// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";
import "../src/utils/Ownable.sol";

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