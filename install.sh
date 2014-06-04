#!/bin/bash
# install luajit from git HEAD

luarocks remove ffiex
luarocks pack ffiex*.rockspec
luarocks unpack ffiex*.src.rock
pushd ffiex*/ffiex
luarocks make 
popd
OUT=`luajit install_test.lua`
if [ "$?" -ne "0" ]; 
then
  echo "test fails"
  exit -2
fi
rm ffiex-*.src.rock
find . -type d -name "ffiex-*" -exec rm -rf {} \;
if [ "$OUT" -ne "1000" ];
then
   exit -1
fi
echo "install success"
