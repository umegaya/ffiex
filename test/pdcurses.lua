local ffi = require 'ffiex.init'

local state = ffi.newstate()
-- ffi need to configure for loading tcc header and lib
ffi.path "./test/myheaders/tcc"
state:copt { cc = "tcc" }
state:cdef [[
//complement missing definition
#if !defined(__SIZE_TYPE__)
#define __SIZE_TYPE__ size_t
#endif
#if !defined(__PTRDIFF_TYPE__)
#define __PTRDIFF_TYPE__ ptrdiff_t
#endif
#if !defined(__WINT_TYPE__)
#define __WINT_TYPE__ wchar_t
#endif
#if !defined(__WCHAR_TYPE__)
#define __WCHAR_TYPE__ wchar_t
#endif
]]
state:cdef [[
#if(HOGE)
#define FOO ("foo")
#else
#define FOO ("bar")
#endif

#ifndef(FUGA)
#define BAR ("bar")
#else
#define BAR ("foo")
#endif

#ifdef(ZZZ)
#define BAZ ("baz")
#else
#define BAZ ("bazbaz")
#endif
]]

print(state.defs.FOO, state.defs.BAR, state.defs.BAZ)
assert(state.defs.FOO == "bar", state.defs.FOO)
assert(state.defs.BAR == "bar", state.defs.BAR)
assert(state.defs.BAZ == "bazbaz", state.defs.BAZ)

state:path "./test/myheaders"
state:path "./test/myheaders/tcc"
state:cdef [[ #include "pdcurses.h" ]]

assert(state.defs.CHTYPE_LONG == 2)

return true
