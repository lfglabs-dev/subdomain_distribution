#[starknet::contract]
mod Whitelist {
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_contract_address};
    use starknet::class_hash::ClassHash;
    use array::SpanTrait;
    use clone::Clone;
    use zeroable::Zeroable;
    use traits::Into;
    use option::OptionTrait;
    use integer::{u256_from_felt252, u256_as_non_zero, u256_safe_divmod, u128_from_felt252};
    use ecdsa::check_ecdsa_signature;

    use subdomain_distribution::interface::whitelist::IWhitelist;

    use subdomain_distribution::interface::identity::{
        IIdentityDispatcher, IIdentityDispatcherTrait
    };
    use naming::interface::naming::{INamingDispatcher, INamingDispatcherTrait};

    #[storage]
    struct Storage {
        _naming_contract: ContractAddress,
        _starknetid_contract: ContractAddress,
        _admin_address: ContractAddress,
        _whitelisting_key: felt252,
        _blacklisted_addresses: LegacyMap<ContractAddress, bool>,
        _is_registration_open: bool,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        proxy_admin_address: ContractAddress,
        starknetid_contract: ContractAddress,
        naming_contract: ContractAddress,
        whitelist_key: felt252
    ) {
        self._initializer(proxy_admin_address, starknetid_contract, naming_contract, whitelist_key);
    }

    #[external(v0)]
    impl WhitelistImpl of IWhitelist<ContractState> {
        fn set_contracts(
            ref self: ContractState,
            starknetid_contract: starknet::ContractAddress,
            naming_contract: starknet::ContractAddress
        ) {
            self._check_admin();
            self._naming_contract.write(naming_contract);
            self._starknetid_contract.write(starknetid_contract);
        }

        fn claim_domain_back(ref self: ContractState, domain: Span<felt252>,) {
            // Check that the caller is the admin
            self._check_admin();

            // Get contracts addresses
            let caller = get_caller_address();
            let (current_contract, starknetid_contract, naming_contract) = self
                ._get_contracts_addresses();

            // Transfer back the starknet identity of the domain to the caller address
            let token_id = INamingDispatcher { contract_address: naming_contract }
                .domain_to_id(domain);

            IIdentityDispatcher { contract_address: starknetid_contract }
                .transferFrom(current_contract, caller, token_id);
        }

        fn register(
            ref self: ContractState,
            domain: Span<felt252>,
            receiver_token_id: u128,
            sig: (felt252, felt252)
        ) {
            // Check if the registration is open
            assert(self._is_registration_open.read(), 'Registration is closed');

            // Check if name is more than 4 letters
            let mut cloned_domain = domain.clone();
            let name = cloned_domain.pop_front().expect('Domain is empty');
            let number_of_character: felt252 = self._get_amount_of_chars(u256_from_felt252(*name));
            assert(
                u128_from_felt252(number_of_character) >= 4_u128, 'Name is less than 4 characters'
            );

            // Check if the domain to send is a subdomain of the root domain
            assert(domain.len() == 2, 'Cannot transfer root domain');

            // Verifiy that the caller address has not minted yet
            let caller = get_caller_address();
            assert(!self._blacklisted_addresses.read(caller), 'Caller already minted');

            // Verify that the caller address is whitelisted
            let whitelisting_key = self._whitelisting_key.read();
            let (sig_0, sig_1) = sig;
            let is_valid = check_ecdsa_signature(caller.into(), whitelisting_key, sig_0, sig_1);
            assert(is_valid, 'Not whitelisted');

            // Check if the name already has an address, as this contract will be the owner of the root domain it can transfer all the subdomain even if it does not own it
            let naming_contract = self._naming_contract.read();
            let address = INamingDispatcher { contract_address: naming_contract }
                .domain_to_address(domain);
            assert(address.is_zero(), 'This name is taken');

            INamingDispatcher { contract_address: naming_contract }
                .transfer_domain(domain, receiver_token_id);

            // blacklist the address for this address
            self._blacklisted_addresses.write(caller, true);
        }

        //
        // Admin functions
        //

        fn open_registration(ref self: ContractState) {
            self._check_admin();
            self._is_registration_open.write(true);
        }

        fn close_registration(ref self: ContractState) {
            self._check_admin();
            self._is_registration_open.write(false);
        }

        fn change_admin(ref self: ContractState, address: ContractAddress) {
            self._check_admin();
            self._admin_address.write(address);
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self._check_admin();
            // todo: use components
            assert(!impl_hash.is_zero(), 'Class hash cannot be zero');
            starknet::replace_class_syscall(impl_hash).unwrap();
        }

        //
        // View functions
        //

        fn is_registration_open(self: @ContractState) -> bool {
            self._is_registration_open.read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _initializer(
            ref self: ContractState,
            proxy_admin_address: ContractAddress,
            starknetid_contract: ContractAddress,
            naming_contract: ContractAddress,
            whitelist_key: felt252
        ) {
            self._admin_address.write(proxy_admin_address);
            self._naming_contract.write(naming_contract);
            self._starknetid_contract.write(starknetid_contract);
            self._whitelisting_key.write(whitelist_key);
        }

        fn _check_admin(self: @ContractState) {
            assert(get_caller_address() == self._admin_address.read(), 'Caller not admin');
        }

        fn _get_contracts_addresses(
            self: @ContractState
        ) -> (ContractAddress, ContractAddress, ContractAddress) {
            (get_contract_address(), self._starknetid_contract.read(), self._naming_contract.read())
        }

        fn _get_amount_of_chars(self: @ContractState, domain: u256) -> felt252 {
            if domain == (u256 { low: 0, high: 0 }) {
                return 0;
            }
            // 38 = simple_alphabet_size
            let (p, q, _) = u256_safe_divmod(domain, u256_as_non_zero(u256 { low: 38, high: 0 }));
            if q == (u256 { low: 37, high: 0 }) {
                // 3 = complex_alphabet_size
                let (shifted_p, _, _) = u256_safe_divmod(
                    p, u256_as_non_zero(u256 { low: 2, high: 0 })
                );
                let next = self._get_amount_of_chars(shifted_p);
                return 1 + next;
            }
            let next = self._get_amount_of_chars(p);
            1 + next
        }
    }
}
