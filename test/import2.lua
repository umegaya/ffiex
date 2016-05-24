local ffi = require 'ffiex.init'

ffi.path "/usr/local/include/luajit-2.0"
if ffi.os == 'OSX' then
	-- disable all __asm alias (because luajit cannot find aliasing symbols)
	ffi.cdef "#define __asm(exp)"
end
local lib
if ffi.os == "OSX" then
    lib = ffi.C
elseif ffi.os == "Linux" then
    lib = ffi.load("pthread")
else
    error("invalid os: " .. ffi.os)
end
local symbols = {
	--> from pthread
	"pthread_t", "pthread_mutex_t", 
	"pthread_mutex_lock", "pthread_mutex_unlock", 
	"pthread_create", "pthread_join", "pthread_self",
	"pthread_equal", 
	--> from luauxlib, lualib
	"luaL_newstate", "luaL_openlibs",
	"luaL_loadstring", "lua_pcall", "lua_tolstring",
	"lua_getfield", "lua_tointeger",
	"lua_settop", "lua_close", 
	--> from time
	"nanosleep",
}
ffi.import(symbols):from [[
	#include <pthread.h>
	#include <lauxlib.h>
	#include <lualib.h>
	#include <time.h>
]]
for _,sym in ipairs(symbols) do
	if sym:find(".+_t$") then
		local ok,ct = pcall(ffi.typeof, sym)
		assert(ok, sym .. " not found")
	elseif sym:find("^pthread") then
		assert(lib[sym], sym .. " not found")
	else
		assert(ffi.C[sym], sym .. " not found")
	end
end


return true