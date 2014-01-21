#!/bin/bash
luarocks remove ffiex
luarocks pack ffiex*.rockspec
luarocks unpack ffiex*.src.rock
pushd ffiex*/ffiex
luarocks make 
popd
OUT = `luajit install_test.lua`
rm ffiex*.src.rock
rmdir ffiex* 
if [ "$OUT" -ne "1000" ]
then
   exit -1
fi

