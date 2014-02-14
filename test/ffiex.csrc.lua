local ffi = require 'ffiex.init'
if ffi.os == 'Linux' then
	ffi.path("/usr/include/linux", true)
end
-- add local path
ffi.path "./test/myheaders"
ffi.cdef[[
	#include <sys/stat.h>
	#include <unistd.h>
	#include <sys/syscall.h>
	int stat64(const char *path, struct stat *sb);
]]
ffi.cdef "#include <time.h>"

local ncall = 0
ffi.exconf.cacher = function (name, code, file, so)
	--print('cacher', name, code, file, so)
	local st = ffi.new('struct stat[1]')
	if ffi.os == "OSX" then
		assert(0 == ffi.C.syscall(ffi.defs.SYS_stat64, file, st), "stat call fails")
		print(file..':modified@'..tostring(st[0].st_size).."|"..tostring(st[0].st_mtimespec.tv_sec))
	elseif ffi.os == "Linux" then
		assert(0 == ffi.C.syscall(ffi.defs.SYS_stat, file, st), "stat call fails")
		print(file..':modified@'..tostring(st[0].st_size).."|"..tostring(st[0].st_mtim.tv_sec))
	else
		assert(false, 'unsupported os:'..ffi.os)
	end
	if ncall < 2 then
		assert(name == 'test')
		assert(file:find('ffiex.csrc.lua'), "file name wrong:" .. file)
	elseif ncall < 4 then
		assert(name == './test/foo.c')
		assert(file:find('test/foo.c'), "filez name wrong:" .. file)
	elseif ncall < 6 then
		assert(name == 'test2')		
		assert(file:find('ffiex.csrc.lua'), "file name wrong:" .. file)
	end
	if (ncall % 2) == 0 then
		assert(not so, "so should be nil (because returning so file path mode)")
	elseif (ncall % 2) == 1 then
		assert(so, "so should not be nil (because caching so file mode)")
	end	
	ncall = (ncall + 1)
end
local lib,ext = ffi.csrc('test', [[
#include <stdio.h>
#include <stdlib.h>
#include "my.h"
#define MYID (101)
#define GEN_ID(x, y) (x + y)
extern void hello_csrc(int id, char *buffer) { sprintf(buffer, "id:%d", id); }
void export(int id) { printf("%d", id); }
static inline void not_export(int id) { 
	printf("it should not export"); 
}
]])

local msg = ffi.new("char[256]")
lib.hello_csrc(ffi.defs.MYID, msg)
print(ffi.defs.MYID)
assert("id:101" == ffi.string(msg));
lib.hello_csrc(ffi.defs.GEN_ID(10, 20), msg)
assert("id:30" == ffi.string(msg));
lib.hello_csrc(ffi.defs.MY_MACRO(2), msg)
assert("id:246" == ffi.string(msg));
assert(lib.export);
local ok, r = pcall(function ()
	return lib.not_export(100)
end)
assert(not ok);

os.remove('./test.so')


local lib2,ext2 = ffi.csrc('./test/foo.c')
assert(lib2.footest(ffi.defs.FOO_ID) == (777 * 2))



local lib3,ext3 = ffi.csrc('test2', [[
void bar(int id) { return id }
]])

assert(not lib3, "should be nil due to compile error")
