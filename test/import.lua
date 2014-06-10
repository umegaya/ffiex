local ffi = require 'ffiex.init'
--ffi.__DEBUG_CDEF__ = true

ffi.import({
"printf",
"sprintf",
}):from [[
#include <stdio.h>
]]

ffi.C.printf("%s is test\n", "test")

local msg = ffi.new("char[256]")
ffi.C.sprintf(msg, "%d:%d", ffi.new("int", 100), ffi.new("int", 200))

assert(ffi.string(msg) == "100:200")


local lib = ffi.load("pthread")
ffi.import({
"pthread_join",
"pthread_create",
"pthread_mutex_t",
}):from [[
#include <pthread.h>
]]

assert(lib.pthread_join)
assert(lib.pthread_create)

return true
