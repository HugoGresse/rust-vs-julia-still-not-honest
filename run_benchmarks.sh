#!/usr/bin/env bash
set -eo pipefail

# =================================================================
# Modern Fibonacci Benchmark Runner
# =================================================================

# Default configuration
DEFAULT_RUNS=5
DEFAULT_N=60
EXPECTED_RESULT="1548008755920"
RESULT_FILE="benchmark_results.csv"
TABLE_FILE="benchmark_table.md"
VERBOSE=true
SHOW_PROGRESS=true
USE_COLOR=true

# Color codes (if enabled)
if [[ "$USE_COLOR" == "true" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    RESET=""
fi

# -------------------------
# Helper functions
# -------------------------

print_header() {
    echo -e "${BOLD}$1${RESET}"
    echo -e "${BLUE}${2:-$(printf '=%.0s' $(seq 1 ${#1})))}${RESET}"
    echo
}

print_info() {
    echo -e "${BLUE}➤ $1${RESET}"
}

print_success() {
    echo -e "${GREEN}✓ $1${RESET}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${RESET}" >&2
}

print_error() {
    echo -e "${RED}✗ $1${RESET}" >&2
}

show_help() {
    cat << EOF
Usage: ./$(basename "$0") [options]

Options:
  -h, --help           Show this help message
  -r, --runs NUMBER    Set number of benchmark runs (default: $DEFAULT_RUNS)
  -n, --number VALUE   Set Fibonacci number to calculate (default: $DEFAULT_N)
  -l, --languages LANG Run benchmarks only for specified languages (comma-separated)
  -o, --output FILE    Set output CSV file (default: $RESULT_FILE)
  --no-color           Disable colored output
  --no-progress        Disable progress indicators
  -v, --verbose        Enable verbose output

Example:
  ./$(basename "$0") --runs 10 --languages rust,julia,python
EOF
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        if [[ -n "$3" ]]; then
            print_warning "$3"
        else
            print_warning "Command '$1' not found, ${2:-this may affect the benchmarks}"
        fi
        return 1
    fi
    return 0
}

check_library() {
    local lib_name=$1
    local lib_file=$2
    local error_msg=$3
    
    if ! ldconfig -p 2>/dev/null | grep -q "$lib_file"; then
        if [[ -n "$error_msg" ]]; then
            print_warning "$error_msg"
        else
            print_warning "Library '$lib_name' not found, this may affect the benchmarks"
        fi
        return 1
    fi
    return 0
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check for essential commands
    check_command bc "benchmark calculations will fail" || exit 1
    
    # Check for optional dependencies with custom messages
    check_command column "results may not be formatted nicely"
    
    # Check for language-specific dependencies based on selected languages
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"rust"* ]]; then
        check_command rustc "Rust benchmarks will be skipped"
    fi
    
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"julia"* ]]; then
        check_command julia "Julia benchmarks will be skipped"
    fi
    
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"python"* ]]; then
        check_command python3 "Python benchmarks will be skipped"
    fi
    
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"go"* ]]; then
        check_command go "Go benchmarks will be skipped"
    fi
    
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"zig"* ]]; then
        check_command zig "Zig benchmarks will be skipped"
    fi
    
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"c"* ]]; then
        check_command gcc "C benchmarks will be skipped"
    fi

    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"c++"* ]]; then
        check_command g++ "C++ benchmarks will be skipped"
        
        if check_command g++ &>/dev/null; then
            # Check if boost is available, but don't fail if not
            if check_command pkg-config &>/dev/null; then
                if ! pkg-config --exists boost 2>/dev/null; then
                    print_warning "C++ benchmarks may fail (Boost libraries not found)"
                fi
            fi
        fi
    fi

    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"java"* ]]; then
        check_command javac "Java benchmarks will be skipped"
    fi
    
    echo
}

compile_languages() {
    print_info "Compiling language implementations..."
    
    # Compile C
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"c"* ]]; then
        if check_command gcc &>/dev/null; then
            print_info "Compiling C implementation..."
            # Try with simplified implementation (no GMP required)
            gcc -O3 -o fib_c fib.c 2>/dev/null || print_warning "Failed to compile fib.c"
        fi
    fi
    
    # Compile C++
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"c++"* ]]; then
        if check_command g++ &>/dev/null; then
            print_info "Compiling C++ implementation..."
            # Try with Boost first, then fallback to standard implementation
            if check_command pkg-config &>/dev/null && pkg-config --exists boost 2>/dev/null; then
                print_info "  Compiling with Boost support"
                g++ -O3 -DHAVE_BOOST -o fib_cpp fib.cpp -lboost_system 2>/dev/null && \
                    print_success "  Compiled C++ with Boost" || \
                    print_warning "  Failed to compile with Boost"
            else
                print_info "  Compiling without Boost (limited precision)"
                g++ -O3 -o fib_cpp fib.cpp 2>/dev/null || print_warning "Failed to compile fib.cpp"
            fi
        fi
    fi
    
    # Compile Go
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"go"* ]]; then
        if check_command go &>/dev/null; then
            print_info "Compiling Go implementation..."
            go build -o fib_go fib.go 2>/dev/null || print_warning "Failed to compile fib.go"
        fi
    fi
    
    # Compile Fortran
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"fortran"* ]]; then
        if check_command gfortran &>/dev/null; then
            print_info "Compiling Fortran implementation..."
            gfortran -O3 -o fib_fortran fib.f90 2>/dev/null || print_warning "Failed to compile fib.f90"
        fi
    fi
    
    # Compile Java
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"java"* ]]; then
        if check_command javac &>/dev/null; then
            print_info "Compiling Java implementation..."
            javac Fib.java 2>/dev/null || print_warning "Failed to compile Fib.java"
        fi
    fi
    
    # Compile Rust
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"rust"* ]]; then
        if check_command rustc &>/dev/null; then
            print_info "Compiling Rust implementation..."
            if [[ ! -d "target/release" ]]; then
                mkdir -p target/release
                rustc -O fib.rs -o target/release/fib 2>/dev/null || print_warning "Failed to compile fib.rs"
            fi
        fi
    fi

    # Compile Zig
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"zig"* ]]; then
        if check_command zig &>/dev/null; then
            print_info "Compiling Zig implementation..."
            zig build-exe -O ReleaseFast fib.zig 2>/dev/null || print_warning "Failed to compile fib.zig"
        fi
    fi
    
    echo
}

# Validate language implementations return correct result
validate_languages() {
    print_info "Validating language implementations..."
    
    local validated_languages=()
    
    for lang in "${!languages[@]}"; do
        lang_lower=$(echo "$lang" | tr '[:upper:]' '[:lower:]')
        
        # Skip if not in selected languages (if specified)
        if [[ -n "$SELECTED_LANGS" && ! "$SELECTED_LANGS" == *"$lang_lower"* ]]; then
            continue
        fi
        
        print_info "  Validating $lang..."
        
        cmd=${languages[$lang]}
        result=$($cmd 2>/dev/null || echo "FAILED")
        
        if [[ "$result" == "FAILED" ]]; then
            print_warning "    Failed to run $lang implementation"
        elif [[ "$result" != "$EXPECTED_RESULT" ]]; then
            print_warning "    $lang returned incorrect result: '$result' (expected: '$EXPECTED_RESULT')"
        else
            print_success "    $lang result verified: '$result'"
            validated_languages+=("$lang")
        fi
    done
    
    # Update the languages array to only include validated languages
    for lang in "${!languages[@]}"; do
        if ! printf '%s\n' "${validated_languages[@]}" | grep -q "^$lang$"; then
            unset languages["$lang"]
        fi
    done
    
    if [[ "${#languages[@]}" -eq 0 ]]; then
        print_warning "No language implementations were successfully validated. Check that implementations are correct."
    else
        print_success "Successfully validated ${#languages[@]} language implementations."
    fi
    
    echo
}

# Core benchmark function
run_benchmark() {
    local name=$1
    local command=$2
    local runs=${3:-$DEFAULT_RUNS}
    
    print_info "Running $name benchmark ($runs runs)..."
    
    # Validate command can run
    if ! $command &>/dev/null; then
        print_error "Skipping $name benchmark - command failed to run"
        echo "$name,FAILED" >> "$RESULT_FILE"
        return 1
    fi
    
    # Array to store all run times for statistical analysis
    local times=()
    local total_time=0
    local min_time=9999999
    local max_time=0
    local test_result=""
    
    for i in $(seq 1 "$runs"); do
        if [[ "$SHOW_PROGRESS" == "true" ]]; then
            echo -ne "\r  Running: [$(printf '=%.0s' $(seq 1 "$i"))$(printf ' %.0s' $(seq "$i" $(($runs - 1))))] ($i/$runs)"
        fi
        
        # Use /usr/bin/time with format to get real time in seconds
        time_output=$(/usr/bin/time -f "%e" $command 2>&1)
        test_result=$(echo "$time_output" | grep -v "^[0-9]")
        time_taken=$(echo "$time_output" | grep "^[0-9]" | tail -n 1)
        
        # Validate result is correct
        if [[ "$test_result" != "$EXPECTED_RESULT" ]]; then
            if [[ "$VERBOSE" == "true" ]]; then
                print_warning "  Unexpected output: $test_result (expected: $EXPECTED_RESULT)"
            fi
        fi
        
        times+=("$time_taken")
        total_time=$(echo "$total_time + $time_taken" | bc)
        
        # Update min/max
        if (( $(echo "$time_taken < $min_time" | bc -l) )); then
            min_time=$time_taken
        fi
        
        if (( $(echo "$time_taken > $max_time" | bc -l) )); then
            max_time=$time_taken
        fi
    done
    
    if [[ "$SHOW_PROGRESS" == "true" ]]; then
        echo -ne "\r                                                                 \r"
    fi
    
    # Calculate statistics
    local avg_time=$(echo "scale=6; $total_time / $runs" | bc)
    
    # Calculate standard deviation
    local variance=0
    for t in "${times[@]}"; do
        local diff=$(echo "$t - $avg_time" | bc)
        variance=$(echo "$variance + ($diff * $diff)" | bc)
    done
    local stddev=$(echo "scale=6; sqrt($variance / $runs)" | bc)
    
    # Print results
    print_success "  Average: ${BOLD}${avg_time}s${RESET} (Min: ${min_time}s, Max: ${max_time}s, StdDev: ${stddev}s)"
    
    # Save to CSV
    echo "$name,$avg_time,$min_time,$max_time,$stddev" >> "$RESULT_FILE"
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "  All runs: ${times[*]}"
    fi
    
    echo
}

# -------------------------
# Parse command line args
# -------------------------
RUNS=$DEFAULT_RUNS
FIB_N=$DEFAULT_N
SELECTED_LANGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -r|--runs)
            RUNS="$2"
            shift 2
            ;;
        -n|--number)
            FIB_N="$2"
            shift 2
            ;;
        -l|--languages)
            SELECTED_LANGS=$(echo "$2" | tr '[:upper:]' '[:lower:]')
            shift 2
            ;;
        -o|--output)
            RESULT_FILE="$2"
            shift 2
            ;;
        --no-color)
            USE_COLOR=false
            RED=""
            GREEN=""
            YELLOW=""
            BLUE=""
            BOLD=""
            RESET=""
            shift
            ;;
        --no-progress)
            SHOW_PROGRESS=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# -------------------------
# Main benchmark process
# -------------------------
print_header "Fibonacci Benchmark Runner" "=========================="

# Check for required dependencies
check_dependencies

# Compile languages
compile_languages

# Create results file with detailed header
echo "Language,Average(s),Min(s),Max(s),StdDev(s)" > "$RESULT_FILE"

# Prepare language definitions
declare -A languages=(
    ["Rust"]="./target/release/fib"
    ["Julia"]="julia fib.jl"
    ["Python"]="python3 fib.py"
    ["C"]="./fib_c"
    ["C++"]="./fib_cpp"
    ["Go"]="./fib_go"
    ["Fortran"]="./fib_fortran"
    ["Java"]="java Fib"
    ["Zig"]="./fib"
)

# Define additional languages that might be available
declare -A additional_languages=(
    ["WebAssembly"]="node fib.wasm.js"
    ["JavaScript"]="node fib.js"
    ["TypeScript"]="ts-node fib.ts"
    ["Ruby"]="ruby fib.rb"
    ["PHP"]="php fib.php"
)

# Validate language implementations
validate_languages

# Run benchmarks
print_header "Running Benchmarks" "-----------------"

# First run primary languages
for lang in "${!languages[@]}"; do
    lang_lower=$(echo "$lang" | tr '[:upper:]' '[:lower:]')
    
    # Skip if not in selected languages (if specified)
    if [[ -n "$SELECTED_LANGS" && ! "$SELECTED_LANGS" == *"$lang_lower"* ]]; then
        if [[ "$VERBOSE" == "true" ]]; then
            print_info "Skipping $lang (not in selected languages)"
        fi
        continue
    fi
    
    run_benchmark "$lang" "${languages[$lang]}" "$RUNS" || true
done

# Try additional languages if files exist and not filtered out
for lang in "${!additional_languages[@]}"; do
    lang_lower=$(echo "$lang" | tr '[:upper:]' '[:lower:]')
    
    # Skip if not in selected languages (if specified)
    if [[ -n "$SELECTED_LANGS" && ! "$SELECTED_LANGS" == *"$lang_lower"* ]]; then
        continue
    fi
    
    # Check if source file exists
    source_file=$(echo "${additional_languages[$lang]}" | awk '{print $NF}')
    if [[ -f "$source_file" ]]; then
        if [[ "$VERBOSE" == "true" ]]; then
            print_info "Found additional language: $lang"
        fi
        run_benchmark "$lang" "${additional_languages[$lang]}" "$RUNS" || true
    fi
done

# Display sorted results
print_header "Benchmark Results (sorted by execution time)" "----------------------------------------"

if command -v column &> /dev/null; then
    # First line with headers
    head -n1 "$RESULT_FILE" | column -t -s,
    echo -e "${BLUE}$(printf '%.0s-' $(seq 1 60))${RESET}"
    # Data lines, sorted by time
    tail -n+2 "$RESULT_FILE" | grep -v "FAILED" | sort -t, -k2,2 -n | column -t -s,
else
    # Fallback formatting without column command
    head -n1 "$RESULT_FILE" | awk -F, '{printf "%-10s %-12s %-10s %-10s %-10s\n", $1, $2, $3, $4, $5}'
    echo -e "${BLUE}$(printf '%.0s-' $(seq 1 60))${RESET}"
    tail -n+2 "$RESULT_FILE" | grep -v "FAILED" | sort -t, -k2,2 -n | 
        awk -F, '{printf "%-10s %-12s %-10s %-10s %-10s\n", $1, $2, $3, $4, $5}'
fi

# List failed benchmarks
if grep -q "FAILED" "$RESULT_FILE"; then
    echo
    print_warning "The following benchmarks failed to run:"
    grep "FAILED" "$RESULT_FILE" | cut -d, -f1 | while read -r lang; do
        echo "  - $lang"
    done
fi

# Create markdown table for README
print_info "Generating markdown table for README"

cat > "$TABLE_FILE" << EOF
## Benchmark Results

Results for Fibonacci($FIB_N) calculation with $RUNS runs per language:

| Language | Average (s) | Min (s) | Max (s) | StdDev (s) |
| -------- | ----------- | ------- | ------- | ---------- |
EOF

# Add sorted results
tail -n+2 "$RESULT_FILE" | grep -v "FAILED" | sort -t, -k2,2 -n | while IFS=, read -r lang avg min max stddev; do
    echo "| $lang | $avg | $min | $max | $stddev |" >> "$TABLE_FILE"
done

# Add failed benchmarks if any
if grep -q "FAILED" "$RESULT_FILE"; then
    cat >> "$TABLE_FILE" << EOF

### Failed Benchmarks

The following benchmarks could not be run in this environment:

EOF
    grep "FAILED" "$RESULT_FILE" | cut -d, -f1 | while read -r lang; do
        echo "- $lang" >> "$TABLE_FILE"
    done
fi

print_success "Results saved to $RESULT_FILE and $TABLE_FILE"
echo
print_info "To run a custom benchmark: $0 --runs 10 --languages rust,julia" 