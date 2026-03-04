--------------------------------------------------------------------------------------------------
-- HMAC-based Extract-and-Expand Key Derivation Function (HKDF)
-- This implementation follows RFC 5869 and uses BLAKE2s as the underlying hash function.
--
-- Security notes:
--   - The input keying material (IKM) should already be a high-entropy value. Do not use raw
--     passphrases without running them through a proper password hashing function first.
--   - The salt value is for domain separation and should be unique for each application. It can
--     be a random value or a fixed string, e.g. the application name.
--   - The info parameter can be used to ensure key separation for multiple keys derived from the
--     same IKM and salt, e.g. a context string like "encryption key" or "authentication key".
--------------------------------------------------------------------------------------------------

local blake2s = require("crypto.blake2s.blake2s");

-- Takes input keying material and a salt, and produces a pseudorandom key (PRK)
local extract = function (ikm, salt)
    if not salt then
        salt = ("\0"):rep(32);
    end
    return blake2s.digest(ikm, salt);
end

-- Takes a pseudorandom key (PRK) and info, and produces output keying material (OKM) of the desired length
local expand = function (prk, info, length)
    -- If info is not provided, use an empty string as per RFC 5869
    if not info then
        info = "";
    end
    
    -- Calculate the number of blocks needed to generate the desired length
    -- RFC 5869 limits the output length to 255 blocks of the hash output size
    local n = math.ceil(length / 32);
    assert(n <= 255, "Cannot expand to more than 255 blocks of 32 bytes");
    
    local t = "";
    local okm = {};

    -- Generate each block of output keying material
    for i = 1, n do
        local hasher = blake2s.init(prk);
        hasher:update(t);
        hasher:update(info);
        hasher:update(string.char(i));
        t = hasher:finalize();
        okm[#okm + 1] = t;
    end
    
    return table.concat(okm):sub(1, length);
end

-- Derive output keying material from input keying material, salt, and info
local derive = function (ikm, salt, info, length)
    local prk = extract(ikm, salt);
    return expand(prk, info, length);
end

-- Export public API
local hkdf = {
    extract = extract,
    expand = expand,
    derive = derive,
};

return hkdf;