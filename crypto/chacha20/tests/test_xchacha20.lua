local XChaCha20 = require("crypto.chacha20.xchacha20")
local misc = require("util.misc");
local assert_equal = misc.assert_equal;
local hex = misc.hex_from_bytestring;
local unhex = misc.hex_to_bytestring;

-- XChaCha20 keystream test vector from libsodium
local libsodium_key         = "9d23bd4149cb979ccf3c5c94dd217e9808cb0e50cd0f67812235eaaf601d6232";
local libsodium_nonce       = "c047548266b7c370d33566a2425cbf30d82d1eaf5294109e";
local libsodium_expected_64 = "a21209096594de8c5667b1d13ad93f744106d054df210e4782cd396fec692d3515a20bf351eec011a92c367888bc464c32f0807acd6c203a247e0db854148468";

-- Test the libsodium vector
local function test_xchacha20_vector()
    local x = XChaCha20.new(unhex(libsodium_key), unhex(libsodium_nonce));
    local out = x:apply_keystream(string.rep("\0", 64));
    assert_equal("XChaCha20 libsodium test vector", hex(out), libsodium_expected_64);
end

-- Test roundtrip
local function test_roundtrip()
    local key = string.rep("\1", 32);
    local nonce = string.rep("\2", 24);
    local x1 = XChaCha20.new(key, nonce, 0);
    local x2 = XChaCha20.new(key, nonce, 0);
    local plaintext = "Hello XChaCha20!";
    local ciphertext = x1:apply_keystream(plaintext);
    local decrypted  = x2:apply_keystream(ciphertext);
    assert_equal("XChaCha20 roundtrip", decrypted, plaintext);
end

-- Test seek
local function test_seek()
    local key   = string.rep("\5", 32);
    local nonce = string.rep("\6", 24);
    local x1 = XChaCha20.new(key, nonce);
    local x2 = XChaCha20.new(key, nonce);
    local data = string.rep("A", 200);
    local full = x1:apply_keystream(data);
    x2:seek(150);
    local partial = x2:apply_keystream(data:sub(151));
    assert_equal("XChaCha20 seek", full:sub(151), partial);
end

local function run_all()
    test_xchacha20_vector();
    test_roundtrip();
    test_seek();
end

run_all()
