#!/usr/bin/env bash
set -e

echo "===== Testing JavaScript/TypeScript Environment ====="

# Check Node.js 
echo "Testing Node.js..."
if command -v node &> /dev/null; then
    node_version=$(node --version)
    echo "✓ Node.js is installed: $node_version"
    
    # Check npm
    if command -v npm &> /dev/null; then
        npm_version=$(npm --version)
        echo "✓ npm is installed: $npm_version"
    else
        echo "✗ npm is not installed"
    fi
    
    # Test simple JavaScript execution
    echo "Testing basic Node.js execution..."
    node -e "console.log('Node.js execution test: ' + (40 + 2))"
    
    # Test fib.js.node file
    if [[ -f "fib.node.js" ]]; then
        echo "Testing fib.node.js with small input..."
        node fib.node.js 10
    elif [[ -f "fib.js.node" ]]; then
        echo "Testing original fib.js.node with small input..."
        node fib.js.node 10 || echo "✗ fib.js.node test failed (expected if extension is wrong)"
    else
        echo "✗ Node.js JavaScript file not found"
    fi
else
    echo "✗ Node.js is not installed"
fi

echo ""

# Check TypeScript
echo "Testing TypeScript..."
if command -v tsc &> /dev/null; then
    ts_version=$(tsc --version)
    echo "✓ TypeScript is installed: $ts_version"
    
    # Check ts-node
    if command -v ts-node &> /dev/null; then
        tsnode_version=$(ts-node --version || echo "ts-node version check failed")
        echo "✓ ts-node is installed: $tsnode_version"
        
        # Test basic TypeScript execution
        echo "Testing basic TypeScript execution..."
        ts-node -e "const x: number = 42; console.log('TypeScript execution test: ' + x);" || 
            echo "✗ Basic TypeScript execution failed"
        
        # Test fib.ts.node file
        if [[ -f "fib.node.ts" ]]; then
            echo "Testing fib.node.ts with small input..."
            set -x # Enable command echoing for debugging
            ts-node fib.node.ts 10
            ts_result=$?
            set +x # Disable command echoing
            
            if [ $ts_result -ne 0 ]; then
                echo "✗ fib.node.ts execution failed with exit code $ts_result"
                # Try alternate approach with Node directly
                echo "Trying with node directly on compiled JS..."
                tsc fib.node.ts && node fib.node.js 10 || echo "✗ Alternative approach also failed"
            fi
        elif [[ -f "fib.ts.node" ]]; then
            echo "Testing original fib.ts.node with small input..."
            ts-node fib.ts.node 10 || echo "✗ fib.ts.node test failed (expected if extension is wrong)"
        else
            echo "✗ TypeScript Node.js file not found"
        fi
    else
        echo "✗ ts-node is not installed"
        # Check where ts-node might be
        echo "Looking for ts-node installation..."
        find /usr -name "ts-node" 2>/dev/null || echo "ts-node not found in /usr"
    fi
else
    echo "✗ TypeScript is not installed"
fi

echo ""

# Check Deno
echo "Testing Deno..."
if command -v deno &> /dev/null; then
    deno_version=$(deno --version | head -n 1)
    echo "✓ Deno is installed: $deno_version"
    
    # Test simple Deno execution
    echo "Testing basic Deno execution..."
    deno eval "console.log('Deno execution test: ' + (40 + 2))"
    
    # Test fib.js.deno file
    if [[ -f "fib.js.deno" ]]; then
        echo "Testing fib.js.deno with small input..."
        deno run --allow-read fib.js.deno 10
    else
        echo "✗ fib.js.deno file not found"
    fi
    
    # Test fib.ts.deno file
    if [[ -f "fib.ts.deno" ]]; then
        echo "Testing fib.ts.deno with small input..."
        deno run --allow-read fib.ts.deno 10
    else
        echo "✗ fib.ts.deno file not found"
    fi
else
    echo "✗ Deno is not installed"
fi

echo ""
echo "===== Environment Test Complete =====" 