// Fibonacci implementation in TypeScript with regular numbers for Node.js
export function fibonacci(n: number): number {
  if (n <= 1) return n;

  let a: number = 0;
  let b: number = 1;

  for (let i = 2; i <= n; i++) {
    const temp: number = a + b;
    a = b;
    b = temp;
  }

  return b;
}

// Execute only if this file is being run directly (not imported)
if (require.main === module) {
  // Get command line argument or use default
  const n: number = process.argv.length > 2 ? parseInt(process.argv[2]) : 60;

  // Calculate and output result
  const result: number = fibonacci(n);
  console.log(result);
}
