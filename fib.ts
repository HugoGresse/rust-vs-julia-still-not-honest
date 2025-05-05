#!/usr/bin/env node
/**
 * TypeScript Fibonacci implementation
 * Can be used with Node.js or Deno after transpilation
 *
 * Determines which runtime environment is being used and
 * processes arguments accordingly.
 */

// Runtime detection utility
const detectRuntime = (): "node" | "deno" | "browser" | "unknown" => {
  try {
    if (typeof Deno !== "undefined") return "deno";
    if (
      typeof process !== "undefined" &&
      process.versions &&
      process.versions.node
    )
      return "node";
    if (typeof window !== "undefined") return "browser";
  } catch (e) {
    /* Ignore errors during detection */
  }
  return "unknown";
};

// Fibonacci implementation in TypeScript with regular numbers
const fibonacci = function (n: number): number {
  if (n <= 1) return n;

  let a: number = 0;
  let b: number = 1;

  for (let i = 2; i <= n; i++) {
    const temp: number = a + b;
    a = b;
    b = temp;
  }

  return b;
};

// Main execution
const main = () => {
  // Default fibonacci number to calculate
  let fibNumber = 45; // Reduced from 60 to use regular number

  // Process arguments based on runtime
  const runtime = detectRuntime();

  try {
    if (runtime === "deno") {
      // @ts-ignore: Deno-specific property
      const args = Deno.args;
      if (args && args.length > 0) {
        fibNumber = parseInt(args[0], 10);
      }
    } else if (runtime === "node") {
      const args = process.argv.slice(2);
      if (args.length > 0) {
        fibNumber = parseInt(args[0], 10);
      }
    }
  } catch (e) {
    console.error("Error processing arguments:", e);
  }

  // Calculate and output
  const fibResult: number = fibonacci(fibNumber);
  console.log(fibResult);
};

// Execute main function
main();
