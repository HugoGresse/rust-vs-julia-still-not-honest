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
    let val = fib(60);
    println!("{}", val);
} 
