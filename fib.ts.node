// Fibonacci implementation in TypeScript with BigInt for Node.js
export function fibonacci(n: number): bigint {
  if (n <= 1) return BigInt(n);

  let a: bigint = BigInt(0);
  let b: bigint = BigInt(1);

  for (let i = 2; i <= n; i++) {
    const temp: bigint = a + b;
    a = b;
    b = temp;
  }

  return b;
}

// Default to Fibonacci of 60 as in other implementations
const n: number = process.argv.length > 2 ? parseInt(process.argv[2]) : 60;

// Calculate and output
const result: bigint = fibonacci(n);
console.log(result.toString()); 