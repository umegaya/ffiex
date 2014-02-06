ffiex
=====

extend luajit ffi module to give more affinity to C codes


APIs
=======

### ffiex.cdef(input:string)
 same as original ffi.cdef but it apply C preprocessor to input text, yes, the concept is almost same as lcpp (https://github.com/willsteel/lcpp), but do more. lcpp have some flaw when its used for parsing practical header like under /usr/include/, lcpp used in ffiex is re-written widely so that it able to parse header files under /usr/include/*.h  (I will test with OSX 10.9, CentOS 6.4, Ubuntu 12.04(travis-CI).

### ffiex.path(path:string)
 add header file search path which is used to find #include files by ffiex.cdef. ffiex initializes system header search path and pre-defined macro symbols from following commands
 ```
 echo | gcc -v -xc - # search paths
 echo | gcc -E -dM - # predefined macros
 ```
 so you don't need to specify system header search path in gcc-enabled environment. but if gcc-less or need to add search path for your original header files, you can add other search paths by this.

### path = ffiex.search(path:string, filename:string, add:boolean)
 find *filename* under *path* and return found path. 
if *filename* is found && *add* is true, call ffiex.path to add searched path.
 it may useful to increase portability when you need to include header which is placed to path like  /usr/include/libfoo/1.2.1/foo.h and the part *1.2.1* is vary from users environment.
 
### clib,err = ffiex.csrc(name:string, input:string)
 if input is nil, regard name as c source file and compile it, ffi.load it, return clib object. otherwise return nil and compile error output err. when compiling, ffiex uses gcc command with the given build option from ffiex.copt and header file paths specified with ffiex.path. if input is string, then name is used as source code name. 
 
### ffiex.copt(opts:table)
 put C compile option which is used by ffiex.csrc



License
=======

apache v2 (http://www.apache.org/licenses/LICENSE-2.0)
