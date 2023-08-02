use starknet::testing;
use subdomain_distribution::whitelist::Whitelist;
use subdomain_distribution::interface::whitelist::{
    IWhitelist, IWhitelistDispatcher, IWhitelistDispatcherTrait,
};

#[cfg(test)]
#[test]
#[available_gas(20000000000)]
fn test_get_amount_of_chars() {
    let mut unsafe_state = Whitelist::unsafe_new_contract_state();

    // Should return 0 (empty string)
    assert(
        Whitelist::InternalImpl::_get_amount_of_chars(@unsafe_state, u256 { low: 0, high: 0 }) == 0,
        'Should return 0'
    );

    // Should return 4 ("toto")
    assert(
        Whitelist::InternalImpl::_get_amount_of_chars(
            @unsafe_state, u256 { low: 796195, high: 0 }
        ) == 4,
        'Should return 4'
    );

    // Should return 5 ("aloha")
    assert(
        Whitelist::InternalImpl::_get_amount_of_chars(
            @unsafe_state, u256 { low: 77554770, high: 0 }
        ) == 5,
        'Should return 5'
    );

    // Should return 9 ("chocolate")
    assert(
        Whitelist::InternalImpl::_get_amount_of_chars(
            @unsafe_state, u256 { low: 19565965532212, high: 0 }
        ) == 9,
        'Should return 9'
    );

    // Should return 30 ("这来abcdefghijklmopqrstuvwyq1234")
    assert(
        Whitelist::InternalImpl::_get_amount_of_chars(
            @unsafe_state,
            integer::u256_from_felt252(801855144733576077820330221438165587969903898313)
        ) == 30,
        'Should return 30'
    );
}
