local lcpp = require 'ffiex.lcpp'
local originalCompileFile = lcpp.compileFile
local searchPath = {"./"}

lcpp.compileFile = function (filename, predefines, macro_sources, nxt, _local)
	local lastTryPath = predefines.__FILE__:gsub('^(.*/)[^/]+$', '%1')
	if nxt then
		local process
		for _,path in ipairs(searchPath) do
			if process then
				local trypath = (path .. filename)
				local ok, r = pcall(io.open, trypath, 'r')
				if ok and r then
					r:close()
					filename = trypath
					break
				end
			elseif path == lastTryPath then
				process = true
			end
		end
	else
		local found 
		if _local then
			local trypath = (lastTryPath .. filename)
			local ok, r = pcall(io.open, trypath, 'r')
			if ok and r then
				r:close()
				filename = trypath
				found = true
			end
		end
		if not found then
			for _,path in ipairs(searchPath) do
				local trypath = (path .. filename)
				local ok, r = pcall(io.open, trypath, 'r')
				if ok and r then
					r:close()
					filename = trypath
					break
				end
			end
		end
	end
	-- print('file found:' .. filename)
	return originalCompileFile(filename, predefines, macro_sources, nxt)
end
local ffi = require 'ffi'
ffi.exconf = {}
ffi.path = function (path)
	if path[#path] ~= '/' then
		path = (path .. '/')
	end
	table.insert(searchPath, path)
end
ffi.search = function (path, file, add)
	local p = io.popen(('find %s -name %s'):format(path, file), 'r')
	if not p then return nil end
	local line
	while true do
		line = p:read('*l')
		if not line then
			break -- eof
		else
			-- if matches find:, log of find itself. 
			if (not line:match('^find:')) and line:match((file .. '$')) then
				break
			end
		end
	end
	if line and add then
		--print('find path and add to header path:' .. line .. "|" .. line:gsub('^(.*/)[^/]+$', '%1'))
		ffi.path(line:gsub('^(.*/)[^/]+$', '%1'))
	end
	return line
end
ffi.define = function (defs)
	for k,v in pairs(defs) do
		ffi.lcpp_defs[k] = v
	end
end
ffi.undef = function (defs)
	for i,def in ipairs(defs) do
		ffi.lcpp_defs[def] = nil
	end
end
local function toluaFunc(macro_source)
	return function (...)
		local args = {...}
		local src = "return " .. macro_source:gsub("%$(%d+)", function (m) return args[tonumber(m)] end)
		local ok, r = pcall(loadstring, src)
		if not ok then error(r) end
		return r()
	end
end
ffi.defs = setmetatable({}, {
	__index = function (t, k)
		local def = ffi.lcpp_defs[k]
		if type(def) == 'string' then
			local ok, r = pcall(loadstring, "return " .. def)
			if ok and r then 
				t[k] = r()
				return  t[k]
			end
		elseif type(def) == 'function' then
			def = ffi.lcpp_macro_sources[k]
			if not def then return nil end
			def = toluaFunc(def)
		end
		t[k] = def
		return def
	end
})

local generate_cdefs = function (code)
	-- matching extern%s+[symbol]%s+[symbol]%b()
	local current = 0
	local decl = ""
	repeat
		local _, offset = string.find(code, '\n', current+1, true)
		local line = code:sub(current+1, offset)
		-- matching simple function declaration (e.g. void foo(t1 a1, t2 a2))
		local _, count = line:gsub('^%s*([_%a][_%w]*%s+[_%a][_%w]*%b()).*', function (s)
			--print(s)
			decl = (decl .. "extern " .. s .. ";\n")
		end)
		-- matching function declaration with access specifier 
		-- (e.g. extern void foo(t1 a1, t2 a2), static void bar())
		-- and not export function declaration contains 'static' specifier
		if count <= 0 then
			line:gsub('(.*)%s+([_%a][_%w]*%s+[_%a][_%w]*%b()).*', function (s1, s2)
				--print(s1 .. "|" .. s2)
				if not s1:find('static') then
					decl = (decl .. "extern " .. s2 .. ";\n")
				end
			end)
		end
		current = offset
	until not current
	if #decl > 0 then
		-- print('decl = ' .. decl)
		ffi.cdef(decl)
	end
end


-- callback for creating so file cache
-- src_name : first argument of csrc. mainly used for distinguish each code
-- code : actual content of code. mainly used for calculating checksum
-- file : if 2nd parameter given to ffi.csrc, .lua file that calls csrc. otherwise same as src_name
-- so : built .so filename. if not nil, you should cache it somewhere if you want, 
-- 		bacaue after calling this function, its removed.
-- 		otherwise you return so file name path correspond to src_name and code.
ffi.exconf.cacher = function (src_name, code, file, so)
	-->print(so, src, is_tmp, luafile, lualine)
end

local call_cacher = function (src_name, code, is_tmp, so)
	if is_tmp then
		local stack,current = debug.traceback(),0
		local file,ln
		-- parse output of debug.traceback()
		-- TODO : need to track the spec change of debug.traceback()
		repeat
			local _, offset = string.find(stack, '\n', current+1, true)
			local line = stack:sub(current+1, offset)
			local res, count = line:gsub('%s*([^%s:]+):([%d]+).*', function (s1, s2)
				file, line = s1, s2
			end)
			if count > 0 and (not file:find('ffiex/init.lua')) then
				break
			end
			current = offset
		until not current
		ffi.exconf.cacher(src_name, code, file, so)
	else
		ffi.exconf.cacher(src_name, code, src_name, so)
	end
end

local build = function (name, code)
	local opts = table.concat((ffi.opts or {"-fPIC"}), " ") .. " -I" .. table.concat(searchPath, " -I")
	local obase,sbase = os.tmpname(),nil
	local obj = obase .. '.so'
	local src,is_tmp
	if code then
		sbase = os.tmpname()
		src,is_tmp = sbase..'.c',true

		local f = io.open(src, 'w')
		f:write(code)
		f:close()
	else
		src = name
		local f = io.open(name, 'r')
		code = f:read('*a')
		f:close()
	end
	local path_from_cache = call_cacher(name, code, is_tmp)
	if path_from_cache then return path_from_cache,"read from cache" end
	-- dummy compile to inject macro definition for external use
	ffi.cdef(code)
	-- generate cdefs from source code
	generate_cdefs(code)
	-- compile .so
	local ok, r = pcall(os.execute, ('gcc -shared -o %s %s %s'):format(obj, opts, src))
	local ra, rb
	if ok then
		if r ~= 0 then
			ra, rb = nil, r
		else
			ra, rb = obj, out
			call_cacher(name, code, is_tmp, obj)
		end
	else
		ra, rb = nil, r
	end
	if obase then os.remove(obase) end
	if sbase then os.remove(sbase) end
	if is_tmp then os.remove(src) end
	return ra, rb
end
ffi.copt = function (opts)
	local found = false
	for _,opt in ipairs(opts) do
		if opt:find("-fPIC") then
			found = true
		end
	end
	if not found then
		table.insert(opts, "-fPIC")
	end
	ffi.opts = opts
end
ffi.csrc = function (name, src)
	local path,ext = build(name, src)
	if path then
		local lib = ffi.load(path)
		os.remove(path)
		return lib,ext
	else
		return nil,ext
	end
end

-- add compiler predefinition
local add_builtin_defs = function ()
	local p = io.popen('echo | gcc -E -dM -')
	local predefs = p:read('*a')
	ffi.cdef(predefs)
	p:close()
end

-- add compiler built in header search path
local add_builtin_paths = function ()
	local p = io.popen('echo | gcc -xc -v - 2>&1 | cat')
	local search_path_start
	while true do
		-- TODO : that is not stable way to get search paths.
		-- but I cannot find better way than this.
		local line = p:read('*l')
		if not line then break end
		if search_path_start then
			local tmp,cnt = line:gsub('^%s+(.*)', '%1')
			if cnt > 0 then
				ffi.path(tmp:gsub(' %(framework directory%)', ''))
			else
				break
			end
		elseif line:find('#include <...>') then
			search_path_start = true
		end
	end
end

add_builtin_defs()
add_builtin_paths()

for _,path in ipairs(searchPath) do
-- print('searchPath:'..path)
end

-- os dependent tweak
if ffi.os == 'OSX' then
	-- luajit cannot parse objective-C code correctly
	-- e.g.  int      atexit_b(void (^)(void)) ; ^!!
	ffi.undef({"__BLOCKS__"})
	-- i don't know the reason but OSX __asm alias not works for luajit symbol search
	-- and also emurate __has_include_next directive
	ffi.cdef [[
		#define __asm(exp)
		#define __has_include_next(x) 1
	]]
end
return ffi
