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
VERBOSE=false
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
    if [[ "$VERBOSE" == "true" || "$2" == "important" ]]; then
        echo -e "${BLUE}➤ $1${RESET}"
    fi
}

print_success() {
    if [[ "$VERBOSE" == "true" || "$2" == "important" ]]; then
        echo -e "${GREEN}✓ $1${RESET}"
    fi
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
    print_info "Checking dependencies..." "important"
    
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
    fi

    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"java"* ]]; then
        check_command javac "Java benchmarks will be skipped"
    fi
    
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"csharp"* || "$SELECTED_LANGS" == *"c#"* ]]; then
        check_command dotnet "C# benchmarks will be skipped"
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
    
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"php"* ]]; then
        check_command php "PHP benchmarks will be skipped"
    fi
    
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"lisp"* ]]; then
        check_command sbcl "Common Lisp benchmarks will be skipped"
    fi
    
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"perl"* ]]; then
        check_command perl "Perl benchmarks will be skipped"
    fi
    
    echo
}

compile_languages() {
    print_info "Compiling language implementations..." "important"
    
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
    
    # Compile C#
    if [[ -z "$SELECTED_LANGS" || "$SELECTED_LANGS" == *"csharp"* || "$SELECTED_LANGS" == *"c#"* ]]; then
        if check_command dotnet &>/dev/null; then
            print_info "Compiling C# implementation..."
            # Detect architecture
            ARCH=$(uname -m)
            print_info "  Detected architecture: $ARCH"
            
            # Set appropriate RuntimeIdentifier
            if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
                RID="linux-arm64"
            elif [[ "$ARCH" == "x86_64" ]]; then
                RID="linux-x64"
            else
                RID="linux-$ARCH"
            fi
            print_info "  Using .NET RuntimeIdentifier: $RID"
            
            # Build for release and publish as a self-contained app
            dotnet publish -c Release -r $RID --self-contained true -o ./bin/csharp 2>/dev/null || print_warning "Failed to compile C# project"
        fi
    fi
    
    echo
}

# Validate language implementations return correct result
validate_languages() {
    print_info "Validating language implementations..." "important"
    
    local validated_languages=()
    
    for lang in "${!languages[@]}"; do
        lang_lower=$(echo "$lang" | tr '[:upper:]' '[:lower:]')
        
        # Skip if not in selected languages (if specified)
        if [[ -n "$SELECTED_LANGS" && ! "$SELECTED_LANGS" == *"$lang_lower"* ]]; then
            continue
        fi
        
        print_info "  Validating $lang..."
        
        cmd=${languages[$lang]}
        print_info "    Command: $cmd"
        
        # Enhanced logging for C# specifically
        if [[ "$lang" == "C#" ]]; then
            print_info "    Checking C# executable:"
            ls -la $(echo "$cmd" | awk '{print $1}') || print_warning "C# executable not found"
            print_info "    Checking if file is executable..."
            test -x $(echo "$cmd" | awk '{print $1}') && print_success "File is executable" || print_warning "File is NOT executable"
            print_info "    File type info:"
            file $(echo "$cmd" | awk '{print $1}') || print_warning "Could not determine file type"
        fi
        
        print_info "    Executing: $cmd"
        result=$($cmd 2>&1 || echo "FAILED:$?")
        
        if [[ "$result" == FAILED* ]]; then
            exit_code=$(echo "$result" | cut -d':' -f2)
            print_warning "    Failed to run $lang implementation (exit code: $exit_code)"
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
        print_success "Successfully validated ${#languages[@]} language implementations." "important"
    fi
    
    echo
}

# Core benchmark function
run_benchmark() {
    local name=$1
    local command=$2
    local runs=${3:-$DEFAULT_RUNS}
    
    print_info "Running $name benchmark ($runs runs)..." "important"
    
    # Add parameters for n and runs to the command
    # The pattern is: command n runs
    local full_command="$command $FIB_N $runs"
    
    print_info "  Command to execute: '$full_command'"
    
    # Special debug for C#
    if [[ "$name" == "C#" ]]; then
        print_info "  Checking C# executable before benchmark run:"
        
        # Check if binary exists and is executable
        bin_path=$(echo "$command" | awk '{print $1}')
        print_info "  Binary path: $bin_path"
        
        if [[ -f "$bin_path" ]]; then
            print_success "  C# binary exists"
            ls -la "$bin_path"
        else
            print_error "  C# binary not found at '$bin_path'"
            ls -la "$(dirname "$bin_path")" || echo "Cannot list directory"
            return 1
        fi
        
        # Check permissions
        if [[ -x "$bin_path" ]]; then
            print_success "  C# binary is executable"
        else
            print_warning "  C# binary is not executable, fixing permissions"
            chmod +x "$bin_path"
        fi
        
        # Show binary info
        print_info "  Binary type information:"
        file "$bin_path" || echo "Failed to get file info"
    fi
    
    # Validate command can run
    print_info "  Validating command execution..."
    if ! $full_command &>/dev/null; then
        print_error "  Validation failed - command execution error"
        print_info "  Attempting to run with debug output:"
        $full_command
        echo "Exit code: $?"
        print_error "Skipping $name benchmark - command failed to run"
        echo "$name,FAILED,N/A,0" >> "$RESULT_FILE"
        return 1
    else
        print_success "  Command validation successful"
    fi
    
    # Test the output once to ensure it matches expected result
    print_info "  Testing output validity..."
    local valid_output=$(mktemp)
    $command $FIB_N 1 > "$valid_output"
    local result=$(cat "$valid_output")
    rm "$valid_output"
    
    if [[ "$result" != "$EXPECTED_RESULT" ]]; then
        print_warning "  Output '$result' does not match expected '$EXPECTED_RESULT'"
    else
        print_success "  Output verified: '$result' matches expected result"
    fi
    
    # For the internal benchmark, we only need to run it once as the loop is inside the implementation
    print_info "  Starting benchmark measurement..."
    # Use 'time' command to measure execution time with nanosecond precision
    time_output=$(TIMEFORMAT='%U.%N'; { time $full_command > /dev/null; } 2>&1)
    
    # Ensure time is a valid numeric value and convert to microseconds internally
    if ! [[ "$time_output" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        print_warning "Invalid time output: $time_output, using fallback value of 0.001"
        time_output="0.001"
    fi
    
    # Store time in microseconds for more precision (1s = 1,000,000μs)
    time_us=$(echo "$time_output * 1000000" | bc)
    # Round to nearest integer microsecond
    time_us=$(echo "($time_us+0.5)/1" | bc)
    
    # Also keep the original for display
    local time_taken=$time_output
    
    # Print results
    print_success "  Time: ${BOLD}${time_taken}s (${time_us}μs)${RESET}" "important"
    
    # Save to CSV with microsecond precision in 4th column (not displayed but used for calculations)
    echo "$name,$time_taken,,$time_us" >> "$RESULT_FILE"
    
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
echo "Language,Time(s),RelativePerformance(%),TimeUs" > "$RESULT_FILE"

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

# Add C# with fallback paths - try multiple locations in order
if [[ -x "./bin/csharp/Fib" ]]; then
    languages["C#"]="./bin/csharp/Fib"
elif [[ -x "./bin/Release/Fib" ]]; then
    languages["C#"]="./bin/Release/Fib"
elif [[ -x "./bin/Release/net7.0/linux-x64/Fib" ]]; then
    languages["C#"]="./bin/Release/net7.0/linux-x64/Fib"
elif [[ -f "./bin/csharp/Fib.dll" ]]; then
    languages["C#"]="dotnet ./bin/csharp/Fib.dll"
elif [[ -f "./bin/Release/net7.0/Fib.dll" ]]; then
    languages["C#"]="dotnet ./bin/Release/net7.0/Fib.dll"
else
    print_warning "Unable to find C# executable - it will be skipped"
fi

# Define additional languages that might be available
declare -A additional_languages=(
    ["WebAssembly"]="node fib.wasm.js"
    ["JavaScript-Node"]="node fib.node.js"
    ["JavaScript-Bun"]="bun fib.js"
    ["JavaScript-Deno"]="deno run --allow-read fib.js.deno"
    ["TypeScript-Node-Compiled"]="node fib.node_alt.js"
    ["TypeScript-Bun"]="bun fib.ts"
    ["TypeScript-Deno"]="deno run --allow-read fib.ts.deno"
    ["Ruby"]="ruby fib.rb"
    ["PHP"]="php fib.php"
    ["Perl"]="perl fib.pl"
    ["Lisp"]="sbcl --script fib.lisp"
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

# Calculate relative performance percentages
print_info "Calculating relative performance..."
# Create a temporary file
tmp_result=$(mktemp)
# Copy header
head -n1 "$RESULT_FILE" > "$tmp_result"

# Get the fastest time (first entry after sorting by microseconds)
print_info "Raw timing results before sorting:"
cat "$RESULT_FILE"

print_info "Sorting results by microsecond time..."
sorted_results=$(tail -n+2 "$RESULT_FILE" | grep -v "FAILED" | sort -t, -k4,4 -g)
print_info "Sorted results with numeric sorting (-g):"
echo "$sorted_results"

fastest_result=$(echo "$sorted_results" | head -n1)
fastest_lang=$(echo "$fastest_result" | cut -d, -f1)
fastest_time_s=$(echo "$fastest_result" | cut -d, -f2)
fastest_time_us=$(echo "$fastest_result" | cut -d, -f4)
print_info "Fastest language: $fastest_lang with time: ${fastest_time_s}s (${fastest_time_us}μs)"

# Check if fastest time is valid
if [[ -z "$fastest_time_us" || "$fastest_time_us" == "0" ]]; then
    print_warning "Fastest time in microseconds is zero or empty, using 1 to avoid division by zero"
    fastest_time_us="1"
fi

# Ensure fastest_time is a numeric value
fastest_time_us=$(echo "$fastest_time_us" | sed 's/[^0-9.]//g')
print_info "Sanitized fastest time: ${fastest_time_us}μs"

# Calculate percentage increase for each entry
tail -n+2 "$RESULT_FILE" | grep -v "FAILED" | sort -t, -k4,4 -g | while IFS=, read -r lang time_s perf time_us; do
    # Ensure time is a valid numeric value
    if ! [[ "$time_us" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        print_warning "Invalid microsecond value for $lang: $time_us, skipping"
        continue
    fi

    # Sanitize time value
    time_us=$(echo "$time_us" | sed 's/[^0-9.]//g')
    
    # Only the actual fastest language should get 0.0%
    if [[ "$lang" == "$fastest_lang" ]]; then
        # Fastest language is the baseline (0% increase)
        percentage="0.0"
        print_info "  $lang: time=${time_s}s (${time_us}μs) is fastest (0% increase)"
    else
        # Calculate percentage increase: ((time - fastest_time) / fastest_time) * 100
        print_info "  Calculating for $lang: time=${time_s}s (${time_us}μs), fastest=${fastest_time_s}s (${fastest_time_us}μs)"
        
        # Both values are already in microseconds (integer), so calculation is straightforward
        time_diff=$(echo "$time_us - $fastest_time_us" | bc)
        print_info "  Difference in μs: $time_diff"
        
        # Calculate percentage - use bc for high precision
        calc_result=$(echo "scale=6; ($time_diff / $fastest_time_us) * 100" | bc -l 2>/dev/null)
        print_info "  Raw percentage: $calc_result"
        
        # If calculation fails, use a simple fallback approach
        if [[ -z "$calc_result" ]]; then
            print_warning "  BC calculation failed for $lang, using Bash arithmetic fallback"
            if [[ "$fastest_time_us" -gt "0" ]]; then
                calc_result=$(( (time_us - fastest_time_us) * 100 / fastest_time_us ))
                print_info "  Fallback calculation: (($time_us - $fastest_time_us) * 100 / $fastest_time_us) = $calc_result"
            else
                print_warning "  Fallback failed too, setting percentage to 999.9"
                calc_result="999.9"
            fi
        fi
        
        # Try to format the percentage, catch any errors
        percentage=$(LC_NUMERIC=C printf "%.1f" $calc_result 2>/dev/null)
        # Check if we got a valid percentage
        if [[ -z "$percentage" || ! "$percentage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            print_warning "  Formatting failed, using raw calc_result"
            percentage=$calc_result
        fi
        
        # Ensure we don't accidentally output 0.0 for values that are just close
        if [[ "$percentage" == "0.0" && "$lang" != "$fastest_lang" ]]; then
            print_warning "  Percentage rounded to 0.0 but this isn't the fastest language, using 0.1"
            percentage="0.1"
        fi
        
        print_info "  Final result: $lang is ${percentage}% slower than fastest"
    fi
    
    # Add the percentage sign for display
    echo "$lang,$time_s,$percentage%,$time_us" >> "$tmp_result"
done

# Add failed entries
if grep -q "FAILED" "$RESULT_FILE"; then
    print_info "Adding failed benchmark entries to the results..."
    grep "FAILED" "$RESULT_FILE" >> "$tmp_result"
fi

# Replace original file with updated one
mv "$tmp_result" "$RESULT_FILE"

# Display sorted results
print_header "Benchmark Results (sorted by execution time)" "----------------------------------------"

if command -v column &> /dev/null; then
    # Create a display-ready version of the results file (without the hidden microseconds column)
    display_file=$(mktemp)
    head -n1 "$RESULT_FILE" | cut -d, -f1-3 > "$display_file"
    tail -n+2 "$RESULT_FILE" | sort -t, -k4,4 -g | cut -d, -f1-3 >> "$display_file"
    
    # First line with headers
    head -n1 "$display_file" | column -t -s,
    echo -e "${BLUE}$(printf '%.0s-' $(seq 1 60))${RESET}"
    # Data lines, sorted by time
    tail -n+2 "$display_file" | grep -v "FAILED" | column -t -s,
    
    # Clean up
    rm "$display_file"
else
    # Fallback formatting without column command
    head -n1 "$RESULT_FILE" | cut -d, -f1-3 | awk -F, '{printf "%-20s %-12s %-20s\n", $1, $2, $3}'
    echo -e "${BLUE}$(printf '%.0s-' $(seq 1 60))${RESET}"
    tail -n+2 "$RESULT_FILE" | grep -v "FAILED" | sort -t, -k4,4 -g | cut -d, -f1-3 | 
        awk -F, '{printf "%-20s %-12s %-20s\n", $1, $2, $3}'
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

| Language | Time (s) | Relative Performance |
| -------- | -------- | ------------------- |
EOF

# Add sorted results
tail -n+2 "$RESULT_FILE" | grep -v "FAILED" | sort -t, -k4,4 -g | cut -d, -f1-3 | while IFS=, read -r lang time perf; do
    echo "| $lang | $time | $perf |" >> "$TABLE_FILE"
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