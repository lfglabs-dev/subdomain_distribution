use super::utils;
use super::constants::{ADMIN, WHITELIST_PUB_KEY};

use super::mocks::identity::{Identity, IIdentityDispatcher, IIdentityDispatcherTrait};
use super::mocks::erc20::ERC20;
use openzeppelin::token::erc20::interface::{
    IERC20Camel, IERC20CamelDispatcher, IERC20CamelDispatcherTrait
};
use naming::naming::main::Naming;
use naming::interface::naming::{INamingDispatcher, INamingDispatcherTrait};
use naming::pricing::Pricing;
use naming::interface::pricing::{IPricingDispatcher, IPricingDispatcherTrait};

use subdomain_distribution::simple::SimpleSubdomainDistribution;
use subdomain_distribution::interface::simple::{
    ISimpleSubdomainDistribution, ISimpleSubdomainDistributionDispatcher,
    ISimpleSubdomainDistributionDispatcherTrait
};

use subdomain_distribution::whitelist::Whitelist;
use subdomain_distribution::interface::whitelist::{
    IWhitelist, IWhitelistDispatcher, IWhitelistDispatcherTrait
};

fn deploy_contracts_simple() -> (
    IERC20CamelDispatcher,
    IPricingDispatcher,
    IIdentityDispatcher,
    INamingDispatcher,
    ISimpleSubdomainDistributionDispatcher
) {
    // erc20
    let eth = utils::deploy(ERC20::TEST_CLASS_HASH, array!['ether', 'ETH', 0, 1, ADMIN().into()]);
    // pricing
    let pricing = utils::deploy(Pricing::TEST_CLASS_HASH, array![eth.into()]);
    // identity
    let identity = utils::deploy(Identity::TEST_CLASS_HASH, ArrayTrait::<felt252>::new());
    // naming
    let naming = utils::deploy(
        Naming::TEST_CLASS_HASH, array![identity.into(), pricing.into(), 0, ADMIN().into()]
    );
    // autorenewal
    let simple = utils::deploy(
        SimpleSubdomainDistribution::TEST_CLASS_HASH,
        array![ADMIN().into(), identity.into(), naming.into()]
    );

    (
        IERC20CamelDispatcher { contract_address: eth },
        IPricingDispatcher { contract_address: pricing },
        IIdentityDispatcher { contract_address: identity },
        INamingDispatcher { contract_address: naming },
        ISimpleSubdomainDistributionDispatcher { contract_address: simple }
    )
}

fn deploy_contracts_whitelist() -> (
    IERC20CamelDispatcher,
    IPricingDispatcher,
    IIdentityDispatcher,
    INamingDispatcher,
    IWhitelistDispatcher
) {
    // erc20
    let eth = utils::deploy(ERC20::TEST_CLASS_HASH, array!['ether', 'ETH', 0, 1, ADMIN().into()]);
    // pricing
    let pricing = utils::deploy(Pricing::TEST_CLASS_HASH, array![eth.into()]);
    // identity
    let identity = utils::deploy(Identity::TEST_CLASS_HASH, ArrayTrait::<felt252>::new());
    // naming
    let naming = utils::deploy(
        Naming::TEST_CLASS_HASH, array![identity.into(), pricing.into(), 0, ADMIN().into()]
    );
    // autorenewal
    let whitelist = utils::deploy(
        Whitelist::TEST_CLASS_HASH,
        array![ADMIN().into(), identity.into(), naming.into(), WHITELIST_PUB_KEY()]
    );

    (
        IERC20CamelDispatcher { contract_address: eth },
        IPricingDispatcher { contract_address: pricing },
        IIdentityDispatcher { contract_address: identity },
        INamingDispatcher { contract_address: naming },
        IWhitelistDispatcher { contract_address: whitelist }
    )
}
