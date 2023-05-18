-- Copyright (c) 2023 BernhardZat  -- see LICENSE file

local XOR, LROT = Bitops.u32_xor, Bitops.u32_lrot;
local num_to_bytes, num_from_bytes = Util.num_to_bytes, Util.num_from_bytes;

local unpack = function(s)
    local array = {};
    for i = 1, s:len(), 4 do
        table.insert(array, num_from_bytes(s:sub(i, i + 3)));
    end
    return array;
end

local pack = function(a)
    local array = {};
    for i = 1, #a do
        array[i] = num_to_bytes(a[i], 4);
    end
    return table.concat(array);
end

local quarter_round = function(s, a, b, c, d)
    s[a] = (s[a] + s[b]) % 0x100000000; s[d] = LROT(XOR(s[d], s[a]), 16);
    s[c] = (s[c] + s[d]) % 0x100000000; s[b] = LROT(XOR(s[b], s[c]), 12);
    s[a] = (s[a] + s[b]) % 0x100000000; s[d] = LROT(XOR(s[d], s[a]), 8);
    s[c] = (s[c] + s[d]) % 0x100000000; s[b] = LROT(XOR(s[b], s[c]), 7);
end

local block = function(key, nonce, counter)
    local init = {
        0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,
        key[1], key[2], key[3], key[4],
        key[5], key[6], key[7], key[8],
        counter, nonce[1], nonce[2], nonce[3],
    }
    local state = {};
    for i = 1, 16 do
        state[i] = init[i];
    end
    for _ = 1, 10 do
        quarter_round(state, 1, 5, 9, 13);
        quarter_round(state, 2, 6, 10, 14);
        quarter_round(state, 3, 7, 11, 15);
        quarter_round(state, 4, 8, 12, 16);
        quarter_round(state, 1, 6, 11, 16);
        quarter_round(state, 2, 7, 12, 13);
        quarter_round(state, 3, 8, 9, 14);
        quarter_round(state, 4, 5, 10, 15);
    end
    for i = 1, 16 do
        state[i] = (state[i] + init[i]) % 0x100000000;
    end
    return state;
end

local encrypt = function(plain, key, nonce)
    key = unpack(key);
    nonce = unpack(nonce);
    local counter = 0;
    local cipher = "";
    while counter < math.floor(plain:len() / 64) do
        local key_stream = block(key, nonce, counter);
        local plain_block = unpack(plain:sub(counter * 64 + 1, (counter + 1) * 64));
        local cipher_block = {};
        for j = 1, 16 do
            cipher_block[j] = XOR(plain_block[j], key_stream[j]);
        end
        cipher = cipher .. pack(cipher_block);
        counter = counter + 1;
    end
    if plain:len() % 64 ~= 0 then
        local key_stream = block(key, nonce, counter);
        local plain_block = unpack(plain:sub(counter * 64 + 1));
        local cipher_block = {};
        for j = 1, math.ceil((plain:len() % 64) / 4) do
            cipher_block[j] = XOR(plain_block[j], key_stream[j]);
        end
        cipher = cipher .. pack(cipher_block);
    end
    return cipher;
end

local decrypt = function(cipher, key, nonce)
    return encrypt(cipher, key, nonce);
end


_G.ChaCha20 = {
    encrypt = encrypt,
    decrypt = decrypt,
}
