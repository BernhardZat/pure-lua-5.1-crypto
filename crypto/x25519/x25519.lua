--------------------------------------------------------------------------------------------------
--  X25519 elliptic‑curve Diffie–Hellman key agreement implemented in pure Lua 5.1.
--
--  Based on TweetNaCl (public domain) by Daniel J. Bernstein, Tanja Lange, and Peter Schwabe.
--  This is a reimplementation and translation into Lua, using 16‑bit limbs and arithmetic
--  operations compatible with Lua 5.1's double‑precision number model.
--
--  Copyright (c) 2022-2026 BernhardZat
--  Licensed under the MIT License. See the LICENSE file for details.
--
--  Notes:
--    - Lua 5.1 has no native 64‑bit integers or bitwise operators. Field arithmetic is
--      emulated using exact integer operations within the IEEE‑754 53‑bit range.
--    - This implementation is verified against RFC 7748 test vectors.
--    - As Lua is an interpreted language, constant‑time execution cannot be guaranteed.
--------------------------------------------------------------------------------------------------

local floor = math.floor;

-- Reduce a field element by propagating carries across 16 limbs.
-- This keeps each limb in the range [0, 2^16).
local carry = function(out)
    for i = 0, 15 do
        out[i] = out[i] + 0x10000;
        local c = floor(out[i] / 0x10000);
        if i < 15 then
            out[i + 1] = out[i + 1] + c - 1;
        else
            out[0] = out[0] + 38 * (c - 1);
        end
        out[i] = out[i] % 0x10000;
    end
end

-- Conditional swap of two field elements. 'bit' must be 0 or 1.
local swap = function(a, b, bit)
    local inv = 1 - bit
    for i = 0, 15 do
        local ai, bi = a[i], b[i]
        a[i] = ai * inv + bi * bit
        b[i] = bi * inv + ai * bit
    end
end

-- Convert a 32‑byte array into a 16‑limb field element.
local unpack = function(out, a)
    for i = 0, 15 do
        out[i] = a[2 * i] + a[2 * i + 1] * 0x100;
    end
    out[15] = out[15] % 0x8000;
end

-- The prime number 2^255-19
local prime = {
    [0] =
    0xffed, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
    0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0x7fff,
};

-- Convert a 16‑limb field element back into a 32‑byte little‑endian array.
-- Includes full reduction modulo 2^255 − 19.
local pack = function(out, a)
    local t, m = {}, {};
    for i = 0, 15 do
        t[i] = a[i];
    end
    carry(t);
    carry(t);
    carry(t);
    for _ = 0, 1 do
        m[0] = t[0] - prime[0];
        for i = 1, 15 do
            m[i] = t[i] - prime[i] - (floor(m[i - 1] / 0x10000) % 2);
            m[i - 1] = m[i - 1] % 0x10000;
        end
        local c = floor(m[15] / 0x10000) % 2;
        swap(t, m, 1 - c);
    end
    for i = 0, 15 do
        out[2 * i] = t[i] % 0x100;
        out[2 * i + 1] = floor(t[i] / 0x100);
    end
end

-- Field addition: out = a + b
local add = function(out, a, b)
    for i = 0, 15 do
        out[i] = a[i] + b[i];
    end
end

-- Field subtraction: out = a − b
local sub = function(out, a, b)
    for i = 0, 15 do
        out[i] = a[i] - b[i];
    end
end

-- Field multiplication modulo 2^255 − 19.
local mul = function(out, a, b)
    local prod = {};
    for i = 0, 31 do
        prod[i] = 0;
    end
    for i = 0, 15 do
        for j = 0, 15 do
            prod[i + j] = prod[i + j] + a[i] * b[j];
        end
    end
    for i = 0, 14 do
        prod[i] = prod[i] + 38 * prod[i + 16];
    end
    for i = 0, 15 do
        out[i] = prod[i];
    end
    carry(out);
    carry(out);
end

-- Field inversion: out = a^(p−2) mod p using exponentiation by squaring.
local inv = function(out, a)
    local c = {};
    for i = 0, 15 do
        c[i] = a[i];
    end
    for i = 253, 0, -1 do
        mul(c, c, c);
        if i ~= 2 and i ~= 4 then
            mul(c, c, a);
        end
    end
    for i = 0, 15 do
        out[i] = c[i];
    end
end

-- Montgomery curve constant 486662
local curve_const = { [0] = 0xdb41, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

-- Core X25519 scalar multiplication using the Montgomery ladder.
-- Computes out = scalar * point.
local scalarmult = function(out, scalar, point)
    local a, b, c, d, e, f, x, clam = {}, {}, {}, {}, {}, {}, {}, {};
    unpack(x, point);

    -- Initialize ladder state
    for i = 0, 15 do a[i], b[i], c[i], d[i] = 0, x[i], 0, 0; end
    a[0], d[0] = 1, 1;

    -- Clamp scalar as per RFC 7748
    for i = 0, 30 do clam[i] = scalar[i]; end
    clam[0] = clam[0] - clam[0] % 8;
    clam[31] = scalar[31] % 64 + 64;

    -- Montgomery ladder loop
    for i = 254, 0, -1 do
        local bit = floor(clam[floor(i / 8)] / 2^(i % 8)) % 2;
        swap(a, b, bit);
        swap(c, d, bit);
        add(e, a, c);
        sub(a, a, c);
        add(c, b, d);
        sub(b, b, d);
        mul(d, e, e);
        mul(f, a, a);
        mul(a, c, a);
        mul(c, b, e);
        add(e, a, c);
        sub(a, a, c);
        mul(b, a, a);
        sub(c, d, f);
        mul(a, c, curve_const);
        add(a, a, d);
        mul(c, c, a);
        mul(a, d, f);
        mul(d, b, x);
        mul(b, e, e);
        swap(a, b, bit);
        swap(c, d, bit);
    end

    -- Convert projective coordinates back to affine
    inv(c, c);
    mul(a, a, c);
    pack(out, a);
end

-- Base point 9
local base = {
    [0] =
    9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

-- Converts a 32‑byte string to a table of bytes
local bytes_to_table = function (bytes)
    local t = {};
    for i = 0, 31 do
        t[i] = string.byte(bytes, i + 1);
    end
    return t;
end

-- Get a 32‑byte string from a table of bytes
local bytes_from_table = function (t)
    local out = {};
    for i = 0, 31 do
        out[i + 1] = string.char(t[i]);
    end
    return table.concat(out);
end


-- Compute public key = secret_key * base_point
local get_public_key = function (secret_key)
    assert(#secret_key == 32, "X25519 key must be 32 bytes");
    local public_key = {};
    scalarmult(public_key, bytes_to_table(secret_key), base);
    return bytes_from_table(public_key);
end

-- Compute shared key = secret_key * peer_public_key
local get_shared_key = function (secret_key, peer_public_key)
    assert(#secret_key == 32 and #peer_public_key == 32, "X25519 key must be 32 bytes");
    local shared_key = {};
    scalarmult(shared_key, bytes_to_table(secret_key), bytes_to_table(peer_public_key));
    return bytes_from_table(shared_key);
end

-- Export public API
local x25519 = {
    get_public_key = get_public_key,
    get_shared_key = get_shared_key,
}

return x25519;
