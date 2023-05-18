-- Copyright (c) 2023 BernhardZat  -- see LICENSE file

local number_to_bytestring = function(num, n)
	n = n or math.floor(math.log(num) / math.log(0x100) + 1);
	n = n > 0 and n or 1;
	local s = "";
	for i = 1, n do
		s = string.char((num % 0x100 ^ i - num % 0x100 ^ (i - 1)) / 0x100 ^ (i - 1)) .. s;
	end
	s = ("\0"):rep(n - s:len()) .. s;
	return s, n;
end

local bytestring_to_number = function(s)
	local num = 0;
	for i = 0, s:len() - 1 do
		num = num + s:byte(s:len() - i) * 0x100 ^ i;
	end
	return num;
end

local bytetable_to_bytestring = function(t)
	local s = t[0] and string.char(t[0]) or "";
	for i = 1, #t do
		s = s .. string.char(t[i]);
	end
	return s;
end
local bytestring_to_bytetable = function(s, zero_based)
	local t = {};
	local j = zero_based and 1 or 0;
	for i = 1, s:len() do
		t[i - j] = s:byte(i);
	end
	return t;
end

_G.Util = {
	number_to_bytestring = number_to_bytestring,
	bytestring_to_number = bytestring_to_number,
	bytetable_to_bytestring = bytetable_to_bytestring,
	bytestring_to_bytetable = bytestring_to_bytetable,
}
