package main

import "fmt"

func fib(n uint) uint64 {
	if n == 1 || n == 2 {
		return 1
	}

	var a, b uint64 = 1, 1

	for i := uint(3); i <= n; i++ {
		a, b = b, a+b
	}

	return b
}

func main() {
	val := fib(60)
	fmt.Println(val)
} 