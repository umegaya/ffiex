local ffi = require "ffiex.init"
if ffi.os == "OSX" then
	ffi.cdef "#define XP_NO_X_HEADERS"
    ffi.search("/Applications/Xcode.app/Contents/Developer/usr", "stdarg.h", true)
    ffi.cdef "#include <stdio.h>"
end
ffi.cdef (("#include <%s>"):format(arg[1]))
