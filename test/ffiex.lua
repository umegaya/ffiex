local ffi = require 'ffiex.init'

if ffi.os == 'OSX' then
	ffi.cdef "#define __asm(exp)"
	ffi.search("/Applications/Xcode.app/Contents/Developer/usr", "stdarg.h", true)
end

ffi.cdef [[
#include <pthread.h>
#include <memory.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
]]

assert(ffi.C.pthread_join)
assert(ffi.C.malloc)
assert(ffi.C.connect)
assert(ffi.C.inet_ntoa)

ffi.path "/usr/local/include/luajit-2.0"
ffi.path "/Applications/Xcode.app/Contents/Developer/usr/lib/llvm-gcc/4.2.1/include"
ffi.cdef "#include <lauxlib.h>"

assert(ffi.C.luaL_newstate, "could not parse lauxlib.h correctly")
