#[starknet::interface]
trait IStarknetId<TContractState> {
    fn owner_of(self: @TContractState, token_id: felt252) -> starknet::ContractAddress;

    fn mint(ref self: TContractState, token_id: felt252);

    fn set_verifier_data(
        ref self: TContractState, starknet_id: felt252, field: felt252, data: felt252
    ) -> bool;

    fn transferFrom(
        ref self: TContractState,
        _from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        token_id: u256,
    );
}

#[starknet::interface]
trait MockStarknetIdABI<TContractState> {
    fn owner_of(self: @TContractState, token_id: felt252) -> starknet::ContractAddress;

    fn mint(ref self: TContractState, token_id: felt252);

    fn set_verifier_data(
        ref self: TContractState, starknet_id: felt252, field: felt252, data: felt252
    ) -> bool;
}

#[starknet::contract]
mod StarknetId {
    use super::IStarknetId;
    use zeroable::Zeroable;
    use traits::Into;

    //
    // Storage
    //

    #[storage]
    struct Storage {
        starknet_id_data: LegacyMap::<(felt252, felt252, starknet::ContractAddress), felt252>,
        _owners: LegacyMap<felt252, starknet::ContractAddress>,
    }

    //
    // Interface impl
    //

    #[external(v0)]
    impl IStarknetIdImpl of IStarknetId<ContractState> {
        fn owner_of(self: @ContractState, token_id: felt252) -> starknet::ContractAddress {
            self._owners.read(token_id)
        }

        fn mint(ref self: ContractState, token_id: felt252) {
            let to = starknet::get_caller_address();
            self._mint(to, token_id);
        }

        fn set_verifier_data(
            ref self: ContractState, starknet_id: felt252, field: felt252, data: felt252
        ) -> bool {
            true
        }

        fn transferFrom(
            ref self: ContractState,
            _from: starknet::ContractAddress,
            to: starknet::ContractAddress,
            token_id: u256,
        ) {
            assert(!to.is_zero(), 'ERC721: invalid receiver');
            let owner = self._owners.read(token_id.low.into());

            self._owners.write(token_id.low.into(), to);
        }
    }

    //
    // Internals
    //

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _mint(ref self: ContractState, to: starknet::ContractAddress, token_id: felt252) {
            assert(!to.is_zero(), 'ERC721: mint to 0');

            self._owners.write(token_id, to);
        }
    }
}
