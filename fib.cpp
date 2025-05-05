#include <iostream>
#include <cstdint>

#ifdef HAVE_BOOST
#include <boost/multiprecision/cpp_int.hpp>
using namespace boost::multiprecision;
using big_int = cpp_int;
#else
// Fallback to uint64_t when Boost is not available
using big_int = uint64_t;
#endif

big_int fib(unsigned int n) {
    if (n == 1 || n == 2) {
        return 1;
    }
    
    big_int a = 1;
    big_int b = 1;
    
    for (unsigned int i = 3; i <= n; i++) {
        big_int next = a + b;
        a = b;
        b = next;
    }
    
    return b;
}

int main() {
    big_int val = fib(60);
    std::cout << val << std::endl;
    return 0;
} 