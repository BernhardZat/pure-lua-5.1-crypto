-- -------------------------------------------------------------------------------
-- Security Notice
-- 
-- This example demonstrates how to use the cryptographic primitives provided by
-- this library. The example uses simplified passphrase handling, deterministic
-- randomness, and a minimal key-derivation step for illustration. Real systems
-- require proper entropy and key-derivation.
-- -------------------------------------------------------------------------------

local blake2s   = require("crypto.blake2s.blake2s");
local x25519    = require("crypto.x25519.x25519");
local ChaCha20  = require("crypto.chacha20.chacha20");
local Rng       = require("crypto.chacha20.chacha20rng");
local base64    = require("util.base64.base64");
local hkdf      = require("crypto.hkdf");

-- 1. Alice chooses a passphrase

local passphrase = "correct horse battery staple";

-- Hash the passphrase to obtain 32 bytes for use as a private key
local alice_private = blake2s.digest(passphrase);

-- Compute Alice's public key
local alice_public = x25519.get_public_key(alice_private);

-- 2. Bob generates a random private key using the PRNG

-- Create a PRNG seeded with 32 random bytes
local seed = string.rep("\01", 32);  -- placeholder seed
local rng = Rng.new(seed);

local bob_private = rng:next_bytes(32);
local bob_public  = x25519.get_public_key(bob_private);

-- 3. Both sides compute the shared secret

local alice_shared = x25519.get_shared_secret(alice_private, bob_public);
local bob_shared   = x25519.get_shared_secret(bob_private, alice_public);

assert(alice_shared == bob_shared, "Shared secrets do not match!");
local shared_secret = alice_shared;

-- 4. Derive a ChaCha20 key from the shared secret

local hkdf_salt = "pure-lua-5.1-crypto example";
local hkdf_info = "ChaCha20 session key";
local session_key = hkdf.derive(shared_secret, hkdf_salt, hkdf_info, 32);

-- 5. Encrypt a message using ChaCha20

local nonce = rng:next_bytes(12);  -- ChaCha20 requires 12-byte nonce
local cipher = ChaCha20.new(session_key, nonce);

local plaintext = "Hello Bob, this is Alice!";
local ciphertext = cipher:apply_keystream(plaintext);

-- 6. Decrypt the message (for demonstration)

local decipher = ChaCha20.new(session_key, nonce);
local decrypted = decipher:apply_keystream(ciphertext);

-- 7. Print results in Base64 for readability

print("=== Alice ===");
print("Private key: " .. base64.encode(alice_private));
print("Public key : " .. base64.encode(alice_public));

print("\n=== Bob ===");
print("Private key: " .. base64.encode(bob_private));
print("Public key : " .. base64.encode(bob_public));

print("\n=== Shared Secret ===");
print(base64.encode(shared_secret));

print("\n=== Session Key (ChaCha20) ===");
print(base64.encode(session_key));

print("\n=== Encryption ===");
print("Nonce      : " .. base64.encode(nonce));
print("Ciphertext : " .. base64.encode(ciphertext));
print("Decrypted  : " .. decrypted);
