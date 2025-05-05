# Benchmark Rust vs. Julia vs. Python

Test ran on Apple Sillicon M2.

Build time:
```
cargo build --release  0,21s user 0,12s system 135% cpu 0,244 total
```

Julia doesn't support binary compilation (https://discourse.julialang.org/t/plans-for-static-compiled-binaries/107413/6).

Execution time:
```
julia fib.jl  0,22s user 0,03s system 151% cpu 0,163 total
./target/release/fib  0,00s user 0,00s system 70% cpu 0,007 total
python fib.py  0,02s user 0,01s system 30% cpu 0,102 total
```
