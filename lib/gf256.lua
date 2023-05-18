local u8_xor, u16_xor = Bitops.u8_xor, Bitops.u16_xor;

local log = { [0] = 512 };
local alog = { [0] = 1 };
for i = 1, 254 do
    local next = alog[i - 1] * 2;
    if next > 255 then
        next = u16_xor(next, 0x11D);
    end
    alog[i] = next;
    log[next] = i;
end
alog[255] = alog[0];
log[alog[255]] = 255;
for i = 256, 509 do
    alog[i] = alog[i % 255];
end
alog[510] = 1;
for i = 511, 1025 do
    alog[i] = 0;
end

local gf256 = {};
gf256.__index = gf256;

local gf256_table = {};
for i = 0, 255 do
    local element = setmetatable({ v = i }, gf256);
    gf256_table[i] = element;
end

gf256.__add = function(a, b)
    return gf256_table[u8_xor(a.v, b.v)];
end

gf256.__sub = function(a, b)
    return gf256_table[u8_xor(a.v, b.v)];
end

gf256.__mul = function(a, b)
    return gf256_table[alog[log[a.v] + log[b.v]]];
end

gf256.__div = function(a, b)
    assert(b.v ~= 0, "Division by zero!");
    return gf256_table[alog[log[a.v] - log[b.v] + 255]];
end

gf256.__pow = function(a, b)
    if a.v == 0 and b.v ~= 0 then
        return gf256_table[0];
    else
        return gf256_table[alog[(log[a.v] * b.v) % 255]];
    end
end

gf256.__tostring = function(a)
    return "0x" .. string.format("%02X", a.v);
end

gf256.to_string = function(self)
    return tostring(self);
end

gf256.to_number = function(self)
    return self.v;
end

local new = function(n)
    return gf256_table[n];
end

_G.Gf256 = {
    new = new,
    to_string = gf256.to_string,
    to_number = gf256.to_number,
};
