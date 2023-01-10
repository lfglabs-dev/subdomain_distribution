%lang starknet
from starkware.cairo.common.math import assert_nn, assert_le
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from cairo_contracts.src.openzeppelin.upgrades.library import Proxy
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from src.interface.naming import Naming
from src.interface.starknetid import StarknetId
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.hash import hash2

// Storage 
@storage_var
func _naming_contract() -> (address: felt) {
}

@storage_var
func _starknetid_contract() -> (address: felt) {
}

// Proxy 

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin_address: felt, starknetid_contract: felt, naming_contract: felt
) {
    Proxy.initializer(proxy_admin_address);
    _naming_contract.write(naming_contract);
    _starknetid_contract.write(starknetid_contract);

    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);

    return ();
}

// External functions
@external
func approve_identities{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*}(
) {
    alloc_locals;

    // Get contracts addresses
    let (current_contract) = get_contract_address();
    let (starknetid_contract_addr) = _starknetid_contract.read();

    StarknetId.setApprovalForAll(starknetid_contract_addr, current_contract, 1);

    return ();
}

@external
func deposit_domain{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    domain_len: felt, domain: felt*
) {
    alloc_locals;

    // Get contracts addresses
    let (current_contract) = get_contract_address();
    let (caller) = get_caller_address();
    let (starknetid_contract_addr) = _starknetid_contract.read();
    let (naming_contract_addr) = _naming_contract.read();

    // Transfer the starknet identity of the domain on this contract
    let (domain_token_id) = Naming.domain_to_token_id(naming_contract_addr, domain_len, domain);
    let token_id_uint = Uint256(domain_token_id, 0);
    StarknetId.transferFrom(starknetid_contract_addr, caller, current_contract, token_id_uint);
    
    return ();
}

@external
func claim_domain_back{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    domain_len: felt, domain: felt*
) {
    alloc_locals;

    // Get contracts addresses
    let (current_contract) = get_contract_address();
    let (caller) = get_caller_address();
    let (starknetid_contract_addr) = _starknetid_contract.read();
    let (naming_contract_addr) = _naming_contract.read();

    // Transfer back the starknet identity of the domain to the caller address
    let (token_id) = Naming.domain_to_token_id(naming_contract_addr, domain_len, domain);
    let token_id_uint = Uint256(token_id, 0);
    StarknetId.transferFrom(starknetid_contract_addr, current_contract, caller, token_id_uint);
    
    return ();
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*}(
    domain_len: felt, domain: felt*, receiver_token_id: felt
) {
    alloc_locals;

    with_attr error_message("You can't transfer the root domain.") {
        if (domain_len == 1) {
            assert 0 = 1;
        }
    }

    // Get contract addresse
    let (naming_contract_addr) = _naming_contract.read();

    // Transfer the subdomain from the root domain owner (the contract) to the new identity
    Naming.transfer_domain(naming_contract_addr, domain_len, domain, receiver_token_id);

    return ();
}