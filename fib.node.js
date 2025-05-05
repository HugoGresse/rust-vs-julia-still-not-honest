// Fibonacci implementation in JavaScript with BigInt for Node.js
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

// Default to Fibonacci of 60 as in other implementations
const n = process.argv.length > 2 ? parseInt(process.argv[2]) : 60;

// Calculate and output
const result = fibonacci(n);
console.log(result.toString()); 