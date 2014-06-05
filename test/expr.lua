local ffi = require 'ffiex.init'

ffi.cdef [[
#if L'\0' - 1 > 0 
#define HOGE "hoge"
#else
#define HOGE "fuga"
#endif
]]

assert("fuga" == ffi.defs.HOGE)

return true
