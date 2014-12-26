local _M = {}
local ffi = require 'ffi'

function _M.get_gcc_version()
	return io.popen('gcc -v'):read('*a')
end
function _M.file_exists(file)
	if ffi.os ~= 'Windows' then
		return io.popen([[if [ -e '%s' ]; then echo '1'; else echo '0'; fi]]):read('*a') == '1'
	else
		error('unsupported OS')
	end
end
function _M.current_path()
	local data = debug.getinfo(1)
	return data.source:match('@(.+)/.+$')
end
local builtin_paths = (_M.current_path()..'/cache/builtin_paths')
local builtin_defs = (_M.current_path()..'/cache/builtin_defs')

-- add compiler predefinition
local builtin_defs_cmd = 'echo | gcc -E -dM -'
local function create_builtin_defs_cache()
	os.execute('echo "'..v..'">'..builtin_defs..".version")
	os.execute(builtin_defs_cmd..'>>'..builtin_defs)
end
local function get_builtin_defs()
	if _M.file_exists(builtin_defs) then
		local v = _M.get_gcc_version()
		if v ~= io.popen(('cat %s'):format(builtin_defs..".version")):read('*a') then
			create_builtin_defs_cache()
		end
		return io.popen(([[cat %s]]):format(builtin_defs))
	end
	return io.popen(builtin_defs_cmd)
end
function _M.add_builtin_defs(state)
	local p = get_builtin_defs()
	local predefs = p:read('*a')
	state:cdef(predefs)
	p:close()
	-- os dependent tweak.
	if ffi.os == 'OSX' then
		-- luajit cannot parse objective-C code correctly
		-- e.g.  int      atexit_b(void (^)(void)) ;
		state:undef({"__BLOCKS__"})
	end
end
function _M.clear_builtin_defs(state)
	local p = io.popen(builtin_defs_cmd)
	local undefs = {}
	while true do 
		local line = p:read('*l')
		if line then
			local tmp,cnt = line:gsub('^#define%s+([_%w]+)%s+.*', '%1')
			if cnt > 0 then
				table.insert(undefs, tmp)
			end
		else
			break
		end
	end
	state:undef(undefs)
	p:close()
end

-- add compiler built in header search path
local builtin_paths_cmd = 'echo | gcc -xc -v - 2>&1 | cat'
function _M.create_builtin_paths_cache()
	local path = _M.current_path()
	local v = _M.get_gcc_version()
	os.execute('echo "'..v..'">'..builtin_paths..".version")
	os.execute(builtin_paths_cmd..'>>'..builtin_paths)
end
local function get_builtin_paths()
	if _M.file_exists(builtin_paths) then
		local v = _M.get_gcc_version()
		if v ~= io.popen(('cat %s'):format(builtin_paths..".version")):read('*a') then
			create_builtin_paths_cache()
		end
		return io.popen(([[cat %s]]):format(builtin_paths))
	end
	return io.popen(builtin_paths_cmd)
end
function _M.add_builtin_paths(state)
	local p = get_builtin_paths()
	local search_path_start
	while true do
		-- TODO : parsing unstructured compiler output.
		-- that is not stable way to get search paths.
		-- but I cannot find better way than this.
		local line = p:read('*l')
		if not line then break end
		-- print('line = ', line)
		if search_path_start then
			local tmp,cnt = line:gsub('^%s+(.*)', '%1')
			if cnt > 0 then
				-- remove unnecessary output of osx clang.
				tmp = tmp:gsub(' %(framework directory%)', '')
				-- print('builtin_paths:'..tmp)
				state:path(tmp, true)
			else
				break
			end
		elseif line:find('#include <...>') then
			search_path_start = true
		end
	end
end
function _M.create_builtin_config_cache()
	create_builtin_paths_cache()
	create_builtin_defs_cache()
end

return _M
