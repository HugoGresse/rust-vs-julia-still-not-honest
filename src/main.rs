fn fib(n: u32) -> u64 {
    if n == 1 || n == 2 {
        return 1;
    }
    
    let mut a: u64 = 1;
    let mut b: u64 = 1;
    
    for _ in 3..=n {
        let next = a + b;
        a = b;
        b = next;
    }
    
    b
}

fn main() {
    // Parse command line arguments
    let args: Vec<String> = std::env::args().collect();
    
    let n: u32 = args.get(1).and_then(|s| s.parse().ok()).unwrap_or(60);
    let runs: u32 = args.get(2).and_then(|s| s.parse().ok()).unwrap_or(1);
    
    // Internal benchmarking loop
    let mut result = 0;
    for _ in 0..runs {
        result = fib(n);
    }
    
    // Only print the result once
    println!("{}", result);
} 
