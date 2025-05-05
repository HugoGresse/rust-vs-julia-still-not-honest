// Fibonacci implementation in TypeScript with BigInt
// This is a simplified version that doesn't depend on Node.js types

namespace FibonacciCalculation {
  // The main fibonacci calculation function
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

  // Use a fixed value rather than command line arguments
  const n: number = 60; // Default to Fibonacci of 60 as in other implementations

  // Calculate and output
  const result: bigint = fibonacci(n);
  console.log(result.toString());
}
