local dir = io.popen('ls test')
while true do
	local file = dir:read()
	if not file then break end
	file = ('test/' .. file)
	if file:find('%.lua$') then
		print('----------- test: '..file)
		local ok, r = pcall(os.execute, "luajit launch.lua "..file)
		if ok and r then
			if r ~= 0 then
				print('test fails:' .. file .. '|' .. r)
				os.exit(-1)
			end
		else
			print('execute test fails:' .. file .. '|' .. tostring(r))
			os.exit(-2)
		end
	else
		print('----------- not test:' .. file)
	end
end
print('test finished')
