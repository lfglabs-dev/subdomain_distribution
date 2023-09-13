#!/usr/bin/env python3
import sys
from starkware.crypto.signature.signature import  private_to_stark_key, get_random_private_key, sign
from starkware.crypto.signature.fast_pedersen_hash import pedersen_hash

# params
argv = sys.argv
if len(argv) < 3:
    print("[ERROR] Invalid amount of parameters")
    print("Usage: .tools/whitelist.py priv_key")
    sys.exit()
priv_key = argv[1]
address = argv[2]

# compute signature
signed = sign(int(address), int(priv_key)) 
print(signed)
    