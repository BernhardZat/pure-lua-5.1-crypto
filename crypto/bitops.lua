-- Copyright (c) 2023 BernhardZat  -- see LICENSE file

local M = Matrix.new;

local u8_and_table = M(256);
for i = 0, 7 do
	local m1 = u8_and_table:get_sub(0, 0, 2 ^ i, 2 ^ i);
	local m2 = M(2 ^ i, 2 ^ i, 2 ^ i);
	u8_and_table:set_sub(m1, 2 ^ i, 0);
	u8_and_table:set_sub(m1, 0, 2 ^ i);
	u8_and_table:set_sub(m1 + m2, 2 ^ i, 2 ^ i);
end

local u8_lsh = function(a, n)
	return a * 2 ^ n % 0x100;
end

local u8_rsh = function(a, n)
	return a / 2 ^ n - (a / 2 ^ n) % 1;
end

local u8_lrot = function(a, n)
	n = n % 8;
	return u8_lsh(a, n) + u8_rsh(a, 8 - n);
end

local u8_rrot = function(a, n)
	n = n % 8;
	return u8_rsh(a, n) + u8_lsh(a, 8 - n);
end

local u8_not = function(a)
	return 0xFF - a;
end

local u8_and = function(a, b)
	return u8_and_table:get(a, b);
end

local u8_xor = function(a, b)
	return u8_not(u8_and(a, b)) - u8_and(u8_not(a), u8_not(b));
end

local u8_or = function(a, b)
	return u8_and(a, b) + u8_xor(a, b);
end

local u16_lsh = function(a, n)
	return a * 2 ^ n % 0x10000;
end

local u16_rsh = function(a, n)
	return a / 2 ^ n - (a / 2 ^ n) % 1;
end

local u16_lrot = function(a, n)
	n = n % 16;
	return u16_lsh(a, n) + u16_rsh(a, 16 - n);
end

local u16_rrot = function(a, n)
	n = n % 16;
	return u16_rsh(a, n) + u16_lsh(a, 16 - n);
end

local u16_not = function(a)
	return 0xFFFF - a;
end

local u16_and = function(a, b)
	local a1, a2 = u16_rsh(a, 8), a % 0x100;
	local b1, b2 = u16_rsh(b, 8), b % 0x100;
	local r1, r2 = u8_and(a1, b1), u8_and(a2, b2);
	return u16_lsh(r1, 8) + r2;
end

local u16_xor = function(a, b)
	local a1, a2 = u16_rsh(a, 8), a % 0x100;
	local b1, b2 = u16_rsh(b, 8), b % 0x100;
	local r1, r2 = u8_xor(a1, b1), u8_xor(a2, b2);
	return u16_lsh(r1, 8) + r2;
end

local u16_or = function(a, b)
	local a1, a2 = u16_rsh(a, 8), a % 0x100;
	local b1, b2 = u16_rsh(b, 8), b % 0x100;
	local r1, r2 = u8_or(a1, b1), u8_or(a2, b2);
	return u16_lsh(r1, 8) + r2;
end

local u32_lsh = function(a, n)
	return a * 2 ^ n % 0x100000000;
end

local u32_rsh = function(a, n)
	return a / 2 ^ n - (a / 2 ^ n) % 1;
end

local u32_lrot = function(a, n)
	n = n % 32;
	return u32_lsh(a, n) + u32_rsh(a, 32 - n);
end

local u32_rrot = function(a, n)
	n = n % 32;
	return u32_rsh(a, n) + u32_lsh(a, 32 - n);
end

local u32_not = function(a)
	return 0xFFFFFFFF - a;
end

local u32_and = function(a, b)
	local a1, a2 = u32_rsh(a, 16), a % 0x10000;
	local b1, b2 = u32_rsh(b, 16), b % 0x10000;
	local r1, r2 = u16_and(a1, b1), u16_and(a2, b2);
	return u32_lsh(r1, 16) + r2;
end

local u32_xor = function(a, b)
	local a1, a2 = u32_rsh(a, 16), a % 0x10000;
	local b1, b2 = u32_rsh(b, 16), b % 0x10000;
	local r1, r2 = u16_xor(a1, b1), u16_xor(a2, b2);
	return u32_lsh(r1, 16) + r2;
end

local u32_or = function(a, b)
	local a1, a2 = u32_rsh(a, 16), a % 0x10000;
	local b1, b2 = u32_rsh(b, 16), b % 0x10000;
	local r1, r2 = u16_or(a1, b1), u16_or(a2, b2);
	return u32_lsh(r1, 16) + r2;
end

_G.Bitops = {
	u8_lsh = u8_lsh,
	u8_rsh = u8_rsh,
	u8_lrot = u8_lrot,
	u8_rrot = u8_rrot,
	u8_not = u8_not,
	u8_and = u8_and,
	u8_xor = u8_xor,
	u8_or = u8_or,
	u16_lsh = u16_lsh,
	u16_rsh = u16_rsh,
	u16_lrot = u16_lrot,
	u16_rrot = u16_rrot,
	u16_not = u16_not,
	u16_and = u16_and,
	u16_xor = u16_xor,
	u16_or = u16_or,
	u32_lsh = u32_lsh,
	u32_rsh = u32_rsh,
	u32_lrot = u32_lrot,
	u32_rrot = u32_rrot,
	u32_not = u32_not,
	u32_and = u32_and,
	u32_xor = u32_xor,
	u32_or = u32_or,
};
