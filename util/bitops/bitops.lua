local u8_and_table = require("util.bitops.lookup_tables.u8_and");
local u8_or_table = require("util.bitops.lookup_tables.u8_xor");
local u8_xor_table = require("util.bitops.lookup_tables.u8_xor");
local floor = math.floor;

-- Precompute powers of two for efficiency
local pow_2 = {};
pow_2[0] = 1;
for i = 1, 32 do
	pow_2[i] = pow_2[i - 1] * 2;
end

-- Extract bytes from u16
local u16_b0 = function(a) return a % 0x100; end
local u16_b1 = function(a) return floor(a / 0x100) % 0x100; end

-- Extract bytes from u32
local u32_b0 = function(a) return a % 256; end
local u32_b1 = function(a) return floor(a / 0x100) % 0x100; end
local u32_b2 = function(a) return floor(a / 0x10000) % 0x100; end
local u32_b3 = function(a) return floor(a / 0x1000000) % 0x100; end

-- Combine two u8 to make an u16
local make_u16 = function(b0, b1)
	return b0 + b1 * 0x100;
end

-- Combine four u8 to make an u32
local make_u32 = function(b0, b1, b2, b3)
	return b0 + b1 * 0x100 + b2 * 0x10000 + b3 * 0x1000000;
end

-- u8 operations

local u8_and = function(a, b)
	return u8_and_table[a][b];
end

local u8_or = function(a, b)
	return u8_or_table[a][b];
end

local u8_xor = function(a, b)
	return u8_xor_table[a][b];
end

local u8_not = function(a)
	return 0xFF - a;
end

local u8_lsh = function(a, n)
	return a * pow_2[n] % 0x100;
end

local u8_rsh = function(a, n)
	return floor(a / pow_2[n])
end

local u8_lrot = function(a, n)
	n = n % 8;
	return u8_lsh(a, n) + u8_rsh(a, 8 - n);
end

local u8_rrot = function(a, n)
	n = n % 8;
	return u8_rsh(a, n) + u8_lsh(a, 8 - n);
end

local u8_add = function (a, b)
	return (a + b) % 0x100;
end

-- u16 operations

local u16_and = function(a, b)
	return make_u16(
		u8_and(u16_b0(a), u16_b0(b)),
		u8_and(u16_b1(a), u16_b1(b))
	);
end

local u16_or = function(a, b)
	return make_u16(
		u8_or(u16_b0(a), u16_b0(b)),
		u8_or(u16_b1(a), u16_b1(b))
	);
end

local u16_xor = function(a, b)
	return make_u16(
		u8_xor(u16_b0(a), u16_b0(b)),
		u8_xor(u16_b1(a), u16_b1(b))
	);
end

local u16_not = function(a)
	return make_u16(
		u8_not(u16_b0(a)),
		u8_not(u16_b1(a))
	);
end

local u16_lsh = function(a, n)
	return (a * pow_2[n]) % 0x10000;
end

local u16_rsh = function(a, n)
	return floor(a / pow_2[n]);
end

local u16_lrot = function(a, n)
	n = n % 16;
	return ((a * pow_2[n]) % 0x10000) + floor(a / pow_2[16 - n]);
end

local u16_rrot = function(a, n)
	n = n % 16;
	return floor(a / pow_2[n]) + ((a * pow_2[16 - n]) % 0x10000);
end

local u16_add = function (a, b)
	return (a + b) % 0x10000;
end

-- u32 operations

local u32_and = function(a, b)
    return make_u32(
        u8_and(u32_b0(a), u32_b0(b)),
        u8_and(u32_b1(a), u32_b1(b)),
        u8_and(u32_b2(a), u32_b2(b)),
        u8_and(u32_b3(a), u32_b3(b))
    );
end

local u32_or = function(a, b)
    return make_u32(
        u8_or(u32_b0(a), u32_b0(b)),
        u8_or(u32_b1(a), u32_b1(b)),
        u8_or(u32_b2(a), u32_b2(b)),
        u8_or(u32_b3(a), u32_b3(b))
    );
end

local u32_xor = function(a, b)
    return make_u32(
        u8_xor(u32_b0(a), u32_b0(b)),
        u8_xor(u32_b1(a), u32_b1(b)),
        u8_xor(u32_b2(a), u32_b2(b)),
        u8_xor(u32_b3(a), u32_b3(b))
    );
end

local u32_not = function(a)
    return make_u32(
        u8_not(u32_b0(a)),
        u8_not(u32_b1(a)),
        u8_not(u32_b2(a)),
        u8_not(u32_b3(a))
    );
end

local u32_lsh = function(a, n)
    return (a * pow_2[n]) % 0x100000000;
end

local u32_rsh = function(a, n)
    return floor(a / pow_2[n]);
end

local u32_lrot = function(a, n)
    n = n % 32;
    return ((a * pow_2[n]) % 0x100000000) + floor(a / pow_2[32 - n]);
end

local u32_rrot = function(a, n)
    n = n % 32;
    return floor(a / pow_2[n]) + ((a * pow_2[32 - n]) % 0x100000000);
end

local u32_add = function (a, b)
	return (a + b) % 0x100000000;
end

-- Export public API
local bitops = {
	u8_and = u8_and,
    u8_or = u8_or,
	u8_xor = u8_xor,
	u8_not = u8_not,
    u8_lsh = u8_lsh,
	u8_rsh = u8_rsh,
	u8_lrot = u8_lrot,
	u8_rrot = u8_rrot,
	u8_add = u8_add,
	
    u16_and = u16_and,
	u16_xor = u16_xor,
	u16_or = u16_or,
    u16_not = u16_not,
	u16_lsh = u16_lsh,
	u16_rsh = u16_rsh,
	u16_lrot = u16_lrot,
	u16_rrot = u16_rrot,
	u16_add = u16_add,
	
    u32_and = u32_and,
	u32_xor = u32_xor,
	u32_or = u32_or,
    u32_not = u32_not,
	u32_lsh = u32_lsh,
	u32_rsh = u32_rsh,
	u32_lrot = u32_lrot,
	u32_rrot = u32_rrot,
	u32_add = u32_add,
};

return bitops;