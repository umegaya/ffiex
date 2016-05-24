function try_parse_headers(directory)
    local dir = io.popen('ls '..directory)
    local ffi = require "ffiex.init"
    local blacklist
    if ffi.os == "OSX" then
        blacklist = {
            "cxxabi.h", -- namespace is contained
            "nc_tparm.h", -- TPARM_1 declared twice
            "standards.h", -- deprecated and cannot used
            "tk.h", -- X11/* headers not exist under /usr/include,
            "tkDecls.h", -- same as tk.h
            "tkIntXlibDecls.h", -- same as tk.h
            "tkMacOSX.h", -- same as tk.h
            "ucontext.h", -- The deprecated ucontext routines require _XOPEN_SOURCE to be defined
            "sys/dtrace_impl.h", -- need KERNEL_BUILD and if it specified, libkern/libkern.h is required (but not provided for normal env)
            "sys/ubc.h", -- kern/locks.h is not found and it is not provided 
        }
    elseif ffi.os == "Linux" then
        blacklist = {
            "complex.h", -- luajit itself will support for it
    		"cursesapp.h", "cursesf.h", "cursesm.h", "cursesp.h", "cursesw.h", "cursslk.h", -- c++ file
           	"autosprintf.h", "etip.h", -- c++ file
            "link.h", -- missing Elf__ELF_NATIVE_CLASS_Addr
    	    "dialog.h", "dlg_colors.h", "dlg_keys.h", -- refer ncurses/ncurses.h even if its not installed (dlg_config.h wrongly says it is exists)
            "driver.h", -- symbolic link to /usr/lib/erlang/user/include/driver.h but only /usr/lib/erlang/user/include/erl_driver.h exists.
            "erl_nif_api_funcs.h", --  This file should not be included directly (error in header itself)
            "FlexLexer.h", -- c++ header
            "ft2build.h", -- try to include <freetype/config/fthreader.h> but only have freetype2 directory under /usr/include
        	"pcre_stringpiece.h", "pcre_scanner.h", "pcrecpp.h", "pcrecpparg.h", -- c++ header
        	"png.h", -- png_structppng_ptr not exist. I think that is typo of "png_structp png_ptr"
        	"turbojpeg.h", -- luajit cdef cannot process static const int []
    		"db_cxx.h", -- c++ header
            "gmpxx.h", -- c++ header
            "t1libx.h",
	}
    end
    while true do
        local file = dir:read()
        local basename = file
        if not file then break end
        local subdir = directory:gsub('/usr/include/', '')
        if #subdir > 0 then
            file = (subdir .. '/' .. file)
        end
        -- no arg or arg[1] is this file => full test mode otherwise single file test mode (specify some header name)
    	if not arg[1] or (arg[1] == file) or (arg[1] == 'test/parseheaders.lua') then
        	if basename:find('^[^_]+.*%.h$') then
                -- print('code:', ('(require "ffiex.init").cdef "#include <%s>"'):format(file))
                local black
                if blacklist then
                    for _,fn in ipairs(blacklist) do
                        if fn == file then
                            black = true
                        end
                    end
                end
                if not black then
                    print('try parse:' .. file)

                    local ok, r = pcall(os.execute, ('luajit test/parser.lua_ %s'):format(file))
                    --local ok, r = pcall(loadstring, ('(require "ffiex.init").cdef "#include <%s>"'):format(file))
                    if ok and r == 0 then
                    else
                        print('parse fails:' .. file .. '|' .. tostring(r))
                        os.exit(-2)
                    end
                end
            else
                print('not test:' .. file)
            end
    	end
    end
end

try_parse_headers('/usr/include/arpa')
try_parse_headers('/usr/include/netinet')
try_parse_headers('/usr/include/sys')
try_parse_headers('/usr/include/')


print('test finished')

return true
