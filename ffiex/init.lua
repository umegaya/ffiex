local lcpp = require 'ffiex.lcpp'
local originalCompileFile = lcpp.compileFile
local searchPath = {"./", "/usr/local/include/", "/usr/include/"}

lcpp.compileFile = function (filename, predefines)
	for _,path in ipairs(searchPath) do
		local trypath = (path .. filename)
		local ok, r = pcall(io.open, trypath, 'r')
		if ok and r then
			r:close()
			filename = trypath
			break
		end
	end
	-- print('file found:' .. filename)
	return originalCompileFile(filename, predefines)
end
local ffi = require 'ffi'
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
			error("currently, functional macro not worked as it should:" .. k)
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
local build = function (name, src)
	local opts = table.concat((ffi.opts or {"-fPIC"}), " ") .. " -I" .. table.concat(searchPath, " -I")
	local obj
	if src then
		-- dummy compile to inject macro definition for external use
		ffi.cdef(src)
		-- generate cdefs from source code
		generate_cdefs(src)
		-- generate so filename/create tmp file to compile
		obj = './' .. name .. '.so'
		name = obj..'.c'
		local f = io.open(name, 'w')
		f:write(src)
		f:close()
	else
		-- dummy compile to inject macro definition for external use
		ffi.cdef(src)
		-- generate cdefs from source code
		local f = io.open(name, 'r')
		generate_cdefs(f:read('*a'))
		f:close()
		-- generate so filename
		obj = './' .. name:gsub('%.c$', '.so')
	end
	local ok, r = pcall(io.popen, ('gcc -shared -o %s %s %s'):format(obj, opts, name))
	if ok then
		local out = r:read('*a')
		if src then
			os.remove(name)
		end		
		return obj,out
	else
		if src then
			os.remove(name)
		end
		return nil, r
	end
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
	local path,err = build(name, src)
	if path then
		return ffi.load(path),err
	else
		error(err)
	end
end

-- add compiler predefinition
local p = io.popen('echo | gcc -E -dM -')
local predefs = p:read('*a')
ffi.cdef(predefs)
p:close()
if ffi.os == 'OSX' then
	-- luajit cannot parse objective-C code correctly
	-- e.g.  int      atexit_b(void (^)(void)) ; ^!!
	ffi.undef({"__BLOCKS__"})
end
return ffi
