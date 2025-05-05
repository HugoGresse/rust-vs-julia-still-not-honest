// Simple Fibonacci implementation for Deno

function fibonacci(n) {
  if (n <= 1) return BigInt(n);

  let a = BigInt(0);
  let b = BigInt(1);

  for (let i = 2; i <= n; i++) {
    const temp = a + b;
    a = b;
    b = temp;
  }

  return b;
}

// Use a fixed value to avoid parsing arguments
const n = 60;

// Calculate and output
const result = fibonacci(n);
console.log(result.toString());
