local lcpp = require 'ffiex.lcpp'
local originalCompileFile = lcpp.compileFile
local searchPath = {"./"}
local localSearchPath = {}
local systemSearchPath = {}
local lastTryPath

local function search_header_file(filename, predefines, nxt, _local)
	lastTryPath = lastTryPath or predefines.__FILE__:gsub('^(.*/)[^/]+$', '%1')
	if nxt then
		local process
		for _,path in ipairs(searchPath) do
			if process then
				-- print("search_header_file:", filename, path, lastTryPath)
				local trypath = (path .. filename)
				local ok, r = pcall(io.open, trypath, 'r')
				if ok and r then
					-- print('return trypath:'..trypath)
					r:close()
					return trypath, trypath:gsub('^(.*/)[^/]+$', '%1')
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
				return trypath, lastTryPath
			end
		end
		if not found then
			for _,path in ipairs(searchPath) do
--print('try:'..path)
				local trypath = (path .. filename)
				local ok, r = pcall(io.open, trypath, 'r')
				if ok and r then
					r:close()
					return trypath, trypath:gsub('^(.*/)[^/]+$', '%1')
				end
			end
		end
	end
	print('not found:' .. filename)
	return nil
end

lcpp.compileFile = function (filename, predefines, macro_sources, nxt, _local)
	filename, lastTryPath = search_header_file(filename, predefines, nxt, _local)
	return originalCompileFile(filename, predefines, macro_sources, nxt)
end

local header_name = "__has_include_next%(%s*[\"<]+(.*)[\">]+%s*%)"
local function has_include_next(decl)
	local file = decl:match(header_name)
	-- print("has_include_next:", file, decl)
	return search_header_file(file, ffi.lcpp_defs, true, false) ~= nil and "1" or "0"
end

local ffi = require 'ffi'
ffi.path = function (path, system)
	if path[#path] ~= '/' then
		path = (path .. '/')
	end
	table.insert(searchPath, path)
	if system then
		table.insert(systemSearchPath, path)
	else
		-- print("add localSerchPath:" .. path)
		table.insert(localSearchPath, path)
	end
end

function replace_table(src, rep)
	for k,v in pairs(src) do
		src[k] = rep[k]
	end
	for k,v in pairs(rep) do
		src[k] = rep[k]
	end
end
ffi.clear_paths = function (system)
	local tmp = {}
	local removed = system and systemSearchPath or localSearchPath
	for _,s in ipairs(searchPath) do
		local found
		for _,t in ipairs(removed) do
			if s == t then
				found = true
			end
		end
		if not found then
			table.insert(tmp, s)
		end
	end
	replace_table(searchPath, tmp)
	if system then
		replace_table(systemSearchPath, {})
	else
		replace_table(localSearchPath, {})
	end
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
		if type(def) == 'number' then
			local ok, r = pcall(loadstring, "return " .. def)
			if ok and r then 
				rawset(t, k, r())
				return rawget(t, k)
			end
		elseif type(def) == 'string' then
			local state = lcpp.init('', ffi.lcpp_defs, ffi.lcpp_macro_sources)
			local expr = state:parseExpr(def)
			rawset(t, k, expr)
			return rawget(t, k)
		elseif type(def) == 'function' then
			def = ffi.lcpp_macro_sources[k]
			if not def then return nil end
			def = toluaFunc(def)
		end
		rawset(t, k, def)
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

-- compiler object (tcc/gcc is natively supported)
local build = function (name, code)
	-- load source code
	if not code then
		local f = io.open(name, 'r')
		code = f:read('*a')
		f:close()
	end
	-- dummy preprocess to inject macro definition for external use
	ffi.cdef(code)
	-- generate cdefs from source code
	generate_cdefs(code)
	return ffi.builder:build(code)
end
ffi.clear_copt = function ()
	local builder = ffi.builder
	if not builder or not builder:get_option() then
		return
	end
	local undefs = {}
	if builder:get_option().define then
		for k,v in pairs(builder:get_option().define) do
			table.insert(undefs, type(k) == 'number' and v or k)
		end
	end
	if builder:get_option().extra then
		for _,o in ipairs(builder:get_option().extra) do
			local def,val = o:match("-D([_%w]+)=?(.*)")
			if def then table.insert(undefs, def) end
 		end
 	end
 	ffi.undef(undefs)
 	if builder then
		builder:exit()
	end
	ffi.builder = nil
end
local parse_stack = function ()
	local stack,current = debug.traceback(),0
	local ret = {}
	-- parse output of debug.traceback()
	-- TODO : need to track the spec change of debug.traceback()
	repeat
		local _, offset = string.find(stack, '\n', current+1, true)
		local line = stack:sub(current+1, offset)
		local res, count = line:gsub('%s*([^%s:]+):([%d]+).*', function (s1, s2)
			table.insert(ret, {file = s1, line = s2})
		end)
		current = offset
	until not current
	return ret
end
local get_decl_file = function (name, src, depth)
	if not src then -- means external .c file specified with 'name'
		return name
	end
	local traces = parse_stack()
	depth = (depth or 1)
	for _,tr in ipairs(traces) do
		if not tr.file:find('ffiex/core.lua') then
			depth = (depth - 1)
		end
		if depth <= 0 then
			return tr.file
		end
	end
	return nil 
end
ffi.copt = function (opts)
	if opts[1] and (not opts.extra) then
		opts = { extra = opts }
	end
	ffi.clear_copt()
	local defs = {}
	local builder
	if opts.cc then
		if type(opts.cc) == 'string' then
			builder = require ('ffiex.builder.'..opts.cc)
		elseif type(opts.cc) == 'table' then
			builder = opts.cc
		else
			error("invalid cc:" .. type(opts.cc))
		end
		if builder then
			builder:init()
			ffi.builder = builder
		end
	else
		error("ffi.copt: opts.cc must be specified")
	end
	if opts.define then
		for k,v in pairs(opts.define) do
			if type(k) == "number" then
				defs[v] = ""
			else
				defs[k] = v
			end
		end
	end
	if opts.extra then
		for _,o in ipairs(opts.extra) do
			local def,val = o:match("-D([_%w]+)=?(.*)")
			if def then
				defs[def] = val
			end
 		end
	end
	ffi.define(defs)
	if not opts.path then
		opts.path = {}
	end
	if type(opts.path.include) ~= 'table' or #opts.path.include <= 0 then
		opts.path.include = localSearchPath
	end
	if type(opts.path.sys_include) ~= 'table' or #opts.path.sys_include <= 0 then
		opts.path.sys_include = systemSearchPath
	end
	if not opts.cache_callback then
		opts.cache_callback = function (name, src, search)
		end
	end
	builder:option(opts)
end
ffi.csrc = function (name, src, opts)
	if opts then
		ffi.copt(opts)
	end
	assert(ffi.builder, "builder not specified. please set opts.cc = 'tcc'/'gcc'/your customized cc table")
	local ext
	local path = ffi.builder:get_option().cache_callback(name, src, get_decl_file(name, src), true)
	if not path then
		path,ext = build(name, src)
	end
	if path then
		local ok, lib = pcall(ffi.load, path)
		if ok and lib then
			ffi.builder:get_option().cache_callback(name, src, get_decl_file(name, src), false)
			-- os.remove(path)
			return lib,ext
		else
			--	os.remove(path)
			return nil,lib
		end
	else
		return nil,ext
	end
end

ffi.lcpp_defs["__has_include_next"] = has_include_next

return ffi
