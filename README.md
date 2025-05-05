# Benchmark of Multiple Languages

Test ran on Apple Silicon M2.

## Implemented Languages

- Rust
- Julia
- Python
- C
- C++
- Go
- Fortran
- Java
- Zig

## Running with Docker (Recommended)

This repository includes a Docker setup that automatically builds and runs all benchmarks in a consistent environment.

### Build the Docker image:

```bash
docker build -t fib-benchmark .
```

### Run the benchmarks:

```bash
docker run --rm fib-benchmark
```

This will:

1. Build all language implementations
2. Run each benchmark 5 times
3. Calculate and display average execution times
4. Generate a sorted table of results

## Manual Build Instructions

### Rust

```
cargo build --release
```

### C

```
gcc -O3 -o fib_c fib.c
```

### C++

```
g++ -O3 -o fib_cpp fib.cpp
```

### Go

```
go build -o fib_go fib.go
```

### Fortran

```
gfortran -O3 -o fib_fortran fib.f90
```

### Java

```
javac Fib.java
```

### Zig

```
zig build-exe -O ReleaseFast fib.zig
```

## Original Benchmark Results

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

## Running the Benchmarks Manually

To benchmark all implementations, you can use the time command:

```bash
# Rust
time ./target/release/fib

# Julia
time julia fib.jl

# Python
time python3 fib.py

# C
time ./fib_c

# C++
time ./fib_cpp

# Go
time ./fib_go

# Fortran
time ./fib_fortran

# Java
time java Fib

# Zig
time ./fib
```
