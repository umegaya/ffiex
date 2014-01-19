local ffi = require 'ffiex.init'

local lib,ext = ffi.csrc('test', [[
#include <stdlib.h>
#include <stdio.h>
#define MYID (101)
extern void hello_csrc(int id, char *buffer) { sprintf(buffer, "id:%d", id); }
void export(int id) { printf("%d", id); }
static inline void not_export(int id) { 
	printf("it should not export"); 
}
]])

local msg = ffi.new("char[256]")
lib.hello_csrc(ffi.defs.MYID, msg)
assert("id:101" == ffi.string(msg));
assert(lib.export);
local ok, r = pcall(function ()
	return lib.not_export(100)
end)
assert(not ok);

os.remove('./test.so')
