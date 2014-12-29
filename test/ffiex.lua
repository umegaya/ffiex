local ffi = require 'ffiex.init'
-- ffi.__DEBUG_CDEF__ = true

local pt
if ffi.os == 'OSX' then
	ffi.search("/Applications/Xcode.app/Contents/Developer/usr", "stdarg.h", true)
	pt = ffi.C
elseif ffi.os == 'Linux' then
	pt = ffi.load('pthread')
end

ffi.cdef [[
#include <pthread.h>
#include <memory.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
]]

assert(pt.pthread_join)
assert(ffi.C.malloc)
assert(ffi.C.connect)
assert(ffi.C.inet_ntoa)

ffi.path "/usr/local/include/luajit-2.0"
ffi.path "/Applications/Xcode.app/Contents/Developer/usr/lib/llvm-gcc/4.2.1/include"
ffi.cdef "#include <lauxlib.h>"

assert(ffi.C.luaL_newstate, "could not parse lauxlib.h correctly")

return true