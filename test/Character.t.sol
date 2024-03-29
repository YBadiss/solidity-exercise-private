// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Character.sol";

contract CharacterTest is Test, ICharacter {
    _Character characterContract;
    address public characterAddress = address(2);

    function setUp() public {
        characterContract = new _Character({_baseEndurance: 10, _baseIntelligence: 10, _baseLevelXp: 100});
    }

    function test_newCharacter() public {
        Character memory character = characterContract.buildCharacter(block.prevrandao);
        vm.startPrank(characterAddress);

        vm.expectEmit();
        emit CharacterSpawned({
            characterAddress: characterAddress,
            maxHp: character.maxHp,
            physicalDamage: character.physicalDamage,
            magicalDamage: character.magicalDamage
        });
        assertFalse(characterContract.isCharacterCreated(characterAddress));
        assertEq(characterContract.getActiveCharacters().length, 0);
        characterContract.newCharacter();
        assertTrue(characterContract.isCharacterCreated(characterAddress));
        assertEq(characterContract.getActiveCharacters().length, 1);
        assertEq(characterContract.getActiveCharacters()[0].addr, characterAddress);
    }

    function test_RevertIf_alreadyCreated() public {
        vm.startPrank(characterAddress);
        characterContract.newCharacter();

        vm.expectRevert(ICharacter.CharacterAlreadyCreated.selector);
        characterContract.newCharacter();
    }

    function test_characterLevelIsOne() public {
        vm.startPrank(characterAddress);
        characterContract.newCharacter();

        assertEq(characterContract.characterLevel(characterAddress), 1);
    }
}
