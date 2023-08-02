#[starknet::contract]
mod SimpleSubdomainDistribution {
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_contract_address};
    use array::{ArrayTrait};
    use zeroable::Zeroable;
    use starknet::class_hash::ClassHash;

    use subdomain_distribution::interface::simple::ISimpleSubdomainDistribution;
    use subdomain_distribution::upgrades::upgradeable::Upgradeable;
    use subdomain_distribution::interface::naming::{
        INaming, INamingDispatcher, INamingDispatcherTrait
    };
    use subdomain_distribution::interface::starknetid::{
        IStarknetId, IStarknetIdDispatcher, IStarknetIdDispatcherTrait
    };

    #[storage]
    struct Storage {
        _naming_contract: ContractAddress,
        _starknetid_contract: ContractAddress,
        _admin_address: ContractAddress,
        _blacklisted_addresses: LegacyMap<ContractAddress, bool>,
        _is_registration_open: bool,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        proxy_admin_address: ContractAddress,
        starknetid_contract: ContractAddress,
        naming_contract: ContractAddress
    ) {
        self._initializer(proxy_admin_address, starknetid_contract, naming_contract);
    }

    #[external(v0)]
    impl SimpleImpl of ISimpleSubdomainDistribution<ContractState> {
        fn claim_domain_back(ref self: ContractState, domain: Array<felt252>, ) {
            // Check that the caller is the admin
            self._check_admin();

            // Get contracts addresses
            let caller = get_caller_address();
            let (current_contract, starknetid_contract, naming_contract) = self
                ._get_contracts_addresses();

            // Transfer back the starknet identity of the domain to the caller address
            let token_id = INamingDispatcher {
                contract_address: naming_contract
            }.domain_to_token_id(domain.span());
            let token_id_uint = u256 { low: integer::u128_from_felt252(token_id), high: 0 };

            IStarknetIdDispatcher {
                contract_address: starknetid_contract
            }.transferFrom(current_contract, caller, token_id_uint);
        }

        fn register(ref self: ContractState, domain: Array<felt252>, receiver_token_id: felt252) {
            // Check if the registration is open
            assert(self._is_registration_open.read(), 'Registration is closed');

            // Check if the domain to send is a subdomain of the root domain
            assert(self._calculate_length(@domain) == 2, 'Cannot transfer root domain');

            // Verifiy that the caller address has not minted yet
            let caller = get_caller_address();
            assert(!self._blacklisted_addresses.read(caller), 'Caller already minted');

            // Check if the name already has an address, as this contract will be the owner of the root domain it can transfer all the subdomain even if it does not own it
            let naming_contract = self._naming_contract.read();
            let address = INamingDispatcher {
                contract_address: naming_contract
            }.domain_to_address(domain.span());
            assert(address.is_zero(), 'This name is taken');

            INamingDispatcher {
                contract_address: naming_contract
            }.set_domain_to_address(domain.span(), caller);
            INamingDispatcher {
                contract_address: naming_contract
            }.transfer_domain(domain.span(), receiver_token_id);

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
            let mut unsafe_state = Upgradeable::unsafe_new_contract_state();
            Upgradeable::InternalImpl::_upgrade(ref unsafe_state, impl_hash);
        }

        fn upgrade_and_call(
            ref self: ContractState,
            impl_hash: ClassHash,
            selector: felt252,
            calldata: Array<felt252>
        ) {
            self._check_admin();
            let mut unsafe_state = Upgradeable::unsafe_new_contract_state();
            Upgradeable::InternalImpl::_upgrade_and_call(
                ref unsafe_state, impl_hash, selector, calldata.span()
            );
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
        ) {
            self._admin_address.write(proxy_admin_address);
            self._naming_contract.write(naming_contract);
            self._starknetid_contract.write(starknetid_contract);
        }
        fn _check_admin(self: @ContractState) {
            assert(get_caller_address() == self._admin_address.read(), 'Caller not admin');
        }

        fn _get_contracts_addresses(
            self: @ContractState
        ) -> (ContractAddress, ContractAddress, ContractAddress) {
            (get_contract_address(), self._starknetid_contract.read(), self._naming_contract.read())
        }

        fn _calculate_length(self: @ContractState, arr: @Array<felt252>) -> usize {
            arr.len()
        }
    }
}
