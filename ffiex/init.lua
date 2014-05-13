local ffi = require 'ffiex.core'

-- if gcc is available, try using it for initial builder.
local ok, rv = pcall(os.execute, "gcc -v 2>/dev/null")
if ok and (rv == 0) then
	ok, rv = pcall(require, 'ffiex.builder.gcc')
	if ok and rv then
		rv:init()
		ffi.builder = rv
	else
		print('gcc available but fail to initialize gcc builder:'..rv)
	end
end

-- i don't know the reason but OSX __asm alias not works for luajit symbol search
-- and also emurate __has_include_next directive
-- TODO : implement __has_include_next in correct way
ffi.cdef [[
	#define __asm(exp)
]]
return ffi
