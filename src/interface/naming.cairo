#[starknet::interface]
trait INaming<TContractState> {
    fn domain_to_address(self: @TContractState, domain: Span<felt252>) -> starknet::ContractAddress;

    fn domain_to_token_id(self: @TContractState, domain: Span<felt252>) -> felt252;

    fn set_domain_to_address(
        ref self: TContractState, domain: Span<felt252>, address: starknet::ContractAddress
    );

    fn transfer_domain(ref self: TContractState, domain: Span<felt252>, target_token_id: felt252, );
}
