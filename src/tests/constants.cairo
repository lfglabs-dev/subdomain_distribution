fn OWNER() -> starknet::ContractAddress {
    starknet::contract_address_const::<10>()
}

fn OTHER() -> starknet::ContractAddress {
    starknet::contract_address_const::<20>()
}

fn USER() -> starknet::ContractAddress {
    starknet::contract_address_const::<123>()
}

fn ZERO() -> starknet::ContractAddress {
    Zeroable::zero()
}

fn ENCODED_ROOT() -> felt252 {
    1426911989
}

fn NAME() -> felt252 {
    1234567890
}

fn BLOCK_TIMESTAMP() -> u64 {
    103374042_u64
}

fn WHITELIST_PUB_KEY() -> felt252 {
    0xdfc4df0b563f28fce69277adbc05ddc034143d20f4754a851a6d9c7f297152
}

fn SIG_USER() -> (felt252, felt252) {
    (
        0x10480a56688d24dc6b807982e2231f34b99ec1fe669965d606e43a9d618b0af,
        0x2a7d2ce28478615c4818ae87f5230999cec36c299c23dab59a92975590261b2
    )
}

fn SIG_OTHER() -> (felt252, felt252) {
    (
        0x33032561be3230d530741ab96b0016b7c4037a2da185b464124a107792bf9ad,
        0x10fca5d3db77f136888981a7edaaebdf8899b2af6211268eb60ca8d8dd8cc4b
    )
}

fn WRONG_SIG() -> (felt252, felt252) {
    (0x123, 0x456)
}

fn WL_CLASS_HASH() -> felt252 {
    11111
}

fn OTHER_WL_CLASS_HASH() -> felt252 {
    222222
}

fn CLASS_HASH_ZERO() -> starknet::ClassHash {
    starknet::class_hash_const::<0>()
}

fn NEW_CLASS_HASH() -> starknet::ClassHash {
    starknet::class_hash_const::<10>()
}
