local dir = io.popen('ls /usr/include/')
local ffi = require "ffiex.init"
local blacklist
if ffi.os == "OSX" then
	ffi.cdef "#define XP_NO_X_HEADERS"
        ffi.search("/Applications/Xcode.app/Contents/Developer/usr", "stdarg.h", true)
        blacklist = {"cxxabi.h"}
end
while true do
        local file = dir:read()
        if not file then break end
	if not arg[1] or (arg[1] == file) then
	if file:find('^[^_]+.*%.h$') then
                print('code:', ('(require "ffiex.init").cdef "#include <%s>"'):format(file))
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
                        local ok, r = pcall(os.execute, ('luajit test/parser.lua %s'):format(file))
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
