#!/usr/bin/env bash
set -e

echo "Compiling TypeScript files to JavaScript..."

# Check if TypeScript compiler is available
if ! command -v tsc &> /dev/null; then
    echo "TypeScript compiler not found. Attempting to install..."
    npm install -g typescript
fi

# Check for @types/node and install if needed
if ! npm list -g @types/node &> /dev/null; then
    echo "Installing @types/node..."
    npm install -g @types/node
fi

# Create a temporary tsconfig.json if it doesn't exist
if [ ! -f "tsconfig.json" ]; then
    echo "Creating temporary tsconfig.json..."
    cat > tsconfig.json << EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": ".",
    "typeRoots": ["./node_modules/@types", "/usr/lib/node_modules/@types"],
    "types": ["node"]
  }
}
EOF
fi

# Add node reference to TypeScript files if missing
for file in fib.node.ts fib.ts fib.ts.deno; do
    if [ -f "$file" ]; then
        if ! grep -q "reference types=\"node\"" "$file"; then
            echo "Adding Node.js type reference to $file..."
            temp_file=$(mktemp)
            echo '/// <reference types="node" />' > "$temp_file"
            cat "$file" >> "$temp_file"
            mv "$temp_file" "$file"
        fi
    fi
done

# Compile TypeScript files
for file in fib.node.ts fib.ts fib.ts.deno fib.node.simple.ts fib.ts.deno.simple.ts; do
    if [ -f "$file" ]; then
        echo "Compiling $file..."
        tsc "$file" || echo "Failed to compile $file"
    fi
done

# Create alternative versions without exports but with Node.js references
for file in fib.node.ts fib.ts; do
    if [ -f "$file" ]; then
        echo "Creating alternative version of $file without exports..."
        # Create an alternative version without exports
        base_name="${file%.*}"
        alt_file="${base_name}_alt.ts"
        sed 's/export function/function/g' "$file" > "$alt_file"
        
        # Make sure the alternative file has Node.js reference
        if ! grep -q "reference types=\"node\"" "$alt_file"; then
            temp_file=$(mktemp)
            echo '/// <reference types="node" />' > "$temp_file"
            cat "$alt_file" >> "$temp_file"
            mv "$temp_file" "$alt_file"
        fi
        
        tsc "$alt_file" || echo "Failed to compile $alt_file"
    fi
done

echo "TypeScript compilation complete!" 