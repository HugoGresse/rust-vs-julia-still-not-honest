#!/bin/bash
set -e

echo "Setting up benchmarks for macOS..."

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed."
fi

# Install dependencies
echo "Installing dependencies..."
brew update
brew install gcc fortran rust go python3

# Install Julia
if ! command -v julia &> /dev/null; then
    echo "Installing Julia..."
    curl -fsSL https://install.julialang.org | sh
else
    echo "Julia already installed."
    julia --version
fi

# Install Zig
if ! command -v zig &> /dev/null; then
    echo "Installing Zig..."
    brew install zig
else
    echo "Zig already installed."
fi

# Compile implementations
echo "Compiling implementations..."
gcc -O3 -o fib_c fib.c
g++ -O3 -o fib_cpp fib.cpp
go build -o fib_go fib.go
gfortran -O3 -o fib_fortran fib.f90
javac Fib.java
zig build-exe -O ReleaseFast fib.zig
cargo build --release

echo "Setup complete. Running benchmarks..."
chmod +x run_benchmarks.sh
./run_benchmarks.sh

echo "Benchmark completed!" 