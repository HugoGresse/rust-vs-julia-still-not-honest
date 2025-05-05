#!/usr/bin/env bash
set -eo pipefail

# =================================================================
# Modern Fibonacci Benchmark Runner
# =================================================================

# Default configuration
DEFAULT_RUNS=20
DEFAULT_N=60
EXPECTED_RESULT="1548008755920"
RESULT_FILE="benchmark_results.csv"
TABLE_FILE="benchmark_table.md"
VERBOSE=true
SHOW_PROGRESS=true
USE_COLOR=true
USE_DOCKER=true  # Default to using Docker

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
  --no-docker          Run benchmarks natively without Docker
  -v, --verbose        Enable verbose output

Example:
  ./$(basename "$0") --runs 10 --languages rust,julia
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
    
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"javascript"* || "$SELECTED_LANGS" == *"js"* ]]; then
        check_command node "Node.js benchmarks will be skipped"
        check_command bun "Bun benchmarks will be skipped"
        check_command deno "Deno benchmarks will be skipped"
    fi
    
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"typescript"* || "$SELECTED_LANGS" == *"ts"* ]]; then
        check_command node "Node.js benchmarks will be skipped"
        check_command ts-node "TypeScript benchmarks with Node.js will be skipped"
        check_command bun "Bun benchmarks will be skipped"
        check_command deno "Deno benchmarks will be skipped"
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
    
    # Test the output once to ensure it matches expected result
    local valid_output=$(mktemp)
    $command > "$valid_output"
    local result=$(cat "$valid_output")
    rm "$valid_output"
    
    if [[ "$result" != "$EXPECTED_RESULT" ]]; then
        print_warning "  Output '$result' does not match expected '$EXPECTED_RESULT'"
    fi
    
    # Array to store all run times for statistical analysis
    local times=()
    local total_time=0
    local min_time=9999999
    local max_time=0
    
    for i in $(seq 1 "$runs"); do
        if [[ "$SHOW_PROGRESS" == "true" ]]; then
            echo -ne "\r  Running: [$(printf '=%.0s' $(seq 1 "$i"))$(printf ' %.0s' $(seq "$i" $(($runs - 1))))] ($i/$runs)"
        fi
        
        # Time the command using bash's built-in timing, sending output to /dev/null
        # to avoid output parsing issues
        local start_time=$(date +%s.%N)
        $command > /dev/null
        local end_time=$(date +%s.%N)
        local time_taken=$(echo "$end_time - $start_time" | bc)
        
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
        --no-docker)
            USE_DOCKER=false
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
    ["JavaScript-Node"]="node fib.node.js"
    ["JavaScript-Bun"]="bun fib.js"
    ["JavaScript-Deno"]="deno run --allow-read fib.js.deno"
    ["TypeScript-Node"]="ts-node fib.node.ts"
    ["TypeScript-Node-Compiled"]="node fib.node_alt.js"
    ["TypeScript-Node-Simple"]="ts-node fib.node.simple.ts"
    ["TypeScript-Bun"]="bun fib.ts"
    ["TypeScript-Deno"]="deno run --allow-read fib.ts.deno"
    ["TypeScript-Deno-Simple"]="deno run fib.ts.deno.simple.ts"
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
    base_lang=$(echo "$lang_lower" | cut -d'-' -f1)
    
    # Skip if not in selected languages (if specified)
    if [[ -n "$SELECTED_LANGS" && ! "$SELECTED_LANGS" == *"$base_lang"* && ! "$SELECTED_LANGS" == *"$lang_lower"* ]]; then
        continue
    fi
    
    # Extract runtime and file from command
    cmd="${additional_languages[$lang]}"
    print_info "Examining command for $lang: $cmd"
    runtime=$(echo "$cmd" | awk '{print $1}')
    
    # Special handling for deno commands
    if [[ "$runtime" == "deno" ]]; then
        # For deno, we need to find the actual source file after the 'run' and potential flags
        source_file=$(echo "$cmd" | awk '{for(i=1;i<=NF;i++) if($i == "run") {for(j=i+1;j<=NF;j++) if($j !~ /^--/) {print $j; exit}}}')
        print_info "Deno source file: $source_file"
    else
        # For other runtimes, the source file is typically the second argument
        source_file=$(echo "$cmd" | awk '{for(i=2;i<=NF;i++) if($i !~ /^-/) {print $i; exit}}')
        print_info "Standard source file: $source_file"
    fi
    
    # Special handling for ts-node
    if [[ "$runtime" == "npx" && $(echo "$cmd" | grep -q "ts-node"; echo $?) -eq 0 ]]; then
        # For ts-node via npx, just check if the .ts file exists
        print_info "Detected ts-node via npx"
        runtime_check=true
        ts_file=$(echo "$cmd" | awk '{for(i=3;i<=NF;i++) if($i !~ /^-/) {print $i; exit}}')
        print_info "TypeScript file for ts-node: $ts_file"
        if [[ -f "$ts_file" ]]; then
            source_file="$ts_file"
        else
            source_file=""
            print_warning "TypeScript file not found: $ts_file"
        fi
    else
        # Check if runtime exists
        runtime_check=$(command -v "$runtime" &>/dev/null && echo true || echo false)
        if [[ "$runtime_check" != "true" ]]; then
            print_warning "Runtime '$runtime' not found in PATH"
            which "$runtime" || echo "which command failed for $runtime"
        fi
    fi
    
    # Display additional debug info
    if [[ -f "$source_file" ]]; then
        print_info "Source file exists: $source_file ($(wc -l < "$source_file") lines)"
        if [[ "$VERBOSE" == "true" ]]; then
            print_info "First few lines of $source_file:"
            head -n 5 "$source_file"
        fi
    else
        print_warning "Source file does not exist: $source_file"
    fi
    
    # Check if runtime exists and source file exists
    if [[ "$runtime_check" == "true" && -f "$source_file" ]]; then
        if [[ "$VERBOSE" == "true" ]]; then
            print_info "Found additional language: $lang"
        fi
        # Try with smaller input for diagnostics first
        if [[ "$lang" == *"JavaScript"* || "$lang" == *"TypeScript"* ]]; then
            print_info "Testing $lang with smaller input first..."
            modified_cmd="${cmd} 10"
            $modified_cmd &>/dev/null && print_success "  Test with small input successful" || print_warning "  Test with small input failed"
        fi
        run_benchmark "$lang" "${additional_languages[$lang]}" "$RUNS" || true
    elif [[ "$VERBOSE" == "true" ]]; then
        if [[ "$runtime_check" != "true" ]]; then
            print_info "Skipping $lang (runtime '$runtime' not available)"
        elif [[ ! -f "$source_file" ]]; then
            print_info "Skipping $lang (source file '$source_file' not found)"
        fi
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