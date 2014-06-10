local ffi = require 'ffiex.init'
local state = ffi.newstate()
local fdecl = "__attribute__((noreturn)) void no_return_fn(char *p);"

state:cdef((
[[
#define FOO(x) (x + 1)
%s
]]
):format(fdecl)
)
assert(state.defs.FOO(1) == 2, "invalid macro parse:"..state.defs.FOO(1))
-- main ffiex still doen't know macro FOO
assert(nil == ffi.defs.FOO, "FOO should not exist:"..tostring(ffi.defs.FOO))
-- able to define another macro FOO
local src_fdecl = state:src_of("no_return_fn")
assert(src_fdecl:gsub("%s", "") == fdecl:gsub("%s", ""), "invalid src_of:["..src_fdecl.."]")
local src_fdecl2 = state:src_of("no_return_fn", true)
assert(src_fdecl2:gsub("%s", "") == fdecl:gsub("%s", ""), "invalid src_of:["..src_fdecl2.."]")

ffi.cdef[[
#define FOO(x) (x + 10)
]]
assert(ffi.defs.FOO(1) == 11, "wrongly defined macro:"..ffi.defs.FOO(1)) --> 11

return true