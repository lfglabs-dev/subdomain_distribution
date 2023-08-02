#[starknet::interface]
trait IWhitelist<TContractState> {
    fn set_contracts(
        ref self: TContractState,
        starknetid_contract: starknet::ContractAddress,
        naming_contract: starknet::ContractAddress
    );
    fn claim_domain_back(ref self: TContractState, domain: Array<felt252>, );
    fn register(
        ref self: TContractState,
        domain: Array<felt252>,
        receiver_token_id: felt252,
        sig: (felt252, felt252)
    );
    fn open_registration(ref self: TContractState);
    fn close_registration(ref self: TContractState);
    fn change_admin(ref self: TContractState, address: starknet::ContractAddress);
    fn is_registration_open(self: @TContractState) -> bool;
    fn upgrade(ref self: TContractState, impl_hash: starknet::class_hash::ClassHash);
    fn upgrade_and_call(
        ref self: TContractState,
        impl_hash: starknet::class_hash::ClassHash,
        selector: felt252,
        calldata: Array<felt252>
    );
}
