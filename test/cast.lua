local ffi = require 'ffiex.init'
ffi.cdef[[
	#include <net/if.h>
	#include <sys/ioctl.h>
]]
print(ffi.defs.SIOCGIFADDR)
return true