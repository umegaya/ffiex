local ffi = require 'ffiex.init'
local st = ffi.cdef [[
#define DEREF(p) (*(int *)p)
]] 
local ffi_ptr = ffi.new('int[1]')
ffi_ptr[0] = 111
assert(ffi.defs.DEREF(tostring(ffi.cast('intptr_t', ffi_ptr))) == 111)

return true
