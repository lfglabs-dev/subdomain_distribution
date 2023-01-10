#!/usr/bin/env python3
import sys
from starkware.crypto.signature.signature import  sign
from starkware.crypto.signature.fast_pedersen_hash import pedersen_hash

# params
argv = sys.argv
if len(argv) < 3:
    print("[ERROR] Invalid amount of parameters")
    print("Usage: .tools/whitelist.py priv_key")
    sys.exit()
priv_key = argv[1]
address = argv[2]
token_id = argv[3]



# compute signature
hashed = pedersen_hash(
    int(token_id),
    int (address, 16),
)
signed = sign(hashed, int(priv_key)) 
print(signed)
    