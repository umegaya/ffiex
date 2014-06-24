local ffi = require 'ffiex.init'

ffi.cdef[[
enum {
	HOGE = 1,
#define HOGE HOGE
}
]]

assert(ffi.defs.HOGE == "HOGE")

return true