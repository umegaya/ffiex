local ffi = require 'ffiex.init'
--ffi.__DEBUG_CDEF__ = true
local C = ffi.C

ffi.import({"printf", "sprintf"}):from [[
#include <stdio.h>
]]

assert(C.printf)
assert(C.sprintf)
local ok, r = pcall(getmetatable(C).__index, C, "fprintf")
assert(not ok)


ffi.cdef[[
#include "./test/myheaders/my.h"
]]

assert(ffi.defs.MY_MACRO)
local ok, r = pcall(getmetatable(C).__index, C, "fprintf")
assert(not ok)

return true