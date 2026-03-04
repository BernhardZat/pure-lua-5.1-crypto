local blake2s = require("crypto.blake2s.blake2s");
local misc = require("util.misc");
local assert_equal = misc.assert_equal;
local hex = misc.hex_from_bytestring;
local unhex = misc.hex_to_bytestring;

local function test(input, expected, key, message)
    key = key and unhex(key) or nil;
    input = input and unhex(input) or "";
    message = message and message or "a " .. input:len() .. "-byte message";
    local output = hex(blake2s.digest(input, key, 32));
    assert_equal(message, output, expected);
end

-- BLAKE2s test vectors from RFC 7693
local rfc_empty = "69217a3079908094e11121d042354a7c1f55b6482ca1a51e1b250dfd1ed0eef9";
local rfc_abc =   "508c5e8c327c14e2e1a72ba34eeb452f37458b209ed63a294d999b4c86675982";

-- Test the RFC vectors
local test_rfc = function ()
    test("", rfc_empty, nil, "empty string");
    test(hex("abc"), rfc_abc, nil, "abc");
end

-- Test with multiple updates
local test_hasher_update = function ()
    local hasher = blake2s.init();
    hasher:update("a");
    hasher:update("b");
    hasher:update("c");
    local output = hex(hasher:finalize());
    local expected = rfc_abc;
    assert_equal("hasher update", output, expected);
end

-- Test keyed vectors from the BLAKE2 reference source code package on GitHub
local test_reference_code = function ()
    local f, err = io.open("crypto/blake2s/blake2s-kat.txt", "r");
    if not f then
        error("Could not open test vector file: " .. tostring(err));
    end
    local input, key, hash;
    for line in f:lines() do
        local tag, value = line:match("^(%w+):%s*(%x*)$");
        if tag == "in" then
            input = value;
        elseif tag == "key" then
            key = value;
        elseif tag == "hash" then
            hash = value;
            test(input, hash, key);
        end
    end
    f:close();
end

local run_all = function ()
    test_rfc();
    test_hasher_update();
    test_reference_code();
end

run_all();