local lcpp = require 'ffiex.lcpp'
-- unit test
lcpp.test()
-- other pathological tests
lcpp.compile([[
#ifndef HOGE
struct var {
    void (*__routine)(void *);      // Routine to call
    void *__arg;                    // Argument to pass
    struct __darwin_pthread_handler_rec *__next;
};
#endif // HOGE]])

return true
