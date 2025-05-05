const std = @import("std");

fn fib(n: u32) u128 {
    if (n == 1 or n == 2) {
        return 1;
    }
    
    var a: u128 = 1;
    var b: u128 = 1;
    
    var i: u32 = 3;
    while (i <= n) : (i += 1) {
        const next = a + b;
        a = b;
        b = next;
    }
    
    return b;
}

pub fn main() !void {
    const val = fib(60);
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{}\n", .{val});
} 