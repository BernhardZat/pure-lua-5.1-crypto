-- Copyright (c) 2023 BernhardZat  -- see LICENSE file

local enc = {
	[0] =
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
	"a",
	"b",
	"c",
	"d",
	"e",
	"f",
	"g",
	"h",
	"i",
	"j",
	"k",
	"l",
	"m",
	"n",
	"o",
	"p",
	"q",
	"r",
	"s",
	"t",
	"u",
	"v",
	"w",
	"x",
	"y",
	"z",
	"0",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"+",
	"/"
};

local dec = {
	["A"] = 0,
	["B"] = 1,
	["C"] = 2,
	["D"] = 3,
	["E"] = 4,
	["F"] = 5,
	["G"] = 6,
	["H"] = 7,
	["I"] = 8,
	["J"] = 9,
	["K"] = 10,
	["L"] = 11,
	["M"] = 12,
	["N"] = 13,
	["O"] = 14,
	["P"] = 15,
	["Q"] = 16,
	["R"] = 17,
	["S"] = 18,
	["T"] = 19,
	["U"] = 20,
	["V"] = 21,
	["W"] = 22,
	["X"] = 23,
	["Y"] = 24,
	["Z"] = 25,
	["a"] = 26,
	["b"] = 27,
	["c"] = 28,
	["d"] = 29,
	["e"] = 30,
	["f"] = 31,
	["g"] = 32,
	["h"] = 33,
	["i"] = 34,
	["j"] = 35,
	["k"] = 36,
	["l"] = 37,
	["m"] = 38,
	["n"] = 39,
	["o"] = 40,
	["p"] = 41,
	["q"] = 42,
	["r"] = 43,
	["s"] = 44,
	["t"] = 45,
	["u"] = 46,
	["v"] = 47,
	["w"] = 48,
	["x"] = 49,
	["y"] = 50,
	["z"] = 51,
	["0"] = 52,
	["1"] = 53,
	["2"] = 54,
	["3"] = 55,
	["4"] = 56,
	["5"] = 57,
	["6"] = 58,
	["7"] = 59,
	["8"] = 60,
	["9"] = 61,
	["+"] = 62,
	["/"] = 63
}

local encode = function(s)
	local r = s:len() % 3;
	s = r == 0 and s or s .. ("\0"):rep(3 - r);
	local b64 = "";
	for i = 1, s:len(), 3 do
		local b1, b2, b3 = s:byte(i, i + 2);
		b64 = b64 .. enc[math.floor(b1 / 0x04)];
		b64 = b64 .. enc[math.floor(b2 / 0x10) + (b1 % 0x04) * 0x10];
		b64 = b64 .. enc[math.floor(b3 / 0x40) + (b2 % 0x10) * 0x04];
		b64 = b64 .. enc[b3 % 0x40];
	end
	b64 = b64 .. (r == 0 and "" or ("="):rep(3 - r));
	return b64;
end

local decode = function(b64)
	local b, p = b64:gsub("=", "");
	local s = "";
	for i = 1, b:len(), 4 do
		local b1 = dec[b:sub(i, i)];
		local b2 = dec[b:sub(i + 1, i + 1)];
		local b3 = dec[b:sub(i + 2, i + 2)];
		local b4 = dec[b:sub(i + 3, i + 3)];
		s = s .. string.char(
			b1 * 0x04 + math.floor(b2 / 0x10),
			(b2 % 0x10) * 0x10 + math.floor(b3 / 0x04),
			(b3 % 0x04) * 0x40 + b4
		);
	end
	s = s:sub(1, -(p + 1));
	return s;
end

_G.Base64 = {
	encode = encode,
	decode = decode,
}
