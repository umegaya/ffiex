local ffi = require 'ffiex.init'
ffi.cdef [[
typedef wchar_t wchar2_t;
typedef intptr_t intptr2_t;
typedef uintptr_t uintptr2_t;
typedef ptrdiff_t ptrdiff2_t;
typedef size_t size2_t;
]]

return true
