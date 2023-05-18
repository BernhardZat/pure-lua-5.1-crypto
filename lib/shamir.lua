-- Copyright (c) 2023 BernhardZat  -- see LICENSE file

local gf = Gf256.new;

local share_byte = function(byte, randoms, index)
    byte = gf(byte);
    for i, r in ipairs(randoms) do
        byte = byte + gf(r) * gf(index) ^ gf(i);
    end
    return byte:to_number();
end

local reconstruct_byte = function(indices, bytes)
    local sum = gf(0);
    for i, byte in ipairs(bytes) do
        local prod = gf(byte);
        local xi = gf(indices[i]);
        for j, index in ipairs(indices) do
            local xj = gf(index);
            if i ~= j then
                prod = prod * xj / (xi - xj);
            end
        end
        sum = sum + prod;
    end
    return sum:to_number();
end

local share_bytestring = function(str, k, n, rng)
    rng = rng or function() return math.random(0, 0xFF) end;
    local shares = {};
    for i = 1, n do shares[i] = string.char(i); end
    for byte in str:gmatch(".") do
        byte = byte:byte();
        local randoms = {};
        for i = 1, k - 1 do
            randoms[i] = rng();
        end
        for i = 1, n do
            shares[i] = shares[i] .. string.char(share_byte(byte, randoms, i));
        end
    end
    return shares;
end

local reconstruct_bytestring = function(shares)
    local str = "";
    local indices = {};
    for i = 1, #shares do
        indices[i] = shares[i]:sub(1, 1):byte();
    end
    for i = 2, shares[1]:len() do
        local bytes = {};
        for j = 1, #shares do
            bytes[j] = shares[j]:sub(i, i):byte();
        end
        str = str .. string.char(reconstruct_byte(indices, bytes));
    end
    return str;
end

_G.Shamir = {
    share_byte = share_byte,
    reconstruct_byte = reconstruct_byte,
    share_bytestring = share_bytestring,
    reconstruct_bytestring = reconstruct_bytestring,
};
