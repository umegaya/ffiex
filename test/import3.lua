local ffi = require 'ffiex.init'
-- ffi.__DEBUG_CDEF__ = true

local s1, s2 = ffi.newstate(), ffi.newstate()

s1:copt { cc = "gcc" }
s2:copt { cc = "gcc" }

s1:import({"nanosleep"}):from [[
	#include <time.h>
]]
assert(ffi.imported_csymbols["struct timespec"], "timespec not imported")
if ffi.os == "OSX" then
	s2:import({"func kevent"}):from [[
		#include <sys/types.h>
		#include <sys/time.h>
		#include <sys/event.h>
	]]

assert(ffi.C.nanosleep)
assert(ffi.C.kevent)
elseif ffi.os == "Linux" then
	s2:import({"clock_gettime"}):from [[
		#include <time.h>
	]]
assert(ffi.C.nanosleep)
local rt = ffi.load("rt")
assert(rt.clock_gettime)
end

ffi.cdef [[
#include <time.h>
]]

assert(ffi.C.time)

return true
