local dir = io.popen('ls /usr/include/')
local ffi = require "ffiex.init"
local blacklist
if ffi.os == "OSX" then
	ffi.cdef "#define XP_NO_X_HEADERS"
        ffi.search("/Applications/Xcode.app/Contents/Developer/usr", "stdarg.h", true)
        blacklist = {
                "cxxabi.h", -- namespace is contained
                "nc_tparm.h", -- TPARM_1 declared twice
                "standards.h", -- deprecated and cannot used
                "tk.h", -- X11/* headers not exist under /usr/include,
                "tkDecls.h", -- same as tk.h
                "tkIntXlibDecls.h", -- same as tk.h
                "tkMacOSX.h", -- same as tk.h
                "ucontext.h", -- The deprecated ucontext routines require _XOPEN_SOURCE to be defined
        }
elseif ffi.os == "Linux" then
    blacklist = {
        "complex.h", -- luajit itself will support for it
		"cursesapp.h", "cursesf.h", "cursesm.h", "cursesp.h", "cursesw.h", "cursslk.h", -- c++ file
       	"autosprintf.h", "etip.h", -- c++ file
        "link.h", -- missing Elf__ELF_NATIVE_CLASS_Addr
	"dialog.h", "dlg_colors.h", "dlg_keys.h", -- refer ncurses/ncurses.h even if its not installed (dlg_config.h wrongly says it is exists)
	}
end
arg[1] = "driver.h"
while true do
    local file = dir:read()
    if not file then break end
	if not arg[1] or (arg[1] == file) then
    	if file:find('^[^_]+.*%.h$') then
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
print('test finished')
