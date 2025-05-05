function fib(n::Int)
    if n <= 0
        throw(ArgumentError("Input must be a positive integer"))
    elseif n == 1 || n == 2
        return 1
    end
    
    # Use native Int64 for numbers that won't overflow
    if n <= 90  # Fib(90) is the largest that fits in Int64
        a, b = 1, 1
        for _ in 3:n
            a, b = b, a + b
        end
        return b
    else
        # Fall back to BigInt for larger values
        a, b = BigInt(1), BigInt(1)
        for _ in 3:n
            a, b = b, a + b
        end
        return b
    end
end

# Precompile for common sizes
precompile(fib, (Int,))

# Parse command line arguments
n = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 60
runs = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 1

# Internal benchmarking loop
result = fib(n)
for _ in 2:runs
    result = fib(n)
end

# Only print the result once
println(result)
