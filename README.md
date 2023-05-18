# Pure Lua 5.1 cryptographic primitives 
Small crypto library written in pure Lua 5.1 which includes X25519, ChaCha20, Shamir's Secret Sharing and more.

This library includes modules for:

- X25519 elliptic curve Diffie-Hellman
- ChaCha20 stream cipher
- Shamir's Secret Sharing Scheme
- Base64 encoding
- GF256 finite field arithmetic
- Bitwise operations
- Matrix operations

# Objective
Some applications only support older versions of Lua and do not allow C bindings. Most existing Lua crypto libraries are either not pure Lua, or are for newer versions of Lua.
See also: https://lua-users.org/wiki/CryptographyStuff

Lua 5.1 doesn't have integer types and no bitwise operations. This makes it difficult to implement cryptographic primitives.
This library circumvents these limitations by emulating bitwise operations arithmetically. Obviously this results in poorer performance, compared to newer versions of Lua.

# In the future
This library is still missing a hash function. I plan adding BLAKE3 as a hash function in the future.
