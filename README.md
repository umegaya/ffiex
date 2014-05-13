[![Build Status](https://travis-ci.org/umegaya/ffiex.png?branch=master)](https://travis-ci.org/umegaya/ffiex)

ffiex
=====

- extend luajit ffi module to give more affinity to C codes
 - can #include typical system C headers (no more manual C definition injection)
 - enable to use C sources without pre-build it.

install
=======

- prerequisity
 - gcc
- clone this repo and run
``` bash
sudo bash install.sh
```
- or you can use [*moonrocks*](http://rocks.moonscript.org/)
``` bash
  moonrocks install ffiex
```


usage
=====

- just replace 1 line where you use luajit ffi module. 
``` lua
 local ffi = requie 'ffiex'
```


APIs
====

### ffiex.cdef(input:string)
- same as original ffi.cdef but it apply C preprocessor to input text. yes, not only concept but also source code is based on lcpp (https://github.com/willsteel/lcpp), but do more. lcpp have some flaw when its used for parsing practical header like under /usr/include/, lcpp.lua used in ffiex is originally from lcpp project, but re-written widely so that it able to parse most of header files under /usr/include/*.h  (see test/parseheaders.lua. its tested with OSX 10.9, CentOS 6.4, Ubuntu 12.04(travis-CI)).

### ffiex.path(path:string, system_path:boolean)
- add header file search path which is used to find #include files by ffiex.cdef. ffiex initializes system header search path and pre-defined macro symbols from following commands
 
``` bash
 echo | gcc -v -xc - # search paths
 echo | gcc -E -dM - # predefined macros
```
 
- so you don't need to specify system header search path in gcc-enabled environment. but if gcc-less or need to add search path for your original header files, you can add other search paths like following:
``` lua
 ffi.path("/usr/local/additional_system_headers/", true) -- system header
 ffi.path "./your/local/header_file_directory/" -- your local header
```
- note: only the path with system_path == false passed to ffiex.csrc's compiler option (-I).

### define:number|string|funciton = ffiex.defs.{TABLE_KEY}
- get corresponding value (number/string) for macro definition or lua function that do same things as functional macro, which name is of macro {TABLE_KEY}.
- it cannot process some C system header macro for keeping backword compatibility (like errno or struct stat.st_atime).
because it will replace the ctype's symbol access... (like stat.st_atime => stat.st_atimespec.tv_sec)

### ffiex.undef(macro_names:table)
- undef specified macro from lcpp cache.
- *macro_name* should be table which has numerical key and string value for keys
``` lua
 -- example, undef 2 macro symbols
 ffi.undef { "MYDEF", "MYDEF2" } 
```
 
### path:string = ffiex.search(path:string, filename:string, add:boolean)
- find *filename* under *path* and return found path. 
- if *filename* is found && *add* is true, call ffiex.path to add searched path.
- it may useful to increase portability when you need to include header which is placed to path like  /usr/include/libfoo/1.2.1/foo.h and the part *1.2.1* is vary from users environment.
 
### lib:clib,err:string = ffiex.csrc(name:string, input:string)
- embed c source file into lua code. 
- ffi.csrc regards *input* as c source string and try to compile and ffi.load it, then return *lib*, which is clib object corresponding to compiled result (see test/ffiex.csrc.lua for example). otherwise return nil and compile error output *err*. if input is omitted, then name is regared as c source file path. 
- input to csrc is parsed by ffiex.lcpp, so all macro declared in input, is accesible from lua code via ffi.defs.{MACRO_NAME}. for this purpose, -D option for ffiex.copt is autometically injected to ffiex.lcpp itself.
- only function symbol which has no static qualifier, will be exported to clib object.
 
### ffiex.copt(opts:table)
- put C compile option which is used by ffiex.csrc. mutiple call of ffiex.copt overwrites previous options. 
``` lua
 -- example, apply -O2, -Wall, 2 pre-defined macro for input of ffiex.csrc
 ffi.copt {
    extra = {"-D_MYDEF", "-D_MYDEF2=101", "-O2", "-Wall"}
 }
 -- still you can use old style option
 ffi.copt {"-D_MYDEF", "-D_MYDEF2=101", "-O2", "-Wall"}
```
fully opts format is like following
``` lua
options = {
		path = {
			include = { path1, path2, ... },
			sys_include = { syspath1, syspath2, ... },
			lib = { libpath1, libpath2, ... }
		},
		lib = { libname1, libname2, ... },
		extra = { opt1, opt2, ... },
		define = { booldef1, booldef2, ... def1 = val1, def2 = val2 }
	}
```

 
 
Improvement
===========

- able to run on gcc-less environment. I already make some preparation like *ffiex.exconf.cacher* to cache built so files on host side (which should have proper gcc toolchain), but has no good idea for bundling them to final executables yet (for example, into apk or ipa)
- reduce memory footprint. because current ffiex import all symbols in #include'd header file, so even unnecessary cdefs all exists on memory. one idea is specify required type or function definition like below.
``` lua
-- it only import cdefs which relate with fopen (thus, FILE related ones)
ffiex.include("stdio.h",{"fopen"})
```


License
=======

apache v2 (http://www.apache.org/licenses/LICENSE-2.0)
