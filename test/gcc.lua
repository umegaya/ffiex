local tester,err = loadfile('test/ffiex_csrc.lua_')
if tester then
	tester()("gcc")
else
	print('fail to load tester:', err)
end
return true