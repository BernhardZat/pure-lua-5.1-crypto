--------------------------------------------------------------------------------------------------------------------------------
--  X25519 elliptic‑curve Diffie–Hellman key agreement implemented in pure Lua 5.1.
--
--  Based on TweetNaCl (public domain) by Daniel J. Bernstein, Tanja Lange, and Peter Schwabe.
--  This is an independent reimplementation and translation into Lua, using 16‑bit limbs and
--  arithmetic operations compatible with Lua 5.1's double‑precision number model.
--
--  Copyright (c) 2023 Bernhard Zatloukal
--  Licensed under the MIT License. See the LICENSE file for details.
--
--  Notes:
--    - Lua 5.1 has no native 64‑bit integers or bitwise operators. All field arithmetic is
--      emulated using exact integer operations within the IEEE‑754 53‑bit range.
--    - This implementation is mathematically correct and verified against RFC 7748 test vectors.
--    - As Lua is an interpreted language, constant‑time execution cannot be guaranteed.
--      Do not rely on this code for side‑channel‑resistant cryptography.
--------------------------------------------------------------------------------------------------------------------------------


-- Reduce a field element by propagating carries across 16 limbs.
-- This keeps each limb in the range [0, 2^16).
local carry = function(out)
    for i = 0, 15 do
        out[i] = out[i] + 0x10000;
        local c = out[i] / 0x10000 - (out[i] / 0x10000) % 1;
        if i < 15 then
            out[i + 1] = out[i + 1] + c - 1;
        else
            out[0] = out[0] + 38 * (c - 1);
        end
        out[i] = out[i] - c * 0x10000;
    end
end

-- Conditional swap of two field elements.
-- 'bit' must be 0 or 1. Implemented branch‑free to match TweetNaCl structure.
local swap = function(a, b, bit)
    for i = 0, 15 do
        a[i], b[i] =
            a[i] * ((bit - 1) % 2) + b[i] * bit,
            b[i] * ((bit - 1) % 2) + a[i] * bit;
    end
end

-- Convert a 32‑byte little‑endian array into a 16‑limb field element.
local unpack = function(out, a)
    for i = 0, 15 do
        out[i] = a[2 * i] + a[2 * i + 1] * 0x100;
    end
    out[15] = out[15] % 0x8000;
end

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
    local prime = { [0] = 0xffed, [15] = 0x7fff };
    for i = 1, 14 do
        prime[i] = 0xffff;
    end
    for _ = 0, 1 do
        m[0] = t[0] - prime[0];
        for i = 1, 15 do
            m[i] = t[i] - prime[i] - ((m[i - 1] / 0x10000 - (m[i - 1] / 0x10000) % 1) % 2);
            m[i - 1] = (m[i - 1] + 0x10000) % 0x10000;
        end
        local c = (m[15] / 0x10000 - (m[15] / 0x10000) % 1) % 2;
        swap(t, m, 1 - c);
    end
    for i = 0, 15 do
        out[2 * i] = t[i] % 0x100;
        out[2 * i + 1] = t[i] / 0x100 - (t[i] / 0x100) % 1;
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
-- Uses schoolbook multiplication followed by reduction.
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
    clam[0] = clam[0] - (clam[0] % 8);
    clam[31] = scalar[31] % 64 + 64;

    -- Montgomery ladder loop
    for i = 254, 0, -1 do
        local bit = (clam[i / 8 - (i / 8) % 1] / 2 ^ (i % 8) - (clam[i / 8 - (i / 8) % 1] / 2 ^ (i % 8)) % 1) % 2;
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
        mul(a, c, { [0] = 0xdb41, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 });
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

-- Base point (9, in little‑endian form)
local base = {
    [0] =
    9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

-- Compute public key = secret_key * base_point
local get_public_key = function (secret_key)
    local public_key = {};
    scalarmult(public_key, secret_key, base);
    return public_key;
end

-- Compute shared key = secret_key * peer_public_key
local get_shared_key = function (secret_key, peer_public_key)
    local shared_key = {};
    scalarmult(shared_key, secret_key, peer_public_key);
    return shared_key;
end

-- Test vectors from RFC 7748 (X25519 section).
-- These are known-good values used to verify correctness of the implementation.
local alice_secret_key = {
    [0] =
    0x77, 0x07, 0x6d, 0x0a, 0x73, 0x18, 0xa5, 0x7d, 0x3c, 0x16, 0xc1, 0x72, 0x51, 0xb2, 0x66, 0x45,
    0xdf, 0x4c, 0x2f, 0x87, 0xeb, 0xc0, 0x99, 0x2a, 0xb1, 0x77, 0xfb, 0xa5, 0x1d, 0xb9, 0x2c, 0x2a
};

local alice_public_key = {
    [0] =
    0x85, 0x20, 0xf0, 0x09, 0x89, 0x30, 0xa7, 0x54, 0x74, 0x8b, 0x7d, 0xdc, 0xb4, 0x3e, 0xf7, 0x5a,
    0x0d, 0xbf, 0x3a, 0x0d, 0x26, 0x38, 0x1a, 0xf4, 0xeb, 0xa4, 0xa9, 0x8e, 0xaa, 0x9b, 0x4e, 0x6a
};

local bob_secret_key = {
    [0] =
    0x5d, 0xab, 0x08, 0x7e, 0x62, 0x4a, 0x8a, 0x4b, 0x79, 0xe1, 0x7f, 0x8b, 0x83, 0x80, 0x0e, 0xe6,
    0x6f, 0x3b, 0xb1, 0x29, 0x26, 0x18, 0xb6, 0xfd, 0x1c, 0x2f, 0x8b, 0x27, 0xff, 0x88, 0xe0, 0xeb
};

local bob_public_key = {
    [0] =
    0xde, 0x9e, 0xdb, 0x7d, 0x7b, 0x7d, 0xc1, 0xb4, 0xd3, 0x5b, 0x61, 0xc2, 0xec, 0xe4, 0x35, 0x37,
    0x3f, 0x83, 0x43, 0xc8, 0x5b, 0x78, 0x67, 0x4d, 0xad, 0xfc, 0x7e, 0x14, 0x6f, 0x88, 0x2b, 0x4f
};

local alice_bob_shared_key = {
    [0] =
    0x4a, 0x5d, 0x9d, 0x5b, 0xa4, 0xce, 0x2d, 0xe1, 0x72, 0x8e, 0x3b, 0xf4, 0x80, 0x35, 0x0f, 0x25,
    0xe0, 0x7e, 0x21, 0xc9, 0x47, 0xd1, 0x9e, 0x33, 0x76, 0xf0, 0x9b, 0x3c, 0x1e, 0x16, 0x17, 0x42
};

-- Compare two 32‑byte arrays for equality.
-- Used by tests to validate keys against the RFC vectors.
local equality_check = function(a, b)
    for i = 0, 31 do
        if a[i] ~= b[i] then
            return false;
        end
    end
    return true;
end

-- Test that get_public_key reproduces the RFC public keys for Alice and Bob.
local test_get_public_key = function()
    local public_key;

    public_key = get_public_key(alice_secret_key);
    assert(equality_check(public_key, alice_public_key));

    public_key = get_public_key(bob_secret_key);
    assert(equality_check(public_key, bob_public_key));
end

-- Test that both parties derive the same shared key, matching the RFC shared secret.
local test_get_shared_key = function()
    local shared_key;

    shared_key = get_shared_key(alice_secret_key, bob_public_key);
    assert(equality_check(shared_key, alice_bob_shared_key));

    shared_key = get_shared_key(bob_secret_key, alice_public_key);
    assert(equality_check(shared_key, alice_bob_shared_key));
end

-- Export public API
_G.X25519 = {
    get_public_key = get_public_key,
    get_shared_key = get_shared_key,
}
