local ffi = require 'ffiex.core'
-- in 0.9.26, only tcc --run is supported for OSX.
if ffi.os == "OSX" then return true end
local tester, err = loadfile('test/ffiex_csrc.lua_')
if tester then
	tester()("tcc", function ()
		ffi.clear_copt()
		ffi.path "./test/myheaders/tcc/"
	end)
else
	print('fail to load tester:'..err)
end

return true
