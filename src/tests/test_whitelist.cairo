use array::{ArrayTrait, SpanTrait};
use debug::PrintTrait;
use zeroable::Zeroable;
use traits::Into;

use starknet::ContractAddress;
use starknet::testing;
use super::common::deploy_contracts_whitelist;
use super::constants::{
    ENCODED_ROOT, NAME, ADMIN, USER, OTHER, ZERO, WL_CLASS_HASH, OTHER_WL_CLASS_HASH,
    NEW_CLASS_HASH, CLASS_HASH_ZERO, SIG_USER, SIG_OTHER, WRONG_SIG
};

use subdomain_distribution::whitelist::Whitelist;
use subdomain_distribution::interface::whitelist::{
    IWhitelist, IWhitelistDispatcher, IWhitelistDispatcherTrait
};
use super::mocks::erc20::ERC20;
use openzeppelin::token::erc20::interface::{
    IERC20Camel, IERC20CamelDispatcher, IERC20CamelDispatcherTrait
};
use super::mocks::identity::{Identity, IIdentity, IIdentityDispatcher, IIdentityDispatcherTrait};
use naming::interface::naming::{INaming, INamingDispatcher, INamingDispatcherTrait};
use naming::naming::main::Naming;
use naming::pricing::Pricing;
use naming::interface::pricing::{IPricingDispatcher, IPricingDispatcherTrait};

//
// Helpers
//

// mint a starknetid, buy a domain & 
// transfer it to the subdomain distribution contract
fn setup(
    erc20: IERC20CamelDispatcher,
    pricing: IPricingDispatcher,
    starknetid: IIdentityDispatcher,
    naming: INamingDispatcher,
    contract_address: ContractAddress
) {
    testing::set_contract_address(ADMIN());
    let token_id: u128 = 1;
    let (_, price) = pricing.compute_buy_price(7, 365);
    erc20.approve(naming.contract_address, price);
    starknetid.mint(token_id);
    naming.buy(token_id, ENCODED_ROOT(), 365_u16, ZERO(), ZERO(), 0, 0);
    starknetid.transferFrom(ADMIN(), contract_address, token_id);
}

#[test]
#[available_gas(20000000000)]
fn test_register() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();
    setup(erc20, pricing, starknetid, naming, contract.contract_address);

    // open registration
    contract.open_registration();

    // Should register a subdomain
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    let owner = naming.domain_to_id(array![NAME(), ENCODED_ROOT()].span());
    assert(owner.is_zero(), 'owner should be zero');
    contract.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id, SIG_USER());

    let owner = naming.domain_to_id(array![NAME(), ENCODED_ROOT()].span());
    assert(owner == user_token_id, 'Owner should be user');
}

#[test]
#[available_gas(20000000000)]
fn test_claim_domain_back() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();
    setup(erc20, pricing, starknetid, naming, contract.contract_address);

    // open registration
    contract.open_registration();

    // Should register a subdomain
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    contract.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id, SIG_USER());
    let owner = starknetid.owner_of(user_token_id);
    assert(owner == USER(), 'Owner should be admin');

    // Should claim subdomain back
    testing::set_contract_address(ADMIN());
    contract.claim_domain_back(array![NAME(), ENCODED_ROOT()].span());
    let owner = starknetid.owner_of(user_token_id);
    assert(owner == ADMIN(), 'Owner should be admin');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Caller not admin', 'ENTRYPOINT_FAILED',))]
fn test_claim_domain_back_fail_not_admin() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();
    setup(erc20, pricing, starknetid, naming, contract.contract_address);

    // open registration
    contract.open_registration();

    // Should register a subdomain
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    contract.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id, SIG_USER());
    let owner = starknetid.owner_of(user_token_id);
    assert(owner == USER(), 'Owner should be admin');

    // Should claim subdomain back
    testing::set_contract_address(OTHER());
    contract.claim_domain_back(array![NAME(), ENCODED_ROOT()].span());
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Registration is closed', 'ENTRYPOINT_FAILED',))]
fn test_register_fail_closed() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();
    setup(erc20, pricing, starknetid, naming, contract.contract_address);

    // Should revert registering a subdomain as registration is closed
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);

    contract.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id, SIG_USER());
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Cannot transfer root domain', 'ENTRYPOINT_FAILED',))]
fn test_register_fail_root() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();
    setup(erc20, pricing, starknetid, naming, contract.contract_address);

    // open registration
    contract.open_registration();

    // Should revert registering as we passed a root domain instead of a subdomain
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);

    contract.register(array![ENCODED_ROOT()].span(), user_token_id, SIG_USER());
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Caller already minted', 'ENTRYPOINT_FAILED',))]
fn test_claim_twice_fail() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();
    setup(erc20, pricing, starknetid, naming, contract.contract_address);

    // open registration
    contract.open_registration();

    // Claim a subdomain
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    contract.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id, SIG_USER());

    // Should revert claiming twice a subdomain
    contract.register(array![77554770, ENCODED_ROOT()].span(), user_token_id, SIG_USER());
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('This name is taken', 'ENTRYPOINT_FAILED',))]
fn test_claim_same_subdomain_fail() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();
    setup(erc20, pricing, starknetid, naming, contract.contract_address);

    // open registration
    contract.open_registration();

    // Claim a subdomain
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    contract.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id, SIG_USER());

    // Should revert claiming the same subdomain as USER
    testing::set_contract_address(OTHER());
    let other_token_id = 3;
    starknetid.mint(other_token_id);
    contract.register(array![NAME(), ENCODED_ROOT()].span(), other_token_id, SIG_OTHER());
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Not whitelisted', 'ENTRYPOINT_FAILED',))]
fn test_register_fail_wrong_sig() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();
    setup(erc20, pricing, starknetid, naming, contract.contract_address);

    // open registration
    contract.open_registration();

    // Should revert claiming subdomain because signature is invalid
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);

    contract.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id, WRONG_SIG());
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Name is less than 4 characters', 'ENTRYPOINT_FAILED',))]
fn test_register_fail_domain_too_short() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();
    setup(erc20, pricing, starknetid, naming, contract.contract_address);

    // open registration
    contract.open_registration();

    // Should revert claiming subdomain because subdomain "ben" is less than 4 characters
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);

    contract.register(array![18925, ENCODED_ROOT()].span(), user_token_id, SIG_USER());
}

#[test]
#[available_gas(200000000)]
fn test_change_implementation_class_hash() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();

    // Should change implementation class hash
    testing::set_contract_address(ADMIN());
    contract.upgrade(NEW_CLASS_HASH());
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('Caller not admin', 'ENTRYPOINT_FAILED',))]
fn test_change_implementation_class_hash_not_admin() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();

    // Should revert because the caller is not admin of the contract
    testing::set_contract_address(USER());
    contract.upgrade(NEW_CLASS_HASH());
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('Class hash cannot be zero', 'ENTRYPOINT_FAILED',))]
fn test_change_implementation_class_hash_0_failed() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, contract) = deploy_contracts_whitelist();

    // Should revert because the implementation class hash cannot be zero
    testing::set_contract_address(ADMIN());
    contract.upgrade(CLASS_HASH_ZERO());
}

