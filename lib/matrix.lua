-- Copyright (c) 2023 BernhardZat  -- see LICENSE file

local matrix = {};
matrix.__index = matrix;

local new = function(n, m, init, zero, one)
	local attrs = {
		n = n,
		m = m or n,
		init = init or 0,
		zero = zero or 0,
		one = one or 1,
		data = {},
	};
	return setmetatable(attrs, matrix);
end

local identity = function(size, zero, one)
	zero = zero or 0;
	one = one or 1;
	local id = new(size, size, zero, zero, one);
	for i = 0, size - 1 do
		id:set(i, i, one);
	end
	return id;
end

matrix.set = function(self, i, j, v)
	self.data[i * self.m + j] = v;
end

matrix.get = function(self, i, j)
	return self.data[i * self.m + j] or self.init;
end

matrix.set_sub = function(self, sub, i, j)
	for k = 0, sub.n - 1 do
		for l = 0, sub.m - 1 do
			self:set(i + k, j + l, sub:get(k, l));
		end
	end
end

matrix.get_sub = function(self, i, j, n, m)
	local sub = new(n, m);
	for k = 0, n - 1 do
		for l = 0, m - 1 do
			sub:set(k, l, self:get(i + k, j + l));
		end
	end
	return sub;
end

matrix.set_row = function(self, row, i)
	self:set_sub(row, i, 0);
end

matrix.get_row = function(self, i)
	return self:get_sub(i, 0, 1, self.m);
end

matrix.set_col = function(self, column, j)
	self:set_sub(column, 0, j);
end

matrix.get_col = function(self, j)
	return self:get_sub(0, j, self.n, 1);
end

matrix.__add = function(a, b)
	local c = new(a.n, a.m);
	for i = 0, a.n - 1 do
		for j = 0, a.m - 1 do
			c:set(i, j, a:get(i, j) + b:get(i, j));
		end
	end
	return c;
end

matrix.__sub = function(a, b)
	local c = new(a.n, a.m);
	for i = 0, a.n - 1 do
		for j = 0, a.m - 1 do
			c:set(i, j, a:get(i, j) - b:get(i, j));
		end
	end
	return c;
end

matrix.__mul = function(a, b)
	local c = new(a.n, b.m);
	for i = 0, a.n - 1 do
		for j = 0, b.m - 1 do
			local sum = 0;
			for k = 0, a.m - 1 do
				sum = sum + a:get(i, k) * b:get(k, j);
			end
			c:set(i, j, sum);
		end
	end
	return c;
end

matrix.__tostring = function(self)
	local s = "";
	for i = 0, self.n - 1 do
		for j = 0, self.m - 1 do
			s = s .. tostring(self:get(i, j)) .. " ";
		end
		s = s .. "\n";
	end
	return s;
end

_G.Matrix = {
	new = new,
	identity = identity,
	set = matrix.set,
	get = matrix.get,
	set_sub = matrix.set_sub,
	get_sub = matrix.get_sub,
	set_row = matrix.set_row,
	get_row = matrix.get_row,
	set_col = matrix.set_col,
	get_col = matrix.get_col,
};
