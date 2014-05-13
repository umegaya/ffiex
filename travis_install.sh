#!/bin/bash

CHECK=`luajit -v`
if [ "$CHECK" = "" ];
then 
git clone http://luajit.org/git/luajit-2.0.git
cd luajit-2.0
make && sudo make install
fi
CHECK=`which tcc`
TCC_VERSION=release_0_9_26
if [ "$CHECK" = "" ];
then
pushd tmp
git clone --depth 1 git://repo.or.cz/tinycc.git --branch $TCC_VERSION
pushd tinycc
sudo ./configure && make && make install
popd
popd
fi

