local base64 = require("util.base64.base64");
local misc = require("util.misc");
local assert_equal = misc.assert_equal;
local assert_error = misc.assert_error;

-- RFC 4648 test vectors
local rfc_empty  = "";
local rfc_f      = "Zg==";
local rfc_fo     = "Zm8=";
local rfc_foo    = "Zm9v";
local rfc_foob   = "Zm9vYg==";
local rfc_fooba  = "Zm9vYmE=";
local rfc_foobar = "Zm9vYmFy";


-- Test RFC vectors
local function test_known_vectors()
    assert_equal("base64 empty", base64.encode(""), rfc_empty);
    assert_equal("base64 f", base64.encode("f"), rfc_f);
    assert_equal("base64 fo", base64.encode("fo"), rfc_fo);
    assert_equal("base64 foo", base64.encode("foo"), rfc_foo);
    assert_equal("base64 foob", base64.encode("foob"), rfc_foob);
    assert_equal("base64 fooba", base64.encode("fooba"), rfc_fooba);
    assert_equal("base64 foobar", base64.encode("foobar"), rfc_foobar);
end

-- Roundtrip tests
local function test_roundtrip()
    local samples = {
        "",
        "hello",
        "Lua 5.1",
        "äöüß€",
        string.char(0,1,2,3,4,250,251,252,253,254,255)
    };

    for i, s in ipairs(samples) do
        local enc = base64.encode(s);
        local dec = base64.decode(enc);
        assert_equal("base64 roundtrip" .. i, dec, s);
    end
end

-- Test padding
local function test_padding()
    assert_equal("base64 2 padding chars", base64.decode(rfc_f), "f")
    assert_equal("base64 1 padding char", base64.decode(rfc_fo), "fo")
    assert_equal("base64 no padding chars", base64.decode(rfc_foo), "foo")
end

-- Test invalid input
local function test_invalid_input()
    assert_error("base64 @@@", function() base64.decode("@@@") end);
    assert_error("base64 A!BC", function() base64.decode("A!BC") end);
end

local function run_all()
    test_known_vectors();
    test_roundtrip();
    test_padding();
    test_invalid_input();
end

run_all();
