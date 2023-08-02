#!/usr/bin/env python3
import sys
from starkware.crypto.signature.signature import  sign
from starkware.crypto.signature.fast_pedersen_hash import pedersen_hash
from starknet_py.hash.utils import private_to_stark_key

# params
argv = sys.argv
if len(argv) < 3:
    print("[ERROR] Invalid amount of parameters")
    print("Usage: .tools/whitelist.py priv_key")
    sys.exit()
priv_key = argv[1]
address = argv[2]



# compute signature
pub_key = private_to_stark_key(int(priv_key))
print(pub_key)
hash = pedersen_hash(int(address), 0)
print(hash)
# signed = sign(hash, int(priv_key))
signed = sign(int(address), int(priv_key)) 
print(signed)
    