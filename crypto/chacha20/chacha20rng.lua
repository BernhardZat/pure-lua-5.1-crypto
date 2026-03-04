local chacha20core = require("crypto.chacha20.chacha20core");
local ChaCha20 = require("crypto.chacha20.chacha20");

local ChaCha20Rng = {};
ChaCha20Rng.__index = ChaCha20Rng;

-- 32 bytes of seed material
function ChaCha20Rng.new(seed)
    assert(#seed == 32, "ChaCha20Rng seed must be 32 bytes");
    local nonce = ("\0"):rep(12);
    local self = setmetatable({}, ChaCha20Rng);
    self.cipher = ChaCha20.new(seed, nonce);
    return self;
end

-- Reseed with 32 bytes seed
function ChaCha20Rng:reseed(new_seed)
    assert(#new_seed == 32, "ChaCha20Rng seed must be 32 bytes");
    local nonce = ("\0"):rep(12);
    self.cipher = ChaCha20.new(new_seed, nonce);
end

-- Get one byte from the keystream
local function next_byte(self)
    -- Generate block if needed
    if self.cipher.offset == 0 or self.cipher.keystream == "" then
        self.cipher.keystream = chacha20core.chacha20_block(
            self.cipher.key,
            self.cipher.nonce,
            self.cipher.counter
        );
        self.cipher.counter = (self.cipher.counter + 1) % 0x100000000;
    end

    local b = self.cipher.keystream:byte(self.cipher.offset + 1);
    self.cipher.offset = (self.cipher.offset + 1) % 64;
    return b;
end

-- Get n random bytes
function ChaCha20Rng:next_bytes(n)
    local out = {};
    for i = 1, n do
        out[i] = string.char(next_byte(self));
    end
    return table.concat(out);
end

-- Get a random 32‑bit integer
function ChaCha20Rng:next_u32()
    local b1 = next_byte(self);
    local b2 = next_byte(self);
    local b3 = next_byte(self);
    local b4 = next_byte(self);
    return b1 + b2 * 0x100 + b3 * 0x10000 + b4 * 0x1000000;
end

return ChaCha20Rng;
