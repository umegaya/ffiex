local parser = require 'ffiex.parser'

local function check_dependency(sym, typename, deps, cdef_checker)
	typename = parser.name(sym, typename)
	local t = assert(sym[typename], typename .. " not exist")
	for i,d in ipairs(deps) do
		local found
		for j,e in ipairs(t.deps) do
			if d == e then found = true end
		end
		assert(found, typename .. " should depend on "..d)
	end
	if cdef_checker then
		assert(cdef_checker(t.cdef), "dependency correct but has invalid source "..typename)
	end
end

local sym
-- test1
sym = parser.parse(nil, [[
 typedef unsigned int volatile *test1_a_t[16], * * test1_b_t ; 
 typedef unsigned long long register test1_c_t, *test1_d_t ; 
struct test1_e_t { int a; };
 typedef struct test1_e_t test1_e_t;
 typedef int integer_t;
]])
check_dependency(sym, "test1_a_t", {"unsigned int"})
check_dependency(sym, "test1_b_t", {"unsigned int"})
check_dependency(sym, "test1_c_t", {"unsigned long long int"})
check_dependency(sym, "test1_d_t", {"unsigned long long int"})
check_dependency(sym, "struct test1_e_t", {"int"})
check_dependency(sym, "typename test1_e_t", {"struct test1_e_t"})
check_dependency(sym, "integer_t", {"int"})


-- test2
sym = parser.parse(nil, [[
 typedef struct _test2_a_t {
 	long a;
 	void *p[16];
 	char * * ptr;
 } test2_a_t;
 typedef enum _test2_b_t {
 	ENUM1,
 	ENUM2,
 	ENUM3,
 } test2_b_t;
]])
check_dependency(sym, "_test2_a_t", {"long int", "void", "char"})
check_dependency(sym, "test2_a_t", {"struct _test2_a_t"})
check_dependency(sym, "test2_b_t", {"enum _test2_b_t"})


-- test3
sym = parser.parse(nil, [[
 typedef struct {
 	unsigned long a  [ 16 ] [ 32 ];
 	char *p [ 16 ] [ 32 ];
 } test3_a_t;
 typedef enum {
 	ENUM4,
 	ENUM5,
 	ENUM6,
 } test3_b_t;
]])
check_dependency(sym, "test3_a_t", {"unsigned long int", "char"})
check_dependency(sym, "test3_b_t", {})


-- test4
sym = parser.parse(nil, [[
 typedef int (*test4_a_t)(char a, short b, unsigned long c);
 typedef void *test4_b_t(int *b[]), *test4_c_t, (*test4_d_t(char, signed short))(int, long long);
]])
check_dependency(sym, "test4_a_t", {"int", "char", "short int", "unsigned long int"})
check_dependency(sym, "test4_b_t", {"void", "int"})
check_dependency(sym, "test4_c_t", {"void"})
check_dependency(sym, "test4_d_t", {"void", "char", "signed short int", "int", "long long int"})


--test5
sym = parser.parse(nil, [[
typedef struct _test5_a_t {
	void *p;
} test5_a_t;
 extern __attribute__(always_inline, hoge(1, 2)) void test5_a_fn(char a, short b, unsigned long c) __attribute__(noreturn, fastcall);
 static int (test5_b_fn)(char a, int (*)(short b), void *(*)(unsigned long c)) __asm(hoge);
 int *test5_c_fn(struct _test5_a_t *ph1, test5_a_t *ph2);
 __declspec(dllimport) void (*test5_d_fn(int, void (*)(int)))(int);
]])
check_dependency(sym, "func test5_a_fn", {"void", "char", "short int", "unsigned long int"}, function (cdef)
	return cdef:find("__attribute__%(always_inline, hoge%(1, 2%)%)")
end)
check_dependency(sym, "func test5_b_fn", {"int", "char", "short int", "void", "unsigned long int"}, function (cdef)
	return cdef:find("__asm%(hoge%)")
end)
check_dependency(sym, "_test5_a_t", {"void"})
check_dependency(sym, "test5_a_t", {"struct _test5_a_t"})
check_dependency(sym, "func test5_c_fn", {"struct _test5_a_t", "test5_a_t"})
check_dependency(sym, "func test5_d_fn", {"void", "int"}, function (cdef)
	return cdef:find('__declspec%(dllimport%)')
end)


--test6
sym = parser.parse(nil, [[
typedef struct {
	void *p;
	volatile int vn;
} test6_a_t;
struct test6_b_t {
	test6_a_t *p;
	test6_a_t *ap[16];
};

typedef struct {
	test6_a_t a, (*fn)(test6_b_t *, int);
	int x, y, z;
	test6_b_t (*fn2(int, void *(void *)))(char, long);
	struct test6_d_t *pd;

} test6_c_t;
]])
check_dependency(sym, "test6_a_t", {"void", "int"})
check_dependency(sym, "test6_b_t", {"test6_a_t"})
check_dependency(sym, "test6_c_t", {"test6_a_t", "test6_b_t", "int", "char", "long int", "struct test6_d_t"})
check_dependency(sym, "test6_d_t", {})

return true
