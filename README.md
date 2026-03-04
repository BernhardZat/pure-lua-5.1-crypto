# Pure Lua 5.1 Cryptographic Primitives

A lightweight cryptography library implemented entirely in **pure Lua 5.1**, providing modern primitives such as **X25519**, **ChaCha20**, **XChaCha20**, and **BLAKE2s** without requiring any C extensions.

This library is intended for environments where only Lua 5.1 is available - such as embedded systems, sandboxed runtimes, or legacy applications.

## Included Modules

### Cryptographic primitives
- **X25519** - Elliptic‑curve Diffie–Hellman key agreement  
- **ChaCha20** - Stream cipher  
- **XChaCha20** - Extended‑nonce stream cipher  
- **ChaCha20‑based PRNG** - Pseudorandom number generator  
- **BLAKE2s** - Cryptographic hash function (including keyed mode)
- **HKDF** - HMAC-based Extract-and-Expand Key Derivation Function using BLAKE2s

### Utility modules
- **Base64** - encoding and decoding  
- **Bitwise operations** - implemented arithmetically and using lookup tables 
- **Miscellaneous helper functions**

### Tests
- Modules include test coverage, including official **RFC test vectors** where applicable.

### Examples
- An `example.lua` script is included to demonstrate how the modules can be used together in a simple end‑to‑end flow.

An earlier version of this library also included Galois‑field arithmetic, matrix operations, and Shamir’s Secret Sharing. These may return in future releases once they match the consistency of the current codebase.

## Objective

Some Lua environments still rely on **Lua 5.1** and do not allow loading native C modules. Existing Lua cryptography libraries often depend on C bindings or target newer Lua versions.

Lua 5.1 lacks integer types and built‑in bitwise operators, which makes implementing modern cryptographic primitives challenging. This library works around these limitations by emulating bitwise operations using arithmetic. While this approach is slower than native implementations, it enables modern cryptography in pure Lua.

Because Lua is an interpreted language, **constant‑time execution cannot be guaranteed**.

## Future Plans

Additional modules are planned, including:

- Message authentication (e.g. Poly1305)  
- Password hashing (e.g. Argon2id)  
- Digital signatures (e.g. Ed25519)

## License

Copyright (c) 2022–2026 BernhardZat  
Licensed under the MIT License. See the LICENSE file for details.
