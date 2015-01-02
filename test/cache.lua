local ffi = require 'ffiex.init'
local util = require 'ffiex.util'

ffi.init_cdef_cache()
local v, d, p = io.open(util.path.version_file):read('*a'),
	io.open(util.path.builtin_defs):read('*a'),
	io.open(util.path.builtin_paths):read('*a')
ffi.clear_cdef_cache()
assert(v == util.gcc_version())
assert(d == util.builtin_defs():read('*a'))

return true