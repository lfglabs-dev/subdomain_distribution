use array::ArrayTrait;
use debug::PrintTrait;
use zeroable::Zeroable;
use traits::Into;

use starknet::ContractAddress;
use starknet::testing;
use super::common::deploy_contracts_simple;
use super::constants::{
    ENCODED_ROOT, NAME, ADMIN, USER, OTHER, ZERO, WL_CLASS_HASH, OTHER_WL_CLASS_HASH,
    NEW_CLASS_HASH, CLASS_HASH_ZERO
};

use subdomain_distribution::simple::SimpleSubdomainDistribution;
use subdomain_distribution::interface::simple::{
    ISimpleSubdomainDistribution, ISimpleSubdomainDistributionDispatcher,
    ISimpleSubdomainDistributionDispatcherTrait
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
    // initialize contracts & setup test
    let (erc20, pricing, starknetid, naming, simple) = deploy_contracts_simple();
    setup(erc20, pricing, starknetid, naming, simple.contract_address);

    // open registration
    simple.open_registration();

    // Should register a subdomain
    testing::set_contract_address(USER());
    let user_token_id: u128 = 2;
    starknetid.mint(user_token_id);
    let owner = naming.domain_to_id(array![NAME(), ENCODED_ROOT()].span());
    assert(owner.is_zero(), 'owner should be zero');
    simple.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id);

    let owner = naming.domain_to_id(array![NAME(), ENCODED_ROOT()].span());
    assert(owner == user_token_id, 'Owner should be user');
}

#[test]
#[available_gas(20000000000)]
fn test_claim_domain_back() {
    // initialize contracts & setup test
    let (erc20, pricing, starknetid, naming, simple) = deploy_contracts_simple();
    setup(erc20, pricing, starknetid, naming, simple.contract_address);

    // open registration
    simple.open_registration();

    // Should register a subdomain
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    simple.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id);
    let owner = starknetid.owner_of(user_token_id);
    assert(owner == USER(), 'Owner should be admin');

    // Should claim subdomain back
    testing::set_contract_address(ADMIN());
    simple.claim_domain_back(array![NAME(), ENCODED_ROOT()].span());
    let owner = starknetid.owner_of(user_token_id);
    assert(owner == ADMIN(), 'Owner should be admin');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Caller not admin', 'ENTRYPOINT_FAILED',))]
fn test_claim_domain_back_fail_not_admin() {
    // initialize contracts & setup test
    let (erc20, pricing, starknetid, naming, simple) = deploy_contracts_simple();
    setup(erc20, pricing, starknetid, naming, simple.contract_address);

    // open registration
    simple.open_registration();

    // Should register a subdomain
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    simple.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id);
    let owner = starknetid.owner_of(user_token_id);
    assert(owner == USER(), 'Owner should be admin');

    // Should revert claiming subdomain back as caller is not admin
    testing::set_contract_address(USER());
    simple.claim_domain_back(array![NAME(), ENCODED_ROOT()].span());
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Registration is closed', 'ENTRYPOINT_FAILED',))]
fn test_register_fail_closed() {
    // initialize contracts & setup test
    let (erc20, pricing, starknetid, naming, simple) = deploy_contracts_simple();
    setup(erc20, pricing, starknetid, naming, simple.contract_address);

    // Should revert registering a subdomain as registration is closed
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);

    simple.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Cannot transfer root domain', 'ENTRYPOINT_FAILED',))]
fn test_register_fail_root() {
    // initialize contracts & setup test
    let (erc20, pricing, starknetid, naming, simple) = deploy_contracts_simple();
    setup(erc20, pricing, starknetid, naming, simple.contract_address);

    // open registration
    simple.open_registration();

    // Should revert registering as we passed a root domain instead of a subdomain
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);

    simple.register(array![ENCODED_ROOT()].span(), user_token_id);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Caller already minted', 'ENTRYPOINT_FAILED',))]
fn test_claim_twice_fail() {
    // initialize contracts & setup test
    let (erc20, pricing, starknetid, naming, simple) = deploy_contracts_simple();
    setup(erc20, pricing, starknetid, naming, simple.contract_address);

    // open registration
    simple.open_registration();

    // Claim a subdomain
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    simple.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id);

    // Should revert claiming twice a subdomain
    simple.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('This name is taken', 'ENTRYPOINT_FAILED',))]
fn test_claim_same_subdomain_fail() {
    // initialize contracts & setup test
    let (erc20, pricing, starknetid, naming, simple) = deploy_contracts_simple();
    setup(erc20, pricing, starknetid, naming, simple.contract_address);

    // open registration
    simple.open_registration();

    // Claim a subdomain
    testing::set_contract_address(USER());
    let user_token_id = 2;
    starknetid.mint(user_token_id);
    simple.register(array![NAME(), ENCODED_ROOT()].span(), user_token_id);

    // Should revert claiming the same subdomain as USER
    testing::set_contract_address(OTHER());
    let other_token_id = 3;
    starknetid.mint(other_token_id);
    simple.register(array![NAME(), ENCODED_ROOT()].span(), other_token_id);
}

#[test]
#[available_gas(200000000)]
fn test_change_implementation_class_hash() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, simple) = deploy_contracts_simple();
    testing::set_contract_address(ADMIN());

    // Should change implementation class hash
    simple.upgrade(NEW_CLASS_HASH());
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('Caller not admin', 'ENTRYPOINT_FAILED',))]
fn test_change_implementation_class_hash_not_admin() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, simple) = deploy_contracts_simple();
    testing::set_contract_address(USER());

    // Should revert because the caller is not admin of the contract
    simple.upgrade(NEW_CLASS_HASH());
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('Class hash cannot be zero', 'ENTRYPOINT_FAILED',))]
fn test_change_implementation_class_hash_0_failed() {
    // initialize contracts
    let (erc20, pricing, starknetid, naming, simple) = deploy_contracts_simple();
    testing::set_contract_address(ADMIN());

    // Should revert because the implementation class hash cannot be zero
    simple.upgrade(CLASS_HASH_ZERO());
}

