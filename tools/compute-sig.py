from starkware.crypto.signature.signature import  private_to_stark_key, get_random_private_key, sign

# compute signature
priv_key = get_random_private_key()
print("priv_key:", hex(priv_key))

pub_key = private_to_stark_key(priv_key)
print("pub_key:", hex(pub_key))

(x, y) = sign(123, priv_key)
print("sig:", hex(x), hex(y))