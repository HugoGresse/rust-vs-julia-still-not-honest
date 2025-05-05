#include <stdio.h>

unsigned long long fib(unsigned int n) {
    if (n == 1 || n == 2) {
        return 1;
    }
    
    unsigned long long a = 1;
    unsigned long long b = 1;
    
    for (unsigned int i = 3; i <= n; i++) {
        unsigned long long next = a + b;
        a = b;
        b = next;
    }
    
    return b;
}

int main() {
    unsigned long long val = fib(60);
    printf("%llu\n", val);
    return 0;
} 