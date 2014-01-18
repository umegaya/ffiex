local ffi = require 'ffiex.init'

local lib,ext = ffi.csrc('test', [[
#include <stdlib.h>
#include <stdio.h>
#define MYID (101)
extern void hello_csrc(int id, char *buffer) {
	sprintf(buffer, "id:%d", id);
}
]])

local msg = ffi.new("char[256]")
lib.hello_csrc(ffi.defs.MYID, msg)
assert("id:101" == ffi.string(msg));

os.remove('./test.so')
