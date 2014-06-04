local ffi = require 'ffiex.init'
local lib,ext = ffi.csrc('test', [[
#include <stdio.h>
extern void test(int id) { printf("%d", id); }
]])
lib.test(1000)
