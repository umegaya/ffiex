#!/bin/bash

CHECK=`luajit -v`
if [ "$CHECK" = "" ];
then 
pushd tmp
git clone http://luajit.org/git/luajit-2.0.git
pushd luajit-2.0
make && sudo make install
popd
popd
fi
CHECK=`which tcc`
TCC_VERSION=release_0_9_26
TCC_LIB=libtcc.so
TCC_LIB_NAME=$TCC_LIB.1.0
if [ "$CHECK" = "" ];
then
pushd tmp
git clone --depth 1 git://repo.or.cz/tinycc.git --branch $TCC_VERSION
pushd tinycc
sudo ./configure && make DISABLE_STATIC=1 && make install
sudo cp $TCC_LIB_NAME /usr/local/lib/
sudo ln -s /usr/local/lib/$TCC_LIB_NAME /usr/local/lib/$TCC_LIB
sudo sh -c "echo '/usr/local/lib' > /etc/ld.so.conf.d/tcc.conf"
sudo ldconfig
popd
popd
fi

