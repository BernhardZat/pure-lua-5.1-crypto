-- -------------------------------------------------------------------------------
-- Security Notice
--
-- This example demonstrates how to use the cryptographic primitives provided by
-- this library. For simplicity, it uses a passphrase-derived private key for
-- Alice and deterministic randomness for Bob. Production systems must generate
-- private keys from high-entropy randomness or use a proper password-based
-- key-derivation function when deriving keys from passphrases.
--
-- The session and MAC keys derived via HKDF from the X25519 shared secret are
-- representative of real-world usage.
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
local session_info = "ChaCha20 session key";
local session_key = hkdf.derive(shared_secret, hkdf_salt, session_info, 32);

-- 5. Encrypt a message using ChaCha20

-- 12-byte nonce for ChaCha20, must not be reused with the same key
local nonce = hkdf.derive(shared_secret, hkdf_salt, "nonce", 12);
local cipher = ChaCha20.new(session_key, nonce);

local plaintext = "Hello Bob, this is Alice!";
local ciphertext = cipher:apply_keystream(plaintext);

-- 6. Derive a MAC key using HKDF with a different context string and compute a MAC of the ciphertext

local mac_info = "BLAKE2s MAC key";
local mac_key = hkdf.derive(shared_secret, hkdf_salt, mac_info, 32);
local mac = blake2s.digest(ciphertext, mac_key);

-- 7. Construct the transmitted message and send it to Bob

local transmitted = nonce .. mac .. ciphertext;

-- 8. Bob receives the message, extracts the nonce, MAC, and ciphertext

local received_nonce = transmitted:sub(1, 12);   -- First 12 bytes are the nonce
local received_mac = transmitted:sub(13, 44);    -- Next 32 bytes are the MAC (BLAKE2s produces a 32-byte hash)
local received_ciphertext = transmitted:sub(45); -- The rest is the ciphertext

-- 9. Bob verifies the MAC

local expected_mac = blake2s.digest(received_ciphertext, mac_key);
assert(received_mac == expected_mac, "MAC verification failed!");

-- 10. Bob decrypts the message

local bob_cipher = ChaCha20.new(session_key, received_nonce);
local decrypted = bob_cipher:apply_keystream(received_ciphertext);

-- Print results in Base64 for readability

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

print("\n=== MAC Key (BLAKE2s) ===");
print(base64.encode(mac_key));

print("\n=== Encryption ===");
print("Nonce      : " .. base64.encode(nonce));
print("Ciphertext : " .. base64.encode(ciphertext));
print("MAC        : " .. base64.encode(mac));
print("Decrypted  : " .. decrypted);
