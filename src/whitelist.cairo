%lang starknet
from starkware.cairo.common.math import assert_nn
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

@storage_var
func _admin_address() -> (address: felt) {
}

@storage_var
func _whitelisting_key() -> (whitelisting_key: felt) {
}

@storage_var
func _blacklisted_mint(address: felt, token_id: felt) -> (boolean: felt) {
}

// Proxy 

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin_address: felt, starknetid_contract: felt, naming_contract: felt
) {
    Proxy.initializer(proxy_admin_address);
    _admin_address.write(proxy_admin_address);
    _naming_contract.write(naming_contract);
    _starknetid_contract.write(starknetid_contract);

    // Whitelisting public key
    _whitelisting_key.write(799085134889162279411547463466380106946633091380230638211634583888488020853);

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
func deposit_domain{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    domain_len: felt, domain: felt*
) {
    alloc_locals;

    // Check that the caller is the admin
    let (caller) = get_caller_address();
    let (admin) = _admin_address.read();
    assert caller = admin;

    // Get contracts addresses
    let (current_contract) = get_contract_address();
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

    // Check that the caller is the admin
    let (caller) = get_caller_address();
    let (admin) = _admin_address.read();
    assert caller = admin;

    // Get contracts addresses
    let (current_contract) = get_contract_address();
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
    domain_len: felt, domain: felt*, root_domain_len: felt, root_domain: felt*, receiver_token_id: felt, sig: (felt, felt)
) {
    alloc_locals;

    // Get the token id of the domain
    let (naming_contract_addr) = _naming_contract.read();
    let (domain_token_id) = Naming.domain_to_token_id(naming_contract_addr, root_domain_len, root_domain);

    // Verifiy that the caller address has not minted yet for this token_id
    let (caller) = get_caller_address();
    let (is_blacklisted) = _blacklisted_mint.read(caller, domain_token_id);
    with_attr error_message("This address has already minted") {
        assert is_blacklisted = FALSE;
    }

    // Verify that the caller address is whitelisted for this token_id
    let (whitelisting_key) = _whitelisting_key.read();
    let (params_hash) = hash2{hash_ptr=pedersen_ptr}(domain_token_id, caller); // The whitelist verify the caller and the token_id. If you claim back the domain and change the token id associated with it, the whitelist is resseted and all the blacklisted addresses can mint again.
    verify_ecdsa_signature(params_hash, whitelisting_key, sig[0], sig[1]);

    // Transfer the subdomain from the root domain owner (the contract) to the new identity
    with_attr error_message("You have to transfer a subdomain of the root domain") {
        assert root_domain_len = domain_len + 1;
    }
    Naming.transfer_domain(naming_contract_addr, domain_len, domain, receiver_token_id);
    
    // blacklist the address for this tokenId
    _blacklisted_mint.write(caller, domain_token_id, TRUE);

    return ();
}


