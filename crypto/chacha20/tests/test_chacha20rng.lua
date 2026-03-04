local ChaCha20Rng = require("crypto.chacha20.chacha20rng")
local ChaCha20    = require("crypto.chacha20.chacha20")
local misc = require("util.misc");
local assert_equal = misc.assert_equal;
local assert_not_equal = misc.assert_not_equal;

-- Test if the same seed produces the same output
local function test_determinism()
    local seed = string.rep("\1", 32);
    local r1 = ChaCha20Rng.new(seed);
    local r2 = ChaCha20Rng.new(seed);
    local a = r1:next_bytes(64);
    local b = r2:next_bytes(64);
    assert_equal("ChaCha20Rng deterministic output", a, b);
end

-- Test if different seeds produce different output
local function test_independence()
    local r1 = ChaCha20Rng.new(string.rep("\1", 32));
    local r2 = ChaCha20Rng.new(string.rep("\2", 32));
    local a = r1:next_bytes(32);
    local b = r2:next_bytes(32);
    assert_not_equal("ChaCha20Rng different seeds", a, b);
end

-- Test if the RNG matches the ChaCha20 keystream
local function test_matches_chacha20()
    local seed = string.rep("\3", 32);
    local nonce = string.rep("\0", 12);
    local rng = ChaCha20Rng.new(seed);
    local c   = ChaCha20.new(seed, nonce);
    local rng_out = rng:next_bytes(128);
    local ch_out  = c:apply_keystream(string.rep("\0", 128));
    assert_equal("ChaCha20 RNG matches keystream", rng_out, ch_out);
end

local function run_all()
    test_determinism();
    test_independence();
    test_matches_chacha20();
end

run_all();
