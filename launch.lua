local ok, r = pcall(loadfile, arg[1])
if ok and r then
	ok, r = pcall(r)
	if ok and r then
		os.exit(0)
	else
		print('fail to test:'..arg[1], r)
		os.exit(-1)
	end
else
	print('fail to load test:'..arg[1], r)
	os.exit(-2)
end
