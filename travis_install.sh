#!/bin/bash

CHECK=`luajit -v`
if [ "$CHECK" = "" ];
then 
git clone http://luajit.org/git/luajit-2.0.git
cd luajit-2.0
make && sudo make install
fi
