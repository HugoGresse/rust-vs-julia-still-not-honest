// Fibonacci implementation in JavaScript with BigInt
const fibonacci = function (n) {
  if (n <= 1) return BigInt(n);

  let a = BigInt(0);
  let b = BigInt(1);

  for (let i = 2; i <= n; i++) {
    const temp = a + b;
    a = b;
    b = temp;
  }

  return b;
};

// Determine which JavaScript runtime is being used
let commandArgs;
let fibN = 60;

// Use try-catch for runtime detection to avoid errors
try {
  // Check for Deno
  if (typeof Deno !== "undefined") {
    commandArgs = Deno.args || [];
    if (commandArgs.length > 0) {
      fibN = parseInt(commandArgs[0]);
    }
  }
  // Check for Node.js or Bun
  else if (typeof process !== "undefined" && process.argv) {
    commandArgs = process.argv.slice(2);
    if (commandArgs.length > 0) {
      fibN = parseInt(commandArgs[0]);
    }
  }
} catch (e) {
  console.error("Warning: Runtime detection issue. Using default value 60.");
}

const fibResult = fibonacci(fibN);

// Output only the result without any formatting (for benchmark comparison)
console.log(fibResult.toString());
