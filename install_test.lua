local ffi = require 'ffiex'
ffi.csrc('test', [[
#include <stdio.h>
extern void test(int id) { printf("%d", id); }
]])
ffi.C.test(1000)
