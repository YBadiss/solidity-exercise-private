function assertEq {
    if [[ "$1" != "$2" ]]; then
        echo "Expected '$2', got '$1'";
        exit 1;
    fi
}

# Set up env vars
# Don't worry this is an anvil private key
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export OWNER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export CHARACTER_1=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
export CHARACTER_2=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
export CHARACTER_3=0x90F79bf6EB2c4f870365E785982E1f101E93b906

# Point RPC at sepolia
srpc sep
# Fork sepolia locally
anvil --fork-url $ETH_RPC_URL &
# Point RPC at sepolia
srpc local

# Build the contract
forge build
# Deploy the contract
forge create Game --rpc-url=$ETH_RPC_URL --private-key=$PRIVATE_KEY --constructor-args $OWNER 10 10
# Keep contract address
export GAME=0x054c25aAEd52d3f55942C6D1cfdeBce50895Db56
# Verify ownership
cast rpc anvil_impersonateAccount $OWNER
assertEq $(cast call $GAME "owner()(address)") $OWNER
cast send $GAME --from $OWNER "transferOwnership(address)" $CHARACTER_1
assertEq $(cast call $GAME "owner()(address)") $CHARACTER_1
cast send $GAME --from $CHARACTER_1 "transferOwnership(address)" $OWNER
assertEq $(cast call $GAME "owner()(address)") $OWNER

# Create characters
cast send $GAME --from $CHARACTER_1 "newCharacter()"
cast call $GAME "characters(address)(bool,uint32,uint32,uint32,uint32,uint64)" $CHARACTER_1
cast send $GAME --from $CHARACTER_2 "newCharacter()"
cast call $GAME "characters(address)(bool,uint32,uint32,uint32,uint32,uint64)" $CHARACTER_2
cast send $GAME --from $CHARACTER_3 "newCharacter()"
cast call $GAME "characters(address)(bool,uint32,uint32,uint32,uint32,uint64)" $CHARACTER_3

# Set a boss
cast send $GAME --from $OWNER "setBoss(string,uint32,uint32,uint32)" "Smoll Dragon" 200 10 1000
cast call $GAME "boss()(string,uint32,uint32,uint32,uint32)"

# Fight!
cast send $GAME --from $CHARACTER_1 "fightBoss()"
cast send $GAME --from $CHARACTER_2 "fightBoss()"
assertEq $(cast call $GAME "isBossDead()(bool)") "true"

# Rewards
cast send $GAME --from $OWNER "distributeRewards()"
cast call $GAME "characters(address)(bool,uint32,uint32,uint32,uint32,uint64)" $CHARACTER_1
cast call $GAME "characters(address)(bool,uint32,uint32,uint32,uint32,uint64)" $CHARACTER_2
cast call $GAME "characters(address)(bool,uint32,uint32,uint32,uint32,uint64)" $CHARACTER_3
