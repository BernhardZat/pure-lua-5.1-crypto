-- Miscellaneous helper functions

local function u32_to_le_bytes(n)
    return string.char(
        n % 256,
        math.floor(n / 256) % 256,
        math.floor(n / 65536) % 256,
        math.floor(n / 16777216) % 256
    );
end

local function u32_from_le_bytes(s)
    local b1, b2, b3, b4 = s:byte(1, 4);
    return b1 + b2 * 0x100 + b3 * 0x10000 + b4 * 0x1000000;
end

local function hex_from_bytestring(s)
    return (s:gsub(".", function(c)
        return string.format("%02x", c:byte());
    end));
end

local function hex_to_bytestring(hex)
    return (hex:gsub("%x%x", function(cc)
        return string.char(tonumber(cc, 16));
    end));
end

local function assert_equal(label, input, expect)
    if input ~= expect then
        error(string.format("Test failed: %s\nExpected: %s\nGot:      %s", label, expect, input));
    else
        print("OK:", label);
    end
end

local function assert_not_equal(label, a, b)
    if a == b then
        error(string.format("Test failed: %s\nExpected not equal: %s", label, a));
    else
        print("OK:", label);
    end
end

local function assert_error(label, fn)
    local ok = pcall(fn);
    if ok then
        error(string.format("Test failed: %s\nExpected error.", label));
    else
        print("OK:", label);
    end
end

local misc = {
    u32_to_le_bytes = u32_to_le_bytes,
    u32_from_le_bytes = u32_from_le_bytes,
    hex_from_bytestring = hex_from_bytestring,
    hex_to_bytestring = hex_to_bytestring,
    assert_equal = assert_equal,
    assert_not_equal = assert_not_equal,
    assert_error = assert_error,
};

return misc;
