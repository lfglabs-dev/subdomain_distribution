use core::option::OptionTrait;
#[starknet::interface]
trait INaming<TContractState> {
    fn buy(
        ref self: TContractState,
        token_id: felt252,
        domain: felt252,
        days: felt252,
        resolver: felt252,
        address: starknet::ContractAddress,
    );

    fn domain_to_address(
        self: @TContractState, domain: Span::<felt252>
    ) -> starknet::ContractAddress;

    fn domain_to_token_id(self: @TContractState, domain: Span<felt252>) -> felt252;

    fn set_domain_to_address(
        ref self: TContractState, domain: Span<felt252>, address: starknet::ContractAddress
    );

    fn transfer_domain(ref self: TContractState, domain: Span<felt252>, target_token_id: felt252, );
}

#[starknet::interface]
trait MockNamingABI<TContractState> {
    fn buy(
        ref self: TContractState,
        token_id: felt252,
        domain: felt252,
        days: felt252,
        resolver: felt252,
        address: starknet::ContractAddress,
    );

    fn domain_to_address(
        self: @TContractState, domain: Span::<felt252>
    ) -> starknet::ContractAddress;

    fn domain_to_token_id(self: @TContractState, domain: Span<felt252>) -> felt252;

    fn set_domain_to_address(
        ref self: TContractState, domain: Span<felt252>, address: starknet::ContractAddress
    );

    fn transfer_domain(ref self: TContractState, domain: Span<felt252>, target_token_id: felt252, );
}

#[starknet::contract]
mod Naming {
    use super::INaming;
    use zeroable::Zeroable;
    use array::{ArrayTrait, SpanTrait};
    use traits::Into;
    use option::OptionTrait;
    use integer::u256_from_felt252;
    use subdomain_distribution::tests::mocks::erc20::{
        IERC20, IERC20Dispatcher, IERC20DispatcherTrait
    };
    use debug::PrintTrait;

    #[derive(Serde, Copy, Drop, starknet::Store)]
    struct DomainData {
        owner: felt252,
        address: starknet::ContractAddress,
        expiry: felt252,
        key: felt252,
        parent_key: felt252,
    }

    //
    // Storage
    //

    #[storage]
    struct Storage {
        starknetid_contract: starknet::ContractAddress,
        _pricing_contract: starknet::ContractAddress,
        _erc20_address: starknet::ContractAddress,
        _domain_data: LegacyMap::<felt252, DomainData>,
    }

    //
    // Constructor
    //

    #[constructor]
    fn constructor(
        ref self: ContractState,
        starknetid_addr: starknet::ContractAddress,
        pricing_addr: starknet::ContractAddress,
        erc20_addr: starknet::ContractAddress
    ) {
        self.starknetid_contract.write(starknetid_addr);
        self._pricing_contract.write(pricing_addr);
        self._erc20_address.write(erc20_addr);
    }

    //
    // Interface impl
    //

    #[external(v0)]
    impl INamingImpl of INaming<ContractState> {
        fn domain_to_address(
            self: @ContractState, domain: Span::<felt252>
        ) -> starknet::ContractAddress {
            let hashed_domain = self._hashed_domain(domain);
            let domain_data = self._domain_data.read(hashed_domain);
            domain_data.address
        }

        fn buy(
            ref self: ContractState,
            token_id: felt252,
            domain: felt252,
            days: felt252,
            resolver: felt252,
            address: starknet::ContractAddress,
        ) {
            // pay_buy_domain
            let caller = starknet::get_caller_address();
            let erc20 = self._erc20_address.read();
            let contract = starknet::get_contract_address();
            // IERC20Dispatcher {
            //     contract_address: erc20
            // }.transfer_from(caller, contract, u256 { low: 500, high: 0 });

            // write_domain_data
            let expiry = starknet::get_block_timestamp().into() + 86400 * days;
            self
                ._domain_data
                .write(
                    domain, DomainData { owner: token_id, address, expiry, key: 1, parent_key: 0 }
                );
        }

        fn domain_to_token_id(self: @ContractState, domain: Span<felt252>) -> felt252 {
            let mut res = 0;
            let mut domain = domain;

            let hashed_domain = self._hashed_domain(domain);
            let domain_data = self._domain_data.read(hashed_domain);
            let owner = domain_data.owner;

            if !owner.is_zero() {
                // subdomain is registered
                let hashed_parent_domain = self._hashed_domain(domain.slice(1, domain.len() - 1));
                let parent_domain_data = self._domain_data.read(hashed_parent_domain);
                if parent_domain_data.key == domain_data.parent_key {
                    return owner;
                } else {
                    return 0;
                }
            } else {
                // domain
                domain.pop_front().expect('pop_front failed');
                let hashed_domain = self._hashed_domain(domain);
                let domain_data = self._domain_data.read(hashed_domain);
                let owner = domain_data.owner;

                if !owner.is_zero() {
                    return owner;
                } else {
                    return 0;
                }
            }
        }

        fn set_domain_to_address(
            ref self: ContractState, domain: Span<felt252>, address: starknet::ContractAddress
        ) {
            let caller = starknet::get_caller_address();
            let hashed_domain = self._hashed_domain(domain);
            let domain_data = self._domain_data.read(hashed_domain);
            let new_data: DomainData = DomainData {
                owner: domain_data.owner,
                address,
                expiry: domain_data.expiry,
                key: domain_data.key,
                parent_key: domain_data.parent_key,
            };
            self._domain_data.write(hashed_domain, new_data);
        }

        fn transfer_domain(
            ref self: ContractState, domain: Span<felt252>, target_token_id: felt252, 
        ) {
            let caller = starknet::get_caller_address();
            let hashed_domain = self._hashed_domain(domain);
            let current_domain_data = self._domain_data.read(hashed_domain);
            let contract = self.starknetid_contract.read();
            // only for subdomains

            let hashed_parent_domain = self._hashed_domain(domain.slice(1, domain.len() - 1));
            let next_domain_data = self._domain_data.read(hashed_parent_domain);
            let new_domain_data = DomainData {
                owner: target_token_id,
                address: current_domain_data.address,
                expiry: current_domain_data.expiry,
                key: current_domain_data.key,
                parent_key: next_domain_data.key,
            };
            self._domain_data.write(hashed_domain, new_domain_data);
        }
    }

    //
    // Internals
    //

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _hashed_domain(self: @ContractState, domain: Span::<felt252>) -> felt252 {
            let mut domain = domain;
            let mut hashed_domain = hash::LegacyHash::hash(
                *domain.pop_front().expect('pop_front failed'), 0
            );
            loop {
                if domain.len() == 0 {
                    break;
                }
                let x = domain.pop_front().expect('pop_front failed');
                hashed_domain = hash::LegacyHash::hash(*x, hashed_domain);
            };
            hashed_domain
        }

        fn new_expiry(
            self: @ContractState, current_expiry: felt252, current_timestamp: felt252, days: felt252
        ) -> felt252 {
            if u256_from_felt252(current_expiry) < u256_from_felt252(current_timestamp) {
                return current_timestamp + 86400 * days;
            } else {
                return current_expiry + 86400 * days;
            }
        }
    }
}

