// Simple Fibonacci implementation for Deno using regular numbers
function fibonacci(n: number): number {
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

// Get command line arguments or use default
const n: number = Deno.args.length > 0 ? parseInt(Deno.args[0]) : 60;
console.log(fibonacci(n));
