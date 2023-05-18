--------------------------------------------------------------------------------------------------------------------------
--  Copyright (c) 2023, BernhardZat -- see LICENSE file                                                                 --
--                                                                                                                      --
--  X25519 elliptic-curve Diffie-Hellman key agreement implemented in pure Lua 5.1.                                     --
--  Based on the original TweetNaCl library written in C. See https://tweetnacl.cr.yp.to/                               --
--                                                                                                                      --
--  Lua 5.1 doesn't have a 64 bit signed integer type and no bitwise operations.                                        --
--  This implementation emulates bitwise operations arithmetically on 64 bit double precision floating point numbers.   --
--  Note that double precision floating point numbers are only exact in the integer range of [-2^53, 2^53].             --
--  This works for our purposes because values will not be outside the range of about [-2^43, 2^44].                    --
--------------------------------------------------------------------------------------------------------------------------

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

local swap = function(a, b, bit)
    for i = 0, 15 do
        a[i], b[i] =
            a[i] * ((bit - 1) % 2) + b[i] * bit,
            b[i] * ((bit - 1) % 2) + a[i] * bit;
    end
end

local unpack = function(out, a)
    for i = 0, 15 do
        out[i] = a[2 * i] + a[2 * i + 1] * 0x100;
    end
    out[15] = out[15] % 0x8000;
end

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

local add = function(out, a, b)
    for i = 0, 15 do
        out[i] = a[i] + b[i];
    end
end

local sub = function(out, a, b)
    for i = 0, 15 do
        out[i] = a[i] - b[i];
    end
end

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

local scalarmult = function(out, scalar, point)
    local a, b, c, d, e, f, x, clam = {}, {}, {}, {}, {}, {}, {}, {};
    unpack(x, point);
    for i = 0, 15 do
        a[i], b[i], c[i], d[i] = 0, x[i], 0, 0;
    end
    a[0], d[0] = 1, 1;
    for i = 0, 30 do
        clam[i] = scalar[i];
    end
    clam[0] = clam[0] - (clam[0] % 8);
    clam[31] = scalar[31] % 64 + 64;
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
    inv(c, c);
    mul(a, a, c);
    pack(out, a);
end

local generate_keypair = function(rng)
    rng = rng or function() return math.random(0, 0xFF) end;
    local sk, pk = {}, {};
    for i = 0, 31 do
        sk[i] = rng();
    end
    local base = { [0] = 9 };
    for i = 1, 31 do
        base[i] = 0;
    end
    scalarmult(pk, sk, base);
    return sk, pk;
end

local get_shared_key = function(sk, pk)
    local shared = {};
    scalarmult(shared, sk, pk);
    return shared;
end

_G.X25519 = {
    generate_keypair = generate_keypair,
    get_shared_key = get_shared_key,
}
