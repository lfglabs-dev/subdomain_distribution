#[starknet::interface]
trait INaming<TContractState> {
    fn domain_to_address(
        self: @TContractState, domain: Span<felt252>,
    ) -> starknet::ContractAddress;

    fn transfer_domain(self: @TContractState, domain: Span<felt252>, receiver_token_id: u128);

    fn domain_to_id(self: @TContractState, domain: Span<felt252>) -> u128;
}

