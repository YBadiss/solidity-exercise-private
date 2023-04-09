// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";

// DONE
// 1. As an owner I want to inherit the admin permissions of the smart contract once it is deployed.
// 2. As an admin I want to be the only one able to populate the contract with customizable bosses.
//      - A new boss can't be populated if the current one isn't defeated.
//      - A dead character can no longer do anything but can be healed.
// 3. As a user I want to be able to pseudo-randomly generate **one** character per address.
// 4. As a user I want to be able to attack the current boss with my character.
//      - Everytime a player attacks the boss, the boss will counterattack. Both will lose life points.
// 5. As a user I should be able to heal other characters with my character.
//      - Players can't heal themselves.
//      - Only players who have already earned experience can cast the heal spell.
// 6. As a user I want to be able to claim rewards, such as experience, when defeating bosses.
//      - Only characters who attacked a boss can receive experience as reward.
//      - Only characters who are alive receive receive experience as reward.

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

contract GameTest is Test, IBoss, ICharacter {
    Game public game;
    address public owner = address(1);
    Boss boss = Boss({name: "Test Boss", maxHp: 1000, hp: 1000, damage: 50, xpReward: 10000});
    Boss weakBoss = Boss({name: "Weak Boss", maxHp: 1, hp: 1, damage: 50, xpReward: 10});
    Boss strongBoss = Boss({name: "Strong Boss", maxHp: 1000, hp: 1000, damage: 10000, xpReward: 100000000});
    address public characterAddress = address(2);
    Character public character;
    address public healerAddress = address(3);

    function setUp() public {
        game = new Game(owner);
        vm.prank(characterAddress);
        game.newCharacter();

        // Give some xp to the healer
        vm.prank(owner);
        game.setBoss(weakBoss);
        vm.startPrank(healerAddress);
        game.newCharacter();
        game.fightBoss();
        vm.stopPrank();
        vm.prank(owner);
        game.distributeRewards();
    }

    function test_bossTakesHit() public {
        vm.prank(owner);
        game.setBoss(boss);

        uint256 newBossHp = game.bossHp() - game.characterPhysicalDamage(characterAddress);
        uint256 newCharacterHp = game.characterHp(characterAddress) - game.bossDamage();
        vm.expectEmit();
        emit BossIsHit(game.bossName(), characterAddress, newBossHp, game.characterPhysicalDamage(characterAddress));
        vm.expectEmit();
        emit CharacterIsHit(characterAddress, game.bossName(), newCharacterHp, game.bossDamage());

        vm.prank(characterAddress);
        game.fightBoss();

        assertEq(game.bossHp(), newBossHp);
        assertEq(game.characterHp(characterAddress), newCharacterHp);
        assertEq(game.charactersInvolvedInFight(0), characterAddress);
        assertEq(game.damageDealtToBoss(characterAddress), game.characterPhysicalDamage(characterAddress));
    }

    function test_bossHpAlwaysAboveZero() public {
        vm.prank(owner);
        game.setBoss(weakBoss);

        uint256 newCharacterHp = game.characterHp(characterAddress) - game.bossDamage();
        vm.expectEmit();
        emit BossIsHit(game.bossName(), characterAddress, 0, game.bossHp());
        vm.expectEmit();
        emit CharacterIsHit(characterAddress, game.bossName(), newCharacterHp, game.bossDamage());
        vm.expectEmit();
        emit BossKilled(game.bossName(), characterAddress);

        vm.prank(characterAddress);
        game.fightBoss();
        assertEq(game.bossHp(), 0);
    }

    function test_characterHpAlwaysAboveZero() public {
        vm.prank(owner);
        game.setBoss(strongBoss);

        uint256 newBossHp = game.bossHp() - game.characterPhysicalDamage(characterAddress);
        vm.expectEmit();
        emit BossIsHit(game.bossName(), characterAddress, newBossHp, game.characterPhysicalDamage(characterAddress));
        vm.expectEmit();
        emit CharacterIsHit(characterAddress, game.bossName(), 0, game.characterHp(characterAddress));
        vm.expectEmit();
        emit CharacterKilled(characterAddress, game.bossName());

        vm.prank(characterAddress);
        game.fightBoss();
        assertEq(game.characterHp(characterAddress), 0);
    }

    function test_fightBoss_RevertsIf_bossIsDead() public {
        vm.prank(characterAddress);

        vm.expectRevert(IBoss.BossIsDead.selector);
        game.fightBoss();
    }

    function test_fightBoss_RevertsIf_characterNotCreated() public {
        vm.prank(owner);
        game.setBoss(boss);

        address notCharacterAddress = address(0);
        vm.prank(notCharacterAddress);

        vm.expectRevert(ICharacter.CharacterNotCreated.selector);
        game.fightBoss();
    }

    function test_fightBoss_RevertsIf_characterIsDead() public {
        vm.prank(owner);
        game.setBoss(strongBoss);

        vm.startPrank(characterAddress);
        game.fightBoss();
        vm.expectRevert(ICharacter.CharacterIsDead.selector);
        game.fightBoss();
    }

    function test_healCharacter() public {
        vm.prank(owner);
        game.setBoss(strongBoss);

        vm.prank(characterAddress);
        game.fightBoss();
        assertEq(game.characterHp(characterAddress), 0);


        vm.expectEmit();
        emit CharacterHealed(characterAddress, healerAddress, game.characterHeal(healerAddress), game.characterHeal(healerAddress));
        vm.prank(healerAddress);
        game.healCharacter(characterAddress);
        assertEq(game.characterHp(characterAddress), game.characterHeal(healerAddress));
    }

    function test_healCharacterNeverAboveMaxHp() public {
        assertEq(game.characterHp(characterAddress), game.characterMaxHp(characterAddress));
        vm.prank(healerAddress);
        game.healCharacter(characterAddress);
        assertEq(game.characterHp(characterAddress), game.characterMaxHp(characterAddress));
    }

    function test_healCharacter_RevertsIf_selfHeal() public {
        vm.prank(healerAddress);
        vm.expectRevert(ICharacter.CharacterCannotSelfHeal.selector);
        game.healCharacter(healerAddress);
    }

    function test_distributeRewards() public {
        vm.prank(owner);
        game.setBoss(strongBoss);

        // We hit the boss until it's about to die
        uint size = game.bossHp() / game.characterPhysicalDamage(characterAddress) - 1;
        address[] memory deadCharacters = new address[](size);
        for (uint160 index = 0; index < size; index++) {
            address deadCharacter = address(index + 4);
            vm.startPrank(deadCharacter);
            game.newCharacter();
            game.fightBoss();
            vm.stopPrank();
            deadCharacters[index] = deadCharacter;
        }
        
        // Finish the boss with our character
        vm.prank(characterAddress);
        game.fightBoss();

        // Heal our character because it's dead
        vm.prank(healerAddress);
        game.healCharacter(characterAddress);
        uint256 healerXp = game.characterXp(healerAddress);
        uint256 expectedReward = game.characterPhysicalDamage(characterAddress) * game.bossXpReward() / game.bossMaxHp();

        vm.expectEmit();
        emit CharacterRewarded({
            characterAddress: characterAddress,
            bossName: game.bossName(),
            xpReward: expectedReward,
            totalDamageDealt: game.characterPhysicalDamage(characterAddress)
        });

        vm.prank(owner);
        game.distributeRewards();
        // The only fighter alive gets its xp based on the damage dealt
        assertEq(game.characterXp(characterAddress), expectedReward);
        // The healer didn't fight, no additional xp
        assertEq(game.characterXp(healerAddress), healerXp);
        // The other fighters are all dead, no xp
        for (uint160 index = 0; index < deadCharacters.length; index++) {
            assertEq(game.characterXp(deadCharacters[index]), 0);
        }
    }
}
