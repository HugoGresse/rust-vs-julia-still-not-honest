#!/bin/bash

echo "Running Fibonacci Benchmarks"
echo "==========================="
echo

# Function to run benchmark multiple times and get average
run_benchmark() {
    name=$1
    command=$2
    runs=${3:-5}  # Default to 5 runs if not specified
    
    echo "Running $name benchmark ($runs runs)..."
    total_time=0
    
    for i in $(seq 1 $runs); do
        # Use /usr/bin/time with format to get real time in seconds
        time_output=$(/usr/bin/time -f "%e" $command 2>&1)
        result=$(echo "$time_output" | grep -v "^[0-9]")
        time_taken=$(echo "$time_output" | grep "^[0-9]" | tail -n 1)
        
        expected_output="1548008755920"
        if [[ "$result" != "$expected_output" ]]; then
            echo "  WARNING: Unexpected output: $result"
        fi
        
        echo "  Run $i: ${time_taken}s"
        total_time=$(echo "$total_time + $time_taken" | bc)
    done
    
    avg_time=$(echo "scale=6; $total_time / $runs" | bc)
    echo "  Average: ${avg_time}s"
    echo "$name,$avg_time" >> benchmark_results.csv
    echo
}

# Create results file with header
echo "Language,Time(s)" > benchmark_results.csv

# Run each benchmark
run_benchmark "Rust" "./target/release/fib"
run_benchmark "Julia" "julia fib.jl"
run_benchmark "Python" "python3 fib.py"
run_benchmark "C" "./fib_c"
run_benchmark "C++" "./fib_cpp"
run_benchmark "Go" "./fib_go"
run_benchmark "Fortran" "./fib_fortran"
run_benchmark "Java" "java Fib"
run_benchmark "Zig" "./fib"

# Display sorted results
echo "Benchmark Results (sorted by execution time)"
echo "==========================================="

# Check if column command exists, otherwise use a fallback
if command -v column &> /dev/null; then
    sort -t, -k2,2 -n benchmark_results.csv | column -t -s,
else
    # Fallback to basic formatting if column command is not available
    sort -t, -k2,2 -n benchmark_results.csv | while IFS=, read -r lang time; do
        printf "%-10s %s\n" "$lang" "$time"
    done
fi

# Create markdown table for README
echo -e "\nGenerating markdown table for README"
echo -e "## Benchmark Results\n" > benchmark_table.md
echo "| Language | Time (seconds) |" >> benchmark_table.md
echo "| -------- | -------------- |" >> benchmark_table.md

sort -t, -k2,2 -n benchmark_results.csv | tail -n +2 | while IFS=, read -r lang time; do
    echo "| $lang | $time |" >> benchmark_table.md
done

echo -e "\nResults saved to benchmark_results.csv and benchmark_table.md" 