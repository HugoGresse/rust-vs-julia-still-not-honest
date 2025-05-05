#!/usr/bin/env bash
set -e

echo "Preparing JavaScript and TypeScript benchmark files..."

# Fix file extensions for Node.js (critical - .node extension is reserved for native modules)
echo "Fixing file extensions for Node.js..."
if [ -f "fib.js.node" ]; then 
    cp fib.js.node fib.node.js
    echo "✓ Created fib.node.js from fib.js.node"
fi

if [ -f "fib.ts.node" ]; then 
    cp fib.ts.node fib.node.ts
    echo "✓ Created fib.node.ts from fib.ts.node"
fi

# Make sure all JS/TS files have the correct line endings
sed -i 's/\r$//' fib.js* fib.ts* fib.node.*

# Ensure all JavaScript and TypeScript files have executable permissions
chmod 755 fib.js* fib.ts* fib.node.*

# Verify file content
echo "Verifying JavaScript and TypeScript file contents..."
for file in fib.js* fib.ts* fib.node.*; do
  if [[ -f "$file" ]]; then
    file_size=$(wc -c < "$file")
    if [[ $file_size -lt 100 ]]; then
      echo "WARNING: $file seems too small ($file_size bytes), might be corrupted"
      head -n 5 "$file"
    else
      echo "$file verified ($file_size bytes)"
    fi
  fi
done

# Copy environment-specific files to generic files for flexibility
cp -v fib.js.node fib.js || echo "Using existing fib.js file"
cp -v fib.ts.node fib.ts || echo "Using existing fib.ts file"
cp -v fib.js.node fib.js.bun || echo "Using existing fib.js.bun file"
cp -v fib.ts.node fib.ts.bun || echo "Using existing fib.ts.bun file"

# Check if TypeScript is installed and compile TS files
if command -v tsc &> /dev/null; then
    echo "TypeScript found, compiling .ts files..."
    tsc --target ES2020 --module commonjs fib.node.ts || echo "Warning: tsc compilation of fib.node.ts failed"
    tsc --target ES2020 --module commonjs fib.ts || echo "Warning: tsc compilation of fib.ts failed"
    # Deno files don't need to be compiled as Deno handles TypeScript directly
    echo "TypeScript compilation completed"
else
    echo "TypeScript not found, skipping compilation"
fi

# Check for Node.js and test basic functionality
if command -v node &> /dev/null; then
    echo "Testing Node.js execution..."
    node -e "console.log('Node.js is working correctly')"
    
    # Test JavaScript file execution with Node.js
    if [[ -f "fib.node.js" ]]; then
        echo "Testing fib.node.js execution..."
        node fib.node.js 10 || echo "Warning: fib.node.js test failed"
    elif [[ -f "fib.js.node" ]]; then
        echo "Testing original fib.js.node execution..."
        node fib.js.node 10 || echo "Warning: fib.js.node test failed - this is expected if file extension is incorrect"
    fi
else
    echo "Node.js not found, skipping Node.js tests"
fi

# Check for Deno and test basic functionality
if command -v deno &> /dev/null; then
    echo "Testing Deno execution..."
    deno eval "console.log('Deno is working correctly')"
    
    # Test JavaScript file execution with Deno
    if [[ -f "fib.js.deno" ]]; then
        echo "Testing fib.js.deno execution..."
        deno run --allow-read fib.js.deno 10 || echo "Warning: fib.js.deno test failed"
    fi
else
    echo "Deno not found, skipping Deno tests"
fi

# Verify file existence with details
echo "Checking for JavaScript files..."
ls -la fib.js* fib.node.js

echo "Checking for TypeScript files..."
ls -la fib.ts* fib.node.ts

echo "JavaScript and TypeScript benchmark preparation complete!" 