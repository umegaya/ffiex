package = "ffiex"
version = "0.1.0-1"
source = {
  url = "git://github.com/umegaya/ffiex.git",
}
description = {
  summary = "extend luajit ffi module to give more affinity to C codes",
  detailed = [[
    - extend cdef to parse macro and headers includes
    - search and add header file path as usual C compiler
    - ffi.csrc to add small C source to lua code
    - macro can share between codes in cdef/csrc and lua (except functional macro :P)
  ]],
  homepage = "https://github.com/umegaya/ffiex",
  license = "Apache v2"
}
dependencies = {
  "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    ["ffiex"] = "ffiex/init.lua",
    ["ffiex.lcpp"] = "ffiex/lcpp.lua",
  },
  install = {
    lua = { 
      ["ffiex"] = "ffiex/init.lua",
      ["ffiex.lcpp"] = "ffiex/lcpp.lua",
    }
  }
}
