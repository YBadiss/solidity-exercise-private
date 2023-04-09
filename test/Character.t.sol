// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Character.sol";

contract CharacterTest is Test, ICharacter {
    _Character characterContract;
    address public characterAddress = address(2);

    function setUp() public {
        characterContract = new _Character({_baseEndurance: 10, _baseIntelligence: 10});
    }

    function test_newCharacter() public {
        Character memory character = characterContract.buildCharacter(block.prevrandao);
        vm.startPrank(characterAddress);

        vm.expectEmit();
        emit CharacterSpawned({
            characterAddress: characterAddress,
            maxHp: character.maxHp,
            physicalDamage: character.physicalDamage,
            heal: character.heal
        });
        assertFalse(characterContract.isCharacterCreated(characterAddress));
        characterContract.newCharacter();
        assertTrue(characterContract.isCharacterCreated(characterAddress));
    }

    function test_RevertIf_alreadyCreated() public {
        vm.startPrank(characterAddress);
        characterContract.newCharacter();

        vm.expectRevert(ICharacter.CharacterAlreadyCreated.selector);
        characterContract.newCharacter();
    }
}
