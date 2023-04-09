// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";
import "../src/Character.sol";

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
