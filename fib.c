#include <stdio.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdlib.h>

// Simple Fibonacci implementation using uint64_t
// Note: This will overflow for n > 93
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

int main(int argc, char *argv[]) {
    // Parse command line arguments
    unsigned int n = (argc > 1) ? (unsigned int)atoi(argv[1]) : 60;
    unsigned int runs = (argc > 2) ? (unsigned int)atoi(argv[2]) : 1;
    
    // Internal benchmarking loop
    uint64_t result = 0;
    for (unsigned int i = 0; i < runs; i++) {
        result = fib(n);
    }
    
    // Redirect stderr to /dev/null to prevent interference with benchmark's time output
    freopen("/dev/null", "w", stderr);
    
    // Print only the number with no extra text or newlines, as the benchmark expects
    printf("%" PRIu64 "\n", result);
    
    // Ensure output is flushed
    fflush(stdout);
    return 0;
} 