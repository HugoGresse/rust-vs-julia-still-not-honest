#include <iostream>
#include <cstdint>

uint64_t fib(unsigned int n) {
    if (n == 1 || n == 2) {
        return 1;
    }
    
    uint64_t a = 1;
    uint64_t b = 1;
    
    for (unsigned int i = 3; i <= n; i++) {
        uint64_t next = a + b;
        a = b;
        b = next;
    }
    
    return b;
}

int main() {
    uint64_t val = fib(60);
    std::cout << val << std::endl;
    return 0;
} 