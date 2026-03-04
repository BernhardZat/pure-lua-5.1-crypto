local bitops = require("util.bitops.bitops")
local chacha20core = require("crypto.chacha20.chacha20core");
local floor = math.floor;

-- ChaCha20 stream cipher object
local ChaCha20 = {};
ChaCha20.__index = ChaCha20;

-- Create a new ChaCha20 stream cipher instance.
function ChaCha20.new(key, nonce, counter)
    assert(#key == 32, "ChaCha20 key must be 32 bytes");
    assert(#nonce == 12, "ChaCha20 nonce must be 12 bytes");

    local self = setmetatable({}, ChaCha20);

    -- Convert key and nonce into u32 arrays
    self.key   = chacha20core.unpack_u32_le(key);
    self.nonce = chacha20core.unpack_u32_le(nonce);

    -- Stream position
    self.counter = counter or 0;    -- block index
    self.offset  = 0;               -- byte offset within block (0–63)
    self.keystream = "";            -- cached 64‑byte block

    return self;
end

-- XOR the keystream with the given data and return the result.
function ChaCha20:apply_keystream(data)
    local out = {};
    local out_len = 0;

    -- Generate a new block if we are at the start of a block or the keystream is empty
    for i = 1, #data do
        if self.offset == 0 or self.keystream == "" then
            chacha20core.generate_block(self);
        end

         -- XOR plaintext byte with keystream byte
        local ks_byte = self.keystream:byte(self.offset + 1);
        local pt_byte = data:byte(i);
        out_len = out_len + 1;
        out[out_len] = string.char(bitops.u32_xor(pt_byte, ks_byte));

        -- Advance within the 64‑byte block
        self.offset = (self.offset + 1) % 64;
    end

    return table.concat(out);
end

-- Seek to an absolute byte offset in the ChaCha20 stream.
function ChaCha20:seek(byte_offset)
    self.counter = floor(byte_offset / 64);     -- block index
    self.offset  = byte_offset % 64;            -- byte within block
    self.keystream = "";                        -- force regeneration
    return self;
end

return ChaCha20;
