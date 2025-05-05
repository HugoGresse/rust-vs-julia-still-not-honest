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
    val = fib(60)
    print(val)
