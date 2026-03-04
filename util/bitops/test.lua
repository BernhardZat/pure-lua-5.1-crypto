local bitops = require("util.bitops.bitops");
local misc = require("util.misc");
local assert_equal = misc.assert_equal;

-- Test u8 bitops
local function test_u8_bitops()
    assert_equal("u8_and", bitops.u8_and(255, 0), 0);
    assert_equal("u8_or", bitops.u8_or(240, 15), 255);
    assert_equal("u8_xor", bitops.u8_xor(170, 85), 255);
    assert_equal("u8_not", bitops.u8_not(0), 255);
    assert_equal("u8_not", bitops.u8_not(255), 0);
    assert_equal("u8_lsh", bitops.u8_lsh(1, 7), 128);
    assert_equal("u8_lsh", bitops.u8_lsh(1, 8), 0);
    assert_equal("u8_rsh", bitops.u8_rsh(255, 7), 1);
    assert_equal("u8_rsh", bitops.u8_rsh(255, 8), 0);
    assert_equal("u8_lrot", bitops.u8_lrot(1, 1), 2);
    assert_equal("u8_lrot", bitops.u8_lrot(240, 4), 15);
    assert_equal("u8_rrot", bitops.u8_rrot(2, 1), 1);
    assert_equal("u8_rrot", bitops.u8_rrot(240, 4), 15);
end

-- Test u16 bitops
local function test_u16_bitops()
    assert_equal("u16_and", bitops.u16_and(0xF0F0, 0x0F0F), 0);
    assert_equal("u16_or", bitops.u16_or(0xF0F0, 0x0F0F), 65535);
    assert_equal("u16_xor", bitops.u16_xor(0xAAAA, 0x5555), 65535);
    assert_equal("u16_not", bitops.u16_not(0), 65535);
    assert_equal("u16_not", bitops.u16_not(65535), 0);
    assert_equal("u16_lsh", bitops.u16_lsh(1, 15), 32768);
    assert_equal("u16_lsh", bitops.u16_lsh(1, 16), 0);
    assert_equal("u16_rsh", bitops.u16_rsh(65535, 15), 1);
    assert_equal("u16_rsh", bitops.u16_rsh(65535, 16), 0);
    assert_equal("u16_lrot", bitops.u16_lrot(1, 1), 2);
    assert_equal("u16_lrot", bitops.u16_lrot(0xF0F0, 8), 0xF0F0);
    assert_equal("u16_rrot", bitops.u16_rrot(2, 1), 1);
    assert_equal("u16_rrot", bitops.u16_rrot(0xF0F0, 8), 0xF0F0);
end

-- Test u32 bitops
local function test_u32_bitops()
    assert_equal("u32_and", bitops.u32_and(0xF0F0F0F0, 0x0F0F0F0F), 0);
    assert_equal("u32_or", bitops.u32_or(0xF0F0F0F0, 0x0F0F0F0F), 0xFFFFFFFF);
    assert_equal("u32_xor", bitops.u32_xor(0xAAAAAAAA, 0x55555555), 0xFFFFFFFF);
    assert_equal("u32_not", bitops.u32_not(0), 0xFFFFFFFF);
    assert_equal("u32_not", bitops.u32_not(0xFFFFFFFF), 0);
    assert_equal("u32_lsh", bitops.u32_lsh(1, 31), 0x80000000);
    assert_equal("u32_lsh", bitops.u32_lsh(1, 32), 0);
    assert_equal("u32_rsh", bitops.u32_rsh(0xFFFFFFFF, 31), 1);
    assert_equal("u32_rsh", bitops.u32_rsh(0xFFFFFFFF, 32), 0);
    assert_equal("u32_lrot", bitops.u32_lrot(1, 1), 2);
    assert_equal("u32_lrot", bitops.u32_lrot(0xF0F0F0F0, 16), 0xF0F0F0F0);
    assert_equal("u32_rrot", bitops.u32_rrot(2, 1), 1);
    assert_equal("u32_rrot", bitops.u32_rrot(0xF0F0F0F0, 16), 0xF0F0F0F0);
end

local function run_all()
    test_u8_bitops();
    test_u16_bitops();
    test_u32_bitops();
end

run_all();