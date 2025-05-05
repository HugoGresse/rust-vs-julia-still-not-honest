package main

import (
	"fmt"
	"math/big"
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
	val := fib(60)
	fmt.Println(val)
} 