use starknet::contract_address::ContractAddressZeroable;

fn ADMIN() -> starknet::ContractAddress {
    starknet::contract_address_const::<0x123>()
}

fn USER() -> starknet::ContractAddress {
    starknet::contract_address_const::<0x124>()
}

fn OTHER() -> starknet::ContractAddress {
    starknet::contract_address_const::<0x456>()
}

fn ZERO() -> starknet::ContractAddress {
    ContractAddressZeroable::zero()
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
    0xd9ed53f9f4b64fedf2d0583141e366ec4e9c0348b30d7cdfdcc086eb9d64f
}

fn SIG_USER() -> (felt252, felt252) {
    (
        0x422d91037cbb407e5f0c801ac4147ad091a17fd3eee5090cd0be4550e2d6deb,
        0x5556e1b49bb92452441956b61328133b965da5c9e0dd5fa9af02f3c39523a9f
    )
}

fn SIG_OTHER() -> (felt252, felt252) {
    (
        0x389ec091bd6c94bf350aa219ca1a7825a3d539a56188be590bf31b40d7fdda2,
        0x4317516e88214e70b7e4e0d1c28900093fcf8b01d27b4779aa8da36475170f0
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
