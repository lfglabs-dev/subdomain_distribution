#[starknet::interface]
trait IIdentity<TContractState> {
    fn transferFrom(
        ref self: TContractState,
        _from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        token_id: u128,
    );
}

