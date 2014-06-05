local ffi = require 'ffiex.init'
ffi.cdef [[
typedef int FT_UInt32;
typedef enum FT_Encoding_
{
 FT_ENCODING_NONE = ( ( (FT_UInt32)(0) << 24 ) | ( (FT_UInt32)(0) << 16 ) | ( (FT_UInt32)(0) << 8 ) | (FT_UInt32)(0) ),
 FT_ENCODING_MS_SYMBOL = ( ( (FT_UInt32)("s") << 24 ) | ( (FT_UInt32)("y") << 16 ) | ( (FT_UInt32)("m") << 8 ) | (FT_UInt32)("b") ),
 FT_ENCODING_UNICODE = ( ( (FT_UInt32)("u") << 24 ) | ( (FT_UInt32)("n") << 16 ) | ( (FT_UInt32)("i") << 8 ) | (FT_UInt32)("c") ),
 FT_ENCODING_SJIS = ( ( (FT_UInt32)("s") << 24 ) | ( (FT_UInt32)("j") << 16 ) | ( (FT_UInt32)("i") << 8 ) | (FT_UInt32)("s") ),
 FT_ENCODING_GB2312 = ( ( (FT_UInt32)("g") << 24 ) | ( (FT_UInt32)("b") << 16 ) | ( (FT_UInt32)(" ") << 8 ) | (FT_UInt32)(" ") ),
 FT_ENCODING_BIG5 = ( ( (FT_UInt32)("b") << 24 ) | ( (FT_UInt32)("i") << 16 ) | ( (FT_UInt32)("g") << 8 ) | (FT_UInt32)("5") ),
 FT_ENCODING_WANSUNG = ( ( (FT_UInt32)("w") << 24 ) | ( (FT_UInt32)("a") << 16 ) | ( (FT_UInt32)("n") << 8 ) | (FT_UInt32)("s") ),
 FT_ENCODING_JOHAB = ( ( (FT_UInt32)("j") << 24 ) | ( (FT_UInt32)("o") << 16 ) | ( (FT_UInt32)("h") << 8 ) | (FT_UInt32)("a") ),
 FT_ENCODING_MS_SJIS = FT_ENCODING_SJIS,
 FT_ENCODING_MS_GB2312 = FT_ENCODING_GB2312,
 FT_ENCODING_MS_BIG5 = FT_ENCODING_BIG5,
 FT_ENCODING_MS_WANSUNG = FT_ENCODING_WANSUNG,
 FT_ENCODING_MS_JOHAB = FT_ENCODING_JOHAB,
 FT_ENCODING_ADOBE_STANDARD = ( ( (FT_UInt32)("A") << 24 ) | ( (FT_UInt32)("D") << 16 ) | ( (FT_UInt32)("O") << 8 ) | (FT_UInt32)("B") ),
 FT_ENCODING_ADOBE_EXPERT = ( ( (FT_UInt32)("A") << 24 ) | ( (FT_UInt32)("D") << 16 ) | ( (FT_UInt32)("B") << 8 ) | (FT_UInt32)("E") ),
 FT_ENCODING_ADOBE_CUSTOM = ( ( (FT_UInt32)("A") << 24 ) | ( (FT_UInt32)("D") << 16 ) | ( (FT_UInt32)("B") << 8 ) | (FT_UInt32)("C") ),
 FT_ENCODING_ADOBE_LATIN_1 = ( ( (FT_UInt32)("l") << 24 ) | ( (FT_UInt32)("a") << 16 ) | ( (FT_UInt32)("t") << 8 ) | (FT_UInt32)("1") ),
 FT_ENCODING_OLD_LATIN_2 = ( ( (FT_UInt32)("l") << 24 ) | ( (FT_UInt32)("a") << 16 ) | ( (FT_UInt32)("t") << 8 ) | (FT_UInt32)("2") ),
 FT_ENCODING_APPLE_ROMAN = ( ( (FT_UInt32)("a") << 24 ) | ( (FT_UInt32)("r") << 16 ) | ( (FT_UInt32)("m") << 8 ) | (FT_UInt32)("n") )
} FT_Encoding;
int sprintf(char *buf, const char *format, ...); 
]]

local p = ffi.new('FT_Encoding', "FT_ENCODING_GB2312")
assert(p == 33686018, "invalid enum constant value:"..tostring(p))
return true
