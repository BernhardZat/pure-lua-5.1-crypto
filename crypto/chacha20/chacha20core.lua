local bitops = require("util.bitops.bitops")
local u32_xor  = bitops.u32_xor
local u32_lrot = bitops.u32_lrot
local u32_add  = bitops.u32_add

local misc = require("util.misc");
local u32_to_le_bytes = misc.u32_to_le_bytes;
local u32_from_le_bytes = misc.u32_from_le_bytes;

-- Convert a byte string into an array of 32‑bit little‑endian integers.
local function unpack_u32_le(s)
    local out = {};
    for i = 1, #s, 4 do
        out[#out+1] = u32_from_le_bytes(s:sub(i, i+3));
    end
    return out;
end

-- Convert an array of 32‑bit integers into a litte-endian byte string.
local function pack_u32_le(a)
    local out = {};
    for i = 1, #a do
        out[i] = u32_to_le_bytes(a[i]);
    end
    return table.concat(out);
end

-- Perform one ChaCha20 quarter‑round on state indices (a, b, c, d).
local function quarter_round(s, a, b, c, d)
    s[a] = u32_add(s[a], s[b]);
    s[d] = u32_lrot(u32_xor(s[d], s[a]), 16);
    s[c] = u32_add(s[c], s[d]);
    s[b] = u32_lrot(u32_xor(s[b], s[c]), 12);
    s[a] = u32_add(s[a], s[b]);
    s[d] = u32_lrot(u32_xor(s[d], s[a]),  8);
    s[c] = u32_add(s[c], s[d]);
    s[b] = u32_lrot(u32_xor(s[b], s[c]),  7);
end

-- Perform 20 rounds = 10 column rounds + 10 diagonal rounds
local function chacha20_rounds(state)
    for _ = 1, 10 do
        -- Column round
        quarter_round(state, 1, 5,  9, 13);
        quarter_round(state, 2, 6, 10, 14);
        quarter_round(state, 3, 7, 11, 15);
        quarter_round(state, 4, 8, 12, 16);
        -- Diagonal round
        quarter_round(state, 1, 6, 11, 16);
        quarter_round(state, 2, 7, 12, 13);
        quarter_round(state, 3, 8,  9, 14);
        quarter_round(state, 4, 5, 10, 15);
    end
end

-- Produce one 64‑byte ChaCha20 block.
local function chacha20_block(key, nonce, counter)
    -- Initial ChaCha20 state
    local state = {
        0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,
        key[1],     key[2],     key[3],     key[4],
        key[5],     key[6],     key[7],     key[8],
        counter,    nonce[1],   nonce[2],   nonce[3],
    };

    -- Working copy for the 20 rounds
    local working = {};
    for i = 1, 16 do working[i] = state[i]; end

    -- 20 rounds
    chacha20_rounds(working);

    -- Add original state
    for i = 1, 16 do
        working[i] = u32_add(working[i], state[i]);
    end

    -- Return 64‑byte keystream block
    return pack_u32_le(working);
end

-- Produce a 32‑byte HChaCha20 block.
local function hchacha20(key, nonce)
    -- Initial HChaCha20 state with 4 nonce words and no counter
    local state = {
        0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,
        key[1],     key[2],     key[3],     key[4],
        key[5],     key[6],     key[7],     key[8],
        nonce[1],   nonce[2],   nonce[3],   nonce[4],
    };

    -- Working copy for the 20 rounds
    local working = {};
    for i = 1, 16 do working[i] = state[i]; end

    -- 20 rounds
    chacha20_rounds(working);

    -- 32-byte subkey = state[0..3] and state[12..15]
    local out_words = {
        working[1], working[2], working[3], working[4],
        working[13], working[14], working[15], working[16],
    };

    -- Return 32‑byte subkey
    return pack_u32_le(out_words);
end

-- Generate the next 64‑byte keystream block and increment counter.
local function generate_block(self)
    self.keystream = chacha20_block(self.key, self.nonce, self.counter);
    self.counter = (self.counter + 1) % 0x100000000;
end

local chacha20core = {
    unpack_u32_le = unpack_u32_le,
    pack_u32_le = pack_u32_le,
    chacha20_block = chacha20_block,
    hchacha20 = hchacha20;
    generate_block = generate_block,
};

return chacha20core;