// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Character.sol";

contract CharacterTest is Test, _Character {
    address public characterAddress = address(2);

    function setUp() public {
    }

    function test_newCharacter() public {
        Character memory character = this.buildCharacter(block.prevrandao);
        vm.startPrank(characterAddress);

        vm.expectEmit();
        emit CharacterSpawned({
            characterAddress: characterAddress,
            maxHp: character.maxHp,
            physicalDamage: character.physicalDamage,
            heal: character.heal
        });
        assertFalse(this.isCharacterCreated(characterAddress));
        this.newCharacter();
        assertTrue(this.isCharacterCreated(characterAddress));
    }

    function test_RevertIf_alreadyCreated() public {
        vm.startPrank(characterAddress);
        this.newCharacter();

        vm.expectRevert(ICharacter.CharacterAlreadyCreated.selector);
        this.newCharacter();
    }
}
