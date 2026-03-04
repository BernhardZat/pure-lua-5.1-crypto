local bitops = require("util.bitops.bitops");
local u8_and = bitops.u8_and;
local u8_lsh = bitops.u8_lsh;
local u8_rsh = bitops.u8_rsh;

-- Encoding lookup table
local enc = {
    [0] =
    "A","B","C","D","E","F","G","H","I","J","K","L","M",
    "N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    "a","b","c","d","e","f","g","h","i","j","k","l","m",
    "n","o","p","q","r","s","t","u","v","w","x","y","z",
    "0","1","2","3","4","5","6","7","8","9","+","/"
};

-- Decoding lookup table
local dec = {
    ["A"]= 0,["B"]= 1,["C"]= 2,["D"]= 3,["E"]= 4,["F"]= 5,["G"]= 6,["H"]= 7,["I"]= 8,["J"]= 9,["K"]=10,["L"]=11,["M"]=12,
    ["N"]=13,["O"]=14,["P"]=15,["Q"]=16,["R"]=17,["S"]=18,["T"]=19,["U"]=20,["V"]=21,["W"]=22,["X"]=23,["Y"]=24,["Z"]=25,
    ["a"]=26,["b"]=27,["c"]=28,["d"]=29,["e"]=30,["f"]=31,["g"]=32,["h"]=33,["i"]=34,["j"]=35,["k"]=36,["l"]=37,["m"]=38,
    ["n"]=39,["o"]=40,["p"]=41,["q"]=42,["r"]=43,["s"]=44,["t"]=45,["u"]=46,["v"]=47,["w"]=48,["x"]=49,["y"]=50,["z"]=51,
    ["0"]=52,["1"]=53,["2"]=54,["3"]=55,["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["+"]=62,["/"]=63
};

-- Encode a raw byte string into base64
local encode = function (s)
    local r = s:len() % 3;
    local pad = (r == 0) and 0 or (3 - r);

    -- Pad with NUL bytes for processing
    local work = (pad == 0) and s or s .. ("\0"):rep(pad);
    local b64 = "";

    for i = 1, work:len(), 3 do
        -- process 3 bytes at a time
        local b1, b2, b3 = work:byte(i, i+2);

        -- encode 3 bytes as 4 characters
        b64 = b64 .. enc[u8_rsh(b1, 2)];
        b64 = b64 .. enc[u8_lsh(u8_and(b1, 3), 4) + u8_rsh(b2, 4)];
        b64 = b64 .. enc[u8_lsh(u8_and(b2, 15), 2) + u8_rsh(b3, 6)];
        b64 = b64 .. enc[u8_and(b3, 63)];
    end

    -- Replace padding bytes with '=' characters
    b64 = pad == 0 and b64 or b64:sub(1, - (pad + 1)) .. ("="):rep(pad);

    return b64;
end

-- Decode a base64 string back into raw bytes
local decode = function (b64)
    -- Count padding
    local _, pad = b64:gsub("=", "");
    local s = "";

    for i = 1, b64:len(), 4 do
        -- Process 4 characters at a time
        local c1 = dec[b64:sub(i, i)];
        local c2 = dec[b64:sub(i+1, i+1)];
        local c3 = dec[b64:sub(i+2, i+2)] or 0;
        local c4 = dec[b64:sub(i+3, i+3)] or 0;

        -- Reconstruct 3 bytes from 4 characters
        local b1 = u8_lsh(c1, 2) + u8_rsh(c2, 4);
        local b2 = u8_lsh(u8_and(c2, 15), 4) + u8_rsh(c3, 2);
        local b3 = u8_lsh(u8_and(c3, 3), 6) + c4;

        s = s .. string.char(b1, b2, b3);
    end

    -- Remove padding bytes
    s = pad == 0 and s or s:sub(1, - (pad + 1));

    return s;
end

-- Export public API
local base64 = {
    encode = encode,
    decode = decode,
};

return base64;