local ffi = require 'ffiex'
ffi.csrc('test', [[
#include <stdio.h>
extern void test(const char *msg) { print(msg); }
]])
ffi.C.test('csrc test')
