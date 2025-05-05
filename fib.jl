function fib(n::Int)
    if n == 1 || n == 2
        return 1
    end
    a, b = 1, 1
    for _ in 3:n
        a, b = b, a + b
    end
    return b
end

val = fib(60)
println(val)
