local tester,err = loadfile('test/ffiex_csrc.lua_')
if tester then
	tester()("gcc", function ()
		if ffi.os == 'Linux' then
			ffi.path("/usr/include/linux", true)
		end
		-- add local path
		ffi.path "./test/myheaders"
		ffi.cdef [[
			#include <sys/stat.h>
			#include <unistd.h>
			#include <sys/syscall.h>
			int stat64(const char *path, struct stat *sb);
		]]
		ffi.cdef "#include <time.h>"

		local ncall = 0
		return {
			cc = "gcc", 
			extra = {"-D_MYDEF", "-D_MYDEF2=101", "-O2", "-Wall"},
			cache_callback = function (name, code, file, search)
				-- print('cacher', name, code, file, search)
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
					assert(file:find('test/foo.c'), "file name wrong:" .. file)
				elseif ncall < 6 then
					assert(name == 'test2', "name wrong:"..name)
					assert(file:find('ffiex.csrc.lua'), "file name wrong:" .. file)
				end
				if (ncall % 2) == 0 then
					assert(search, "search should be true (because search object file from cache)")
				elseif (ncall % 2) == 1 then
					assert(not search, "search should be false (because caching object file mode)")
				end	
				ncall = (ncall + 1)
			end
		}
	end)
else
	print('fail to load tester:', err)
end
return true
