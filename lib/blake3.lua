-- Copyright (c) 2023 BernhardZat  -- see LICENSE file

-- WORK IN PROGRESS, DOES NOT WORK YET! --

local XOR, RROT, RSH, OR = Bitops.u32_xor, Bitops.u32_rrot, Bitops.u32_rsh, Bitops.u32_or;

local OUT_LEN = 32;
local KEY_LEN = 32;
local BLOCK_LEN = 64;
local CHUNK_LEN = 1024;

local CHUNK_START = 1;
local CHUNK_END = 2;
local PARENT = 4;
local ROOT = 8;
local KEYED_HASH = 16;
local KEY_CONTEXT = 32;
local DERIVE_KEY_MATERIAL = 64;

local IV = { [0] = 0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19 };
local MSG_PERMUTATION = { [0] = 2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8 };

local g = function(state, a, b, c, d, mx, my)
    state[a] = (state[a] + state[b] + mx) % 0x100000000;
    state[d] = RROT(XOR(state[d], state[a]), 16);
    state[c] = (state[c] + state[d]) % 0x100000000;
    state[b] = RROT(XOR(state[b], state[c]), 12);
    state[a] = (state[a] + state[b] + my) % 0x100000000;
    state[d] = RROT(XOR(state[d], state[a]), 8);
    state[c] = (state[c] + state[d]) % 0x100000000;
    state[b] = RROT(XOR(state[b], state[c]), 7);
end

local round = function(state, m)
    g(state, 0, 4, 8, 12, m[0], m[1]);
    g(state, 1, 5, 9, 13, m[2], m[3]);
    g(state, 2, 6, 10, 14, m[4], m[5]);
    g(state, 3, 7, 11, 15, m[6], m[7]);
    g(state, 0, 5, 10, 15, m[8], m[9]);
    g(state, 1, 6, 11, 12, m[10], m[11]);
    g(state, 2, 7, 8, 13, m[12], m[13]);
    g(state, 3, 4, 9, 14, m[14], m[15]);
end

local permute = function(m)
    local permuted = {};
    for i = 0, 15 do
        permuted[i] = m[MSG_PERMUTATION[i]];
    end
    m = permuted;
end

local compress = function(chaining_value, block_words, counter, block_len, flags)
    local state = {
        [0] = chaining_value[0],
        chaining_value[1],
        chaining_value[2],
        chaining_value[3],
        chaining_value[4],
        chaining_value[5],
        chaining_value[6],
        chaining_value[7],
        IV[0],
        IV[1],
        IV[2],
        IV[3],
        counter,
        RSH(counter, 32),
        block_len,
        flags
    };
    local block = block_words;

    round(state, block);
    permute(block);
    round(state, block);
    permute(block);
    round(state, block);
    permute(block);
    round(state, block);
    permute(block);
    round(state, block);
    permute(block);
    round(state, block);
    permute(block);
    round(state, block);
    permute(block);

    for i = 0, 7 do
        state[i] = XOR(state[i], state[i + 8]);
        state[i + 8] = XOR(state[i + 8], chaining_value[i]);
    end
    return state;
end

local first_8_words = function(compression_output)
    return {
        compression_output[0],
        compression_output[1],
        compression_output[2],
        compression_output[3],
        compression_output[4],
        compression_output[5],
        compression_output[6],
        compression_output[7]
    };
end

local words_from_little_endian_bytes = function(bytes, words)
    -- TODO
end

local Output = {};
Output.__index = Output;

Output.chaining_value = function(self)
    return first_8_words(compress(
        self.input_chaining_value,
        self.block_words,
        self.counter,
        self.block_len,
        self.flags
    ));
end

Output.root_output_bytes = function(self, output)
    local output_block_counter = 0;

    -- TODO
end

local ChunkState = {};
ChunkState.__index = ChunkState;

ChunkState.new = function(key_words, chunk_counter, flags)
    local self = setmetatable({}, ChunkState);
    self.chaining_value = key_words;
    self.chunk_counter = chunk_counter;
    self.block = {};
    for i = 0, #BLOCK_LEN - 1 do
        self.block[i] = 0;
    end
    self.block_len = 0;
    self.blocks_compressed = 0;
    self.flags = flags;
    return self;
end

ChunkState.len = function(self)
    return BLOCK_LEN * self.blocks_compressed + self.block_len;
end

ChunkState.start_flag = function(self)
    if self.blocks_compressed == 0 then
        return CHUNK_START;
    else
        return 0;
    end
end

ChunkState.update = function(self, input)
    while input ~= "" do
         if self.block_len == BLOCK_LEN then
            local block_words = {[0] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
            words_from_little_endian_bytes(self.block, block_words);
            self.chaining_value = first_8_words(compress(
                self.chaining_value,
                block_words,
                self.chunk_counter,
                BLOCK_LEN,
                OR(self.flags, self:start_flag())
            ));
            self.blocks_compressed = self.blocks_compressed + 1;
            for i = 0, #BLOCK_LEN - 1 do
                self.block[i] = 0;
            end
            self.block_len = 0;
         end

         local want = BLOCK_LEN - self.block_len;
         local take = math.min(want, input.len());
         for i = self.block_len, take do
            self.block[i] = input[i - self.block_len];
         end
         self.block_len = self.block_len + take;
         input = input:sub(take);
    end
end

ChunkState.output = function(self)
    local block_words = {[0] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    words_from_little_endian_bytes(self.block, block_words);
    return setmetatable(
        {
            input_chaining_value = self.chaining_value,
            block_words,
            counter = self.chunk_counter,
            block_len = self.block_len,
            flags = OR(OR(self.flags, self:start_flag()), CHUNK_END)
        },
        Output
    );
end

local parent_output = function(left_child_cv, right_child_cv, key_words, flags)
    local block_words = {};
    for i = 0, 7 do block_words[i] = left_child_cv[i]; end
    for i = 8, 15 do block_words[i] = right_child_cv[i - 8]; end
    return setmetatable(
        {
            input_chaining_value = key_words,
            block_words = block_words,
            counter = 0,
            block_len = BLOCK_LEN,
            flags = flags
        },
        Output
    )
end

local parent_cv = function(left_child_cv, right_child_cv, key_words, flags)
    return parent_output(left_child_cv, right_child_cv, key_words, flags):chaining_value();
end

local Hasher = {};
Hasher.__index = Hasher;

Hasher.new_internal = function(key_words, flags)
    local self = setmetatable({}, Hasher);
    self.chunk_state = ChunkState.new(key_words, 0, flags);
    self.key_words = key_words;
    self.cv_stack = {};
    for i = 0, 53 do
        self.cv_stack[i] = { [0] = 0, 0, 0, 0, 0, 0, 0, 0 };
    end
    self.cv_stack_len = 0;
    self.flags = flags;
    return self;
end

Hasher.new = function()
    return Hasher.new_internal(IV, 0);
end

Hasher.new_keyed = function(key)
    local key_words = {};
    words_from_little_endian_bytes(key, key_words);
    return Hasher.new_internal(key_words, KEYED_HASH);
end

Hasher.new_derive_key = function(context)
    local context_hasher = Hasher.new_internal(IV, DERIVE_KEY_CONTEXT);
    context_hasher:update(context);
    local context_key = {};
    for i = 0, #KEY_LEN - 1 do
        context_key[i] = 0;
    end
    context_hasher:finalize(context_key);
    local context_key_words = {};
    words_from_little_endian_bytes(context_key, context_key_words);
    return Hasher.new_internal(context_key_words, DERIVE_KEY_MATERIAL);
end

Hasher.push_stack = function(self, cv)
    self.cv_stack[self.cv_stack_len] = cv;
    self.cv_stack_len = self.cv_stack_len + 1;
end

Hasher.pop_stack = function(self)
    self.cv_stack_len = self.cv_stack_len - 1;
    return self.cv_stack[self.cv_stack_len];
end

Hasher.add_chunk_chaining_value = function(self, new_cv, total_chunks)
    while total_chunks % 2 == 1 do
        new_cv = parent_cv(self:pop_stack(), new_cv, self.key_words, self.flags);
        total_chunks = total_chunks / 2 - (total_chunks % 2) % 1;
    end
    self:push_stack(new_cv);
end

Hasher.update = function(self, input)
    while input ~= "" do
        if self.chunk_state:len() == CHUNK_LEN then
            local chunk_cv = self.chunk_state:output():chaining_value();
            local total_chunks = self.chunk_state.chunk_counter + 1;
            self:add_chunk_chaining_value(chunk_cv, total_chunks);
            self.chunk_state = ChunkState.new(self.key_words, total_chunks, self.flags);
        end
        local want = CHUNK_LEN - self.chunk_state:len();
        local take = math.min(want, input:len());
        self.chunk_state:update(input:sub(1, take));
        input = input:sub(take + 1);
    end
end

Hasher.finalize = function(self, out_slice)
    local output = self.chunk_state:output();
    local parent_nodes_remaining = self.cv_stack_len;
    while parent_nodes_remaining > 0 do
        parent_nodes_remaining = parent_nodes_remaining - 1;
        output = parent_output(
            self.cv_stack[parent_nodes_remaining],
            output:chaining_value(),
            self.key_words,
            self.flags
        );
    end
    output:root_output_bytes(out_slice);
end
