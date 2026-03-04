--------------------------------------------------------------------------------------------------
--  BLAKE2s cryptographic hash function implemented in pure Lua 5.1.
--
--  Based on the algorithm specification of RFC 7693 and the C reference implementation.
--
--  Copyright (c) 2026 BernhardZat
--  Licensed under the MIT License. See the LICENSE file for details.
--------------------------------------------------------------------------------------------------

-- Use bitops library
local bitops = require("util.bitops.bitops");
local u32_xor = bitops.u32_xor;
local u32_and = bitops.u32_and;
local u32_lsh = bitops.u32_lsh;
local u32_rsh = bitops.u32_rsh;
local u32_rrot = bitops.u32_rrot;
local u32_add = bitops.u32_add;

-- Initialization vector
local iv = {
    [0] =
    0x6A09E667,
    0xBB67AE85,
    0x3C6EF372,
    0xA54FF53A,
    0x510E527F,
    0x9B05688C,
    0x1F83D9AB,
    0x5BE0CD19,
};

-- Message permutation schedule
local sigma = {
    [0] = { [0] = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
    [1] = { [0] = 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 },
    [2] = { [0] = 11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4 },
    [3] = { [0] = 7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8 },
    [4] = { [0] = 9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13 },
    [5] = { [0] = 2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9 },
    [6] = { [0] = 12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11 },
    [7] = { [0] = 13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10 },
    [8] = { [0] = 6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5 },
    [9] = { [0] = 10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0 },
};

-- Load a 32‑bit little‑endian word from byte array b at word index i
local function get32(b, i)
    local j = 4 * i;
    local b0 = b[j] or 0;
    local b1 = b[j + 1] or 0;
    local b2 = b[j + 2] or 0;
    local b3 = b[j + 3] or 0;

    local x = b0;
    x = u32_add(x, u32_lsh(b1, 8));
    x = u32_add(x, u32_lsh(b2, 16));
    x = u32_add(x, u32_lsh(b3, 24));
    return x;
end

-- Mixing function
local function mix(v, a, b, c, d, x, y)
    v[a] = u32_add(v[a], u32_add(v[b], x));
    v[d] = u32_rrot(u32_xor(v[d], v[a]), 16);
    v[c] = u32_add(v[c], v[d]);
    v[b] = u32_rrot(u32_xor(v[b], v[c]), 12);
    v[a] = u32_add(v[a], u32_add(v[b], y));
    v[d] = u32_rrot(u32_xor(v[d], v[a]), 8);
    v[c] = u32_add(v[c], v[d]);
    v[b] = u32_rrot(u32_xor(v[b], v[c]), 7);
end

-- Compression function
local compress = function(self, last)
    local v = {};
    local m = {};

    -- Initialize work vector v with chaining value and IV
    for i = 0, 7 do
        v[i] = self.chain[i];
        v[i + 8] = iv[i];
    end

    -- XOR low/high 64‑bit counter into v[12]/v[13]
    v[12] = u32_xor(v[12], self.total[0]);
    v[13] = u32_xor(v[13], self.total[1]);

    -- If this is the final block, invert v[14]
    if last then
        v[14] = u32_xor(v[14], 0xFFFFFFFF);
    end

    -- Load message block into m[0..15]
    for i = 0, 15 do
        m[i] = get32(self.buffer, i);
    end

    -- 10 rounds of mixing
    for r = 0, 9 do
        local s = sigma[r];

        -- Column step
        mix(v, 0, 4, 8, 12, m[s[0]], m[s[1]]);
        mix(v, 1, 5, 9, 13, m[s[2]], m[s[3]]);
        mix(v, 2, 6, 10, 14, m[s[4]], m[s[5]]);
        mix(v, 3, 7, 11, 15, m[s[6]], m[s[7]]);
        
        -- Diagonal step
        mix(v, 0, 5, 10, 15, m[s[8]], m[s[9]]);
        mix(v, 1, 6, 11, 12, m[s[10]], m[s[11]]);
        mix(v, 2, 7, 8, 13, m[s[12]], m[s[13]]);
        mix(v, 3, 4, 9, 14, m[s[14]], m[s[15]]);
    end

    -- Update chaining value
    for i = 0, 7 do
        self.chain[i] = u32_xor(self.chain[i], u32_xor(v[i], v[i + 8]));
    end
end

local blake2s = {};
blake2s.__index = blake2s;

-- Initialize a new BLAKE2s state
blake2s.init = function(key, outlen)
    outlen = outlen and outlen or 32;
    local keylen = key and #key or 0;

    local self = setmetatable({}, blake2s);

    self.chain = {};                -- internal chaining value
    self.total = { [0] = 0, 0 };    -- number of total bytes processed
    self.count = 0;                 -- number of bytes in buffer
    self.outlen = outlen;           -- digest size
    self.buffer = {};               -- 64-byte message buffer

    -- Initialize chaining value with IV
    for i = 0, 7 do
        self.chain[i] = iv[i];
    end

    -- Parameter block
    local param = u32_xor(0x01010000, u32_lsh(keylen, 8));
    param = u32_xor(param, outlen);
    self.chain[0] = u32_xor(self.chain[0], param);

    -- Zero buffer
    for i = 0, 63 do
        self.buffer[i] = 0;
    end

    -- If keyed hashing, process first block with key padded to 64 bytes
    if keylen > 0 then
        local block = key .. ("\0"):rep(64 - keylen);
        blake2s.update(self, block);
    end

    return self;
end

-- Absorb input bytes into the state
function blake2s.update(self, input)
    local inlen = #input;
    local pos = 1;

    while inlen > 0 do
        -- If buffer full, compress it
        if self.count == 64 then
            self.total[0] = u32_add(self.total[0], self.count);
            if self.total[0] < self.count then
                self.total[1] = u32_add(self.total[1], 1);
            end
            compress(self, false);
            self.count = 0;
        end

        -- Add next byte to buffer
        self.buffer[self.count] = string.byte(input, pos);
        self.count = self.count + 1;
        pos = pos + 1;
        inlen = inlen - 1;
    end
end

-- Finalize hash and return digest
function blake2s.finalize(self)

    -- Update total counter with remaining bytes
    self.total[0] = u32_add(self.total[0], self.count);
    if self.total[0] < self.count then
        self.total[1] = u32_add(self.total[1], 1);
    end

    -- Pad remaining buffer with zeros
    while self.count < 64 do
        self.buffer[self.count] = 0;
        self.count = self.count + 1;
    end

    -- Final compression with last block flag
    compress(self, true);

    -- Produce output bytes from chaining value
    local out = {};
    for i = 0, self.outlen - 1 do
        local word = self.chain[u32_rsh(i, 2)];
        local shift = 8 * (i % 4);
        local byte = u32_and(u32_rsh(word, shift), 0xFF);
        out[#out + 1] = string.char(byte);
    end

    return table.concat(out);
end

-- Convenience function: hash a string in one call
function blake2s.digest(input, key, outlen)
    outlen = outlen and outlen or 32;
    local hasher = blake2s.init(key, outlen);
    hasher:update(input);
    return hasher:finalize();
end

return blake2s;
