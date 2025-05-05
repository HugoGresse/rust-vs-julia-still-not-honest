// TypeScript type declarations for different runtimes
declare global {
  namespace NodeJS {
    interface Process {
      argv: string[];
    }
  }

  interface Window {
    Deno?: {
      args: string[];
    };
  }
}

// Fibonacci implementation in TypeScript with BigInt
const fibonacci = function (n: number): bigint {
  if (n <= 1) return BigInt(n);

  let a: bigint = BigInt(0);
  let b: bigint = BigInt(1);

  for (let i = 2; i <= n; i++) {
    const temp: bigint = a + b;
    a = b;
    b = temp;
  }

  return b;
};

// Determine which JavaScript runtime is being used
let fibNumber = 60;

// Use try-catch for runtime detection to avoid errors
try {
  // Check for Deno
  if (typeof Deno !== "undefined") {
    if (Deno.args && Deno.args.length > 0) {
      fibNumber = parseInt(Deno.args[0]);
    }
  }
  // Check for Node.js or Bun
  else if (typeof process !== "undefined" && process.argv) {
    const args = process.argv.slice(2);
    if (args.length > 0) {
      fibNumber = parseInt(args[0]);
    }
  }
} catch (e) {
  console.error("Warning: Runtime detection issue. Using default value 60.");
}

const fibResult: bigint = fibonacci(fibNumber);

// Output only the result without any formatting (for benchmark comparison)
console.log(fibResult.toString());
