%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from src.whitelist import _get_amount_of_chars
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import split_felt

@external
func test_get_amount_of_chars{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // Should return 0 (empty string)
    let chars_amount = _get_amount_of_chars(Uint256(0, 0));
    assert chars_amount = 0;

    // Should return 4 ("toto")
    let chars_amount = _get_amount_of_chars(Uint256(796195, 0));
    assert chars_amount = 4;

    // Should return 5 ("aloha")
    let chars_amount = _get_amount_of_chars(Uint256(77554770, 0));
    assert chars_amount = 5;

    // Should return 9 ("chocolate")
    let chars_amount = _get_amount_of_chars(Uint256(19565965532212, 0));
    assert chars_amount = 9;

    // Should return 30 ("这来abcdefghijklmopqrstuvwyq1234")
    let (high, low) = split_felt(801855144733576077820330221438165587969903898313);
    let chars_amount = _get_amount_of_chars(Uint256(low, high));
    assert chars_amount = 30;

    return ();
}
