#include <iostream>

uint64_t fib(uint32_t n) {
    if (n == 1 || n == 2) {
        return 1;
    }
    
    uint64_t a = 1;
    uint64_t b = 1;
    
    for (uint32_t i = 3; i <= n; i++) {
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