//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

interface IOwnableEvents {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract Ownable is IOwnableEvents {
    // TODO how do I properly define that we support interface 0x7f5828d0?

    address public owner;

    /// Errors
    error NotOwner();

    /// @notice Modifier to enforce ownership control
    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external onlyOwner {
        address previousOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previousOwner, owner);
    }
}

interface IBossEvents {
    /// @dev This emits when the Boss is created.
    event BossSpawned(string indexed bossName, uint256 hp, uint256 damage, uint256 xpReward);
    /// @dev This emits when the Boss is hit.
    event BossHit(string indexed bossName, uint256 bossHp, uint256 damageDealtByBoss, address indexed characterAddress, uint256 characterHp, uint256 damageDealtByCharacter);
    /// @dev This emits when the Boss dies.
    event BossKilled(string indexed bossName, address indexed characterAddress);
}

interface IBoss is IBossEvents {
    /// @notice Boss structure
    /// @param name Name of the Boss
    /// @param hp Life points of the Boss
    /// @param damage Damage inflicted by the Boss on each attack
    /// @param xpReward Experience reward split between all fighters
    struct Boss {
        string name;
        uint256 hp;
        uint256 damage;
        uint256 xpReward;
    }

    /// Errors
    error BossIsNotDead();
    error BossIsDead();
}

interface ICharacterEvents {
    /// @dev This emits when the Character is created.
    event CharacterSpawned(address indexed characterAddress, uint256 hp, uint256 damage);
    /// @dev This emits when the Character dies.
    event CharacterKilled(address indexed characterAddress, string indexed bossName);
}

interface ICharacter is ICharacterEvents {
    /// @notice Character structure
    /// @dev The parameters should be generated randomly
    /// @param created Whether the Character is empty or not
    /// @param hp Life points of the Character
    /// @param damage Damage inflicted by the Character on each attack
    /// @param xp Experience earned by the Character
    struct Character {
        bool created;
        uint256 hp;
        uint256 damage;
        uint256 xp;
    }

    /// Errors
    error CharacterAlreadyCreated();
    error CharacterNotCreated();
    error CharacterIsDead();
}

/// @title World Of Ledger
/// @author Yacine B. Badiss
/// @notice Create a character linked to your address and fight monsters!
/// @dev Main contract controlling the game flow
contract Game is Ownable, IBoss, ICharacter {
    ////////////////////////////////////////////////////////////////////////
    /// All about the characters
    ////////////////////////////////////////////////////////////////////////

    mapping(address => Character) public characters;

    function newCharacter() external {
        if (characters[msg.sender].created) {
            revert CharacterAlreadyCreated();
        }

        uint256 bonus = block.prevrandao % 5;
        uint256 hp = 1000 + 100 * bonus;
        uint256 damage = 100 + 10 * bonus;
        Character memory character = Character({created: true, hp: hp, damage: damage, xp: 0});
        characters[msg.sender] = character;

        emit CharacterSpawned(msg.sender, character.hp, character.damage);
    }

    ////////////////////////////////////////////////////////////////////////
    /// All about the boss
    ////////////////////////////////////////////////////////////////////////

    /// @notice Current Boss players can fight against
    Boss public boss;

    /// @notice Set a new Boss
    /// @dev Only for the owner, and if the boss is already dead
    /// @param _boss New boss to set
    function setBoss(Boss memory _boss) external onlyOwner {
        if (this.isBossDead()) {
            boss = _boss;
            emit BossSpawned(boss.name, boss.hp, boss.damage, boss.xpReward);
        } else {
            revert BossIsNotDead();
        }
    }

    /// @notice Get the name of the boss
    /// @return string Name of the boss
    function bossName() external view returns(string memory) {
        return boss.name;
    }
    
    /// @notice Get the hp of the boss
    /// @return uint256 Current HP of the boss
    function bossHp() external view returns(uint256) {
        return boss.hp;
    }
    
    /// @notice Get the damage inflicted by the boss on each attack
    /// @return uint256 Damage inflicted
    function bossDamage() external view returns(uint256) {
        return boss.damage;
    }
    
    /// @notice Get the xp reward split between all fighters when the boss dies
    /// @return uint256 XP reward
    function bossXpReward() external view returns(uint256) {
        return boss.xpReward;
    }

    /// @notice Check if the Boss is dead
    /// @dev hp is unsigned, we don't check negative values
    /// @return bool true if dead, false otherwise
    function isBossDead() view public returns(bool) {
        return boss.hp == 0;
    }

    /// @notice Hit the Boss using the character of the caller
    /// @dev We make sure that hp does not go below 0 since it is unsigned
    function hitBoss() external {
        // Don't allow hitting a boss that is dead
        if (isBossDead()) revert BossIsDead();

        address characterAddress = msg.sender;
        Character memory character = characters[characterAddress];
        // Don't allow using a character not created
        if (!character.created) revert CharacterNotCreated();
        // Don't allow using a character that is not alive
        if (character.hp == 0) revert CharacterIsDead();

        uint256 damageDealtByCharacter = calculateDamageDealt(character.damage, boss.hp);
        boss.hp -= damageDealtByCharacter;

        uint256 damageDealtByBoss = calculateDamageDealt(boss.damage, character.hp);
        character.hp -= damageDealtByBoss;
        characters[characterAddress] = character;
        
        emit BossHit(boss.name, boss.hp, damageDealtByBoss, characterAddress, character.hp, damageDealtByCharacter);
        if (boss.hp == 0) {
            emit BossKilled(boss.name, characterAddress);
        }
        if (character.hp == 0) {
            emit CharacterKilled(characterAddress, boss.name);
        }
    }

    ////////////////////////////////////////////////////////////////////////
    /// Game mechanic
    ////////////////////////////////////////////////////////////////////////

    /// @notice Instantiate a new contract and set its owner
    /// @dev `owner` is defined in the Ownable interface
    /// @param _owner New owner of the contract
    constructor(address _owner) {
        owner = _owner;
        emit OwnershipTransferred(address(0), owner);
    }

    function calculateDamageDealt(uint256 damage, uint256 hp) public pure returns(uint256) {
        return damage >= hp ? hp : damage;
    }
}
