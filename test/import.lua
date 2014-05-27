local ffi = require 'ffiex.init'
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


ffi.load("pthread")
ffi.import({
"pthread_join",
"pthread_create",
"pthread_mutex_t",
}):from [[
#include <pthread.h>
]]

assert(ffi.C.pthread_join)
assert(ffi.C.pthread_create)

return true