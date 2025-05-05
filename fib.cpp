#include <iostream>
#include <cstdint>
#include <cstdlib>

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

int main(int argc, char* argv[]) {
    // Parse command line arguments
    unsigned int n = (argc > 1) ? static_cast<unsigned int>(std::atoi(argv[1])) : 60;
    unsigned int runs = (argc > 2) ? static_cast<unsigned int>(std::atoi(argv[2])) : 1;
    
    // Internal benchmarking loop
    uint64_t result = 0;
    for (unsigned int i = 0; i < runs; i++) {
        result = fib(n);
    }
    
    // Print the result
    std::cout << result << std::endl;
    return 0;
} 