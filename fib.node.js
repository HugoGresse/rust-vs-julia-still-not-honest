// Fibonacci implementation in JavaScript with regular numbers for Node.js
function fibonacci(n) {
  if (n <= 1) return n;

  let a = 0;
  let b = 1;

  for (let i = 2; i <= n; i++) {
    const temp = a + b;
    a = b;
    b = temp;
  }

  return b;
}

// Parse command line arguments
const n = process.argv.length > 2 ? parseInt(process.argv[2]) : 60;
const runs = process.argv.length > 3 ? parseInt(process.argv[3]) : 1;

// Internal benchmarking loop
let result;
for (let i = 0; i < runs; i++) {
  result = fibonacci(n);
}

// Output result
console.log(result);
