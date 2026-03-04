local ChaCha20 = require("crypto.chacha20.chacha20");
local misc = require("util.misc");
local assert_equal = misc.assert_equal;
local hex = misc.hex_from_bytestring;
local unhex = misc.hex_to_bytestring;

-- RFC 8439 test vector
local rfc_key         = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
local rfc_nonce       = "000000090000004a00000000";
local rfc_expected_64 = "10f1e7e4d13b5915500fdd1fa32071c4c7d1f4c733c068030422aa9ac3d46c4ed2826446079faa0914c2d705d98b02a2b5129cd1de164eb9cbd083e8a2503c4e";

-- Test the RFC vector
local function test_rfc_vector()
    local key = unhex(rfc_key);
    local nonce = unhex(rfc_nonce);
    local c = ChaCha20.new(key, nonce, 1);
    local out = c:apply_keystream(string.rep("\0", 64));
    assert_equal("ChaCha20 RFC8439 test vector", hex(out), rfc_expected_64);
end

-- Test roundtrip
local function test_roundtrip()
    local key = string.rep("\1", 32);
    local nonce = string.rep("\2", 12);
    local c1 = ChaCha20.new(key, nonce, 0);
    local c2 = ChaCha20.new(key, nonce, 0);
    local plaintext = "Hello ChaCha20!";
    local ciphertext = c1:apply_keystream(plaintext);
    local decrypted  = c2:apply_keystream(ciphertext);
    assert_equal("ChaCha20 roundtrip", decrypted, plaintext);
end

-- Test seek
local function test_seek()
    local key = string.rep("\3", 32);
    local nonce = string.rep("\4", 12);
    local c1 = ChaCha20.new(key, nonce, 0);
    local c2 = ChaCha20.new(key, nonce, 0);
    local data = string.rep("A", 200);
    local full = c1:apply_keystream(data);
    c2:seek(150);
    local partial = c2:apply_keystream(data:sub(151));
    assert_equal("ChaCha20 seek", full:sub(151), partial);
end

local function run_all()
    test_rfc_vector();
    test_roundtrip();
    test_seek();
end

run_all();
