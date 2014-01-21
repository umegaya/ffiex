local dir = io.popen('ls test')
while true do
	local file = dir:read()
	if not file then break end
	file = ('test/' .. file)
	if file:find('%.lua') then
		local ok, r = pcall(loadfile, file)
		if ok and r then
			print('run test:' .. file)
			ok, r = pcall(r)
			if not ok then
				print('test fails:' .. file .. '|' .. r)
				os.exit(-1)
			end
		else
			print('init test fails:' .. file .. '|' .. tostring(r))
			os.exit(-2)
		end
	else
		print('not test:' .. file)
	end
end
print('test finished')
