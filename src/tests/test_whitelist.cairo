use array::ArrayTrait;
use debug::PrintTrait;
use zeroable::Zeroable;
use traits::Into;

use starknet::ContractAddress;
use starknet::testing;

use subdomain_distribution::whitelist::Whitelist;
use subdomain_distribution::interface::whitelist::{
    IWhitelist, IWhitelistDispatcher, IWhitelistDispatcherTrait
};

use super::mocks::starknetid::{
    StarknetId, MockStarknetIdABIDispatcher, MockStarknetIdABIDispatcherTrait
};
use super::mocks::naming::{Naming, MockNamingABIDispatcher, MockNamingABIDispatcherTrait};
use super::constants::{
    ENCODED_ROOT, NAME, OWNER, USER, ZERO, OTHER, WL_CLASS_HASH, OTHER_WL_CLASS_HASH,
    NEW_CLASS_HASH, CLASS_HASH_ZERO, WHITELIST_PUB_KEY, SIG_USER, SIG_OTHER, WRONG_SIG
};
use super::utils;

//
// Helpers
//

#[cfg(test)]
fn setup(
    admin: ContractAddress, starknetid_contract: ContractAddress, naming_contract: ContractAddress
) -> IWhitelistDispatcher {
    let mut calldata = ArrayTrait::<felt252>::new();
    calldata.append(admin.into());
    calldata.append(starknetid_contract.into());
    calldata.append(naming_contract.into());
    calldata.append(WHITELIST_PUB_KEY());
    let address = utils::deploy(Whitelist::TEST_CLASS_HASH, calldata);
    IWhitelistDispatcher { contract_address: address }
}

#[cfg(test)]
fn deploy_starknetid() -> MockStarknetIdABIDispatcher {
    let address = utils::deploy(StarknetId::TEST_CLASS_HASH, ArrayTrait::<felt252>::new());
    MockStarknetIdABIDispatcher { contract_address: address }
}

#[cfg(test)]
fn deploy_naming(
    starknetid_addr: ContractAddress, pricing_addr: ContractAddress, erc20_addr: ContractAddress
) -> MockNamingABIDispatcher {
    let mut calldata = ArrayTrait::<felt252>::new();
    calldata.append(starknetid_addr.into());
    calldata.append(pricing_addr.into());
    calldata.append(erc20_addr.into());

    let address = utils::deploy(Naming::TEST_CLASS_HASH, calldata);
    MockNamingABIDispatcher { contract_address: address }
}

#[cfg(test)]
fn build_subdomain(a: felt252, b: felt252) -> Array<felt252> {
    let mut subdomain = ArrayTrait::<felt252>::new();
    subdomain.append(a);
    subdomain.append(b);
    subdomain
}

#[cfg(test)]
#[test]
#[available_gas(20000000000)]
fn test_register() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // mint a starknetid & buy a domain
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    let token_id = 1;
    starknetid.mint(token_id);
    naming.buy(token_id, ENCODED_ROOT(), 365, 0, OWNER());

    // open registration
    contract.open_registration();

    // Should register a subdomain
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);

    let owner = naming.domain_to_token_id(build_subdomain(NAME(), ENCODED_ROOT()).span());
    assert(owner.is_zero(), 'owner should be zero');

    contract.register(build_subdomain(NAME(), ENCODED_ROOT()), user_token_id, SIG_USER());

    let owner = naming.domain_to_token_id(build_subdomain(NAME(), ENCODED_ROOT()).span());
    assert(owner == user_token_id, 'Owner should be user');
}

#[cfg(test)]
#[test]
#[available_gas(20000000000)]
fn test_claim_domain_back() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // mint a starknetid & buy a domain
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    let token_id = 1;
    starknetid.mint(token_id);
    naming.buy(token_id, ENCODED_ROOT(), 365, 0, OWNER());

    // open registration
    contract.open_registration();

    // Should register a subdomain
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    contract.register(build_subdomain(NAME(), ENCODED_ROOT()), user_token_id, SIG_USER());
    let owner = starknetid.owner_of(user_token_id);
    assert(owner == USER(), 'Owner should be admin');

    // Should claim subdomain back
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    contract.claim_domain_back(build_subdomain(NAME(), ENCODED_ROOT()));
    let owner = starknetid.owner_of(user_token_id);
    assert(owner == OWNER(), 'Owner should be admin');
}

#[cfg(test)]
#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Caller not admin', 'ENTRYPOINT_FAILED', ))]
fn test_claim_domain_back_fail_not_admin() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // mint a starknetid & buy a domain
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    let token_id = 1;
    starknetid.mint(token_id);
    naming.buy(token_id, ENCODED_ROOT(), 365, 0, OWNER());

    // open registration
    contract.open_registration();

    // Should register a subdomain
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    contract.register(build_subdomain(NAME(), ENCODED_ROOT()), user_token_id, SIG_USER());
    let owner = starknetid.owner_of(user_token_id);
    assert(owner == USER(), 'Owner should be admin');

    // Should claim subdomain back
    testing::set_caller_address(OTHER());
    testing::set_contract_address(OTHER());
    contract.claim_domain_back(build_subdomain(NAME(), ENCODED_ROOT()));
}

#[cfg(test)]
#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Registration is closed', 'ENTRYPOINT_FAILED', ))]
fn test_register_fail_closed() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // mint a starknetid & buy a domain
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    let token_id = 1;
    starknetid.mint(token_id);
    naming.buy(token_id, ENCODED_ROOT(), 365, 0, OWNER());

    // Should revert registering a subdomain as registration is closed
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);

    contract.register(build_subdomain(NAME(), ENCODED_ROOT()), user_token_id, SIG_USER());
}

#[cfg(test)]
#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Cannot transfer root domain', 'ENTRYPOINT_FAILED', ))]
fn test_register_fail_root() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // mint a starknetid & buy a domain
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    let token_id = 1;
    starknetid.mint(token_id);
    naming.buy(token_id, ENCODED_ROOT(), 365, 0, OWNER());

    // open registration
    contract.open_registration();

    // Should revert registering as we passed a root domain instead of a subdomain
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);

    let mut domain = ArrayTrait::<felt252>::new();
    domain.append(ENCODED_ROOT());
    contract.register(domain, user_token_id, SIG_USER());
}

#[cfg(test)]
#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Caller already minted', 'ENTRYPOINT_FAILED', ))]
fn test_claim_twice_fail() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // mint a starknetid & buy a domain
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    let token_id = 1;
    starknetid.mint(token_id);
    naming.buy(token_id, ENCODED_ROOT(), 365, 0, OWNER());

    // open registration
    contract.open_registration();

    // Claim a subdomain
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    contract.register(build_subdomain(NAME(), ENCODED_ROOT()), user_token_id, SIG_USER());

    // Should revert claiming twice a subdomain
    contract.register(build_subdomain(77554770, ENCODED_ROOT()), user_token_id, SIG_USER());
}

#[cfg(test)]
#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('This name is taken', 'ENTRYPOINT_FAILED', ))]
fn test_claim_same_subdomain_fail() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // mint a starknetid & buy a domain
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    let token_id = 1;
    starknetid.mint(token_id);
    naming.buy(token_id, ENCODED_ROOT(), 365, 0, OWNER());

    // open registration
    contract.open_registration();

    // Claim a subdomain
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    contract.register(build_subdomain(NAME(), ENCODED_ROOT()), user_token_id, SIG_USER());

    // Should revert claiming the same subdomain as USER
    testing::set_caller_address(OTHER());
    testing::set_contract_address(OTHER());
    let other_token_id = 3;
    starknetid.mint(other_token_id);
    contract.register(build_subdomain(NAME(), ENCODED_ROOT()), other_token_id, SIG_OTHER());
}

#[cfg(test)]
#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Not whitelisted', 'ENTRYPOINT_FAILED', ))]
fn test_register_fail_wrong_sig() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // mint a starknetid & buy a domain
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    let token_id = 1;
    starknetid.mint(token_id);
    naming.buy(token_id, ENCODED_ROOT(), 365, 0, OWNER());

    // open registration
    contract.open_registration();

    // Should revert claiming subdomain because signature is invalid
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);

    contract.register(build_subdomain(NAME(), ENCODED_ROOT()), user_token_id, WRONG_SIG());
}

#[cfg(test)]
#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Name is less than 4 characters', 'ENTRYPOINT_FAILED', ))]
fn test_register_fail_domain_too_short() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // mint a starknetid & buy a domain
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    let token_id = 1;
    starknetid.mint(token_id);
    naming.buy(token_id, ENCODED_ROOT(), 365, 0, OWNER());

    // open registration
    contract.open_registration();

    // Should revert claiming subdomain because subdomain "ben" is less than 4 characters
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);

    contract.register(build_subdomain(18925, ENCODED_ROOT()), user_token_id, SIG_USER());
}

#[cfg(test)]
#[test]
#[available_gas(200000000)]
fn test_change_implementation_class_hash() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // Should change implementation class hash
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    contract.upgrade(NEW_CLASS_HASH());
}

#[cfg(test)]
#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('Caller not admin', 'ENTRYPOINT_FAILED', ))]
fn test_change_implementation_class_hash_not_admin() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // Should revert because the caller is not admin of the contract
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    contract.upgrade(NEW_CLASS_HASH());
}

#[cfg(test)]
#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('Class hash cannot be zero', 'ENTRYPOINT_FAILED', ))]
fn test_change_implementation_class_hash_0_failed() {
    let starknetid = deploy_starknetid();
    let naming = deploy_naming(starknetid.contract_address, ZERO(), ZERO());
    let contract = setup(OWNER(), starknetid.contract_address, naming.contract_address);

    // Should revert because the implementation class hash cannot be zero
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    contract.upgrade(CLASS_HASH_ZERO());
}

