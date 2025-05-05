package main

import (
	"fmt"
	"math/big"
	"os"
	"strconv"
)

func fib(n uint) *big.Int {
	if n == 1 || n == 2 {
		return big.NewInt(1)
	}

	a := big.NewInt(1)
	b := big.NewInt(1)
	
	for i := uint(3); i <= n; i++ {
		// Create temporary value for a+b
		next := new(big.Int).Add(a, b)
		a = b
		b = next
	}

	return b
}

func main() {
	// Parse command line arguments
	n := uint(60)
	runs := uint(1)
	
	if len(os.Args) > 1 {
		if val, err := strconv.ParseUint(os.Args[1], 10, 64); err == nil {
			n = uint(val)
		}
	}
	
	if len(os.Args) > 2 {
		if val, err := strconv.ParseUint(os.Args[2], 10, 64); err == nil {
			runs = uint(val)
		}
	}
	
	// Internal benchmarking loop
	var result *big.Int
	for i := uint(0); i < runs; i++ {
		result = fib(n)
	}
	
	// Print the result
	fmt.Println(result)
} 