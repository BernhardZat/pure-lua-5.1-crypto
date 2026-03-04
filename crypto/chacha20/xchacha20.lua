local chacha20core = require("crypto.chacha20.chacha20core");
local ChaCha20 = require("crypto.chacha20.chacha20");

-- ChaCha20 stream cipher object
local XChaCha20 = {};
XChaCha20.__index = XChaCha20;

-- Create a new XChaCha20 stream cipher instance.
function XChaCha20.new(key, nonce, counter)
    assert(#key == 32, "XChaCha20 key must be 32 bytes");
    assert(#nonce == 24, "XChaCha20 nonce must be 24 bytes");

    -- First 16 bytes for HChaCha20, last 8 for ChaCha20
    local nonce16 = nonce:sub(1, 16);
    local nonce8  = nonce:sub(17, 24);

    -- Derive subkey using HChaCha20
    key = chacha20core.unpack_u32_le(key);
    nonce16 = chacha20core.unpack_u32_le(nonce16);
    local subkey = chacha20core.hchacha20(key, nonce16);

    -- For ChaCha20 nonce prepend 4 zero bytes.
    local chacha_nonce = ("\0"):rep(4) .. nonce8;

    local self = setmetatable({}, XChaCha20);
    self.cipher = ChaCha20.new(subkey, chacha_nonce, counter);

    return self;
end

-- XOR the keystream with the given data and return the result.
function XChaCha20:apply_keystream(data)
    return self.cipher:apply_keystream(data);
end

-- Seek to an absolute byte offset in the ChaCha20 stream.
function XChaCha20:seek(byte_offset)
    self.cipher:seek(byte_offset);
    return self;
end

return XChaCha20;
