def fib(n: int) -> int:
    if not isinstance(n, int) or n <= 0:
        raise ValueError("Input must be a positive integer")
    if n == 1 or n == 2:
        return 1
        
    a, b = 1, 1
    for _ in range(3, n + 1):
        a, b = b, a + b
    return b

if __name__ == "__main__":
    import sys
    
    # Parse command line arguments
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 60
    runs = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    
    # Internal benchmarking loop
    result = None
    for _ in range(runs):
        result = fib(n)
    
    # Only print the result once
    print(result)
