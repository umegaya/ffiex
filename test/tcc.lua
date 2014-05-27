local ffi = require 'ffiex.init'
-- in 0.9.26, only tcc --run is supported for OSX.
if ffi.os == "OSX" then return true end
local tester, err = loadfile('test/ffiex_csrc.lua_')
if tester then
	tester()("tcc", function ()
		ffi.clear_copt()
		ffi.path "./test/myheaders/"
		ffi.path "./test/myheaders/tcc/"
		return {
			cc = "tcc", 
			extra = {"-D_MYDEF", "-D_MYDEF2=101", "-O2", "-Wall"},
		}
	end)
else
	print('fail to load tester:'..err)
end

return true
