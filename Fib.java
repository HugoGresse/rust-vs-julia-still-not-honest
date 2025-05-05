public class Fib {
    public static long fib(int n) {
        if (n == 1 || n == 2) {
            return 1;
        }
        
        long a = 1;
        long b = 1;
        
        for (int i = 3; i <= n; i++) {
            long next = a + b;
            a = b;
            b = next;
        }
        
        return b;
    }
    
    public static void main(String[] args) {
        // Parse command line arguments
        int n = (args.length > 0) ? Integer.parseInt(args[0]) : 60;
        int runs = (args.length > 1) ? Integer.parseInt(args[1]) : 1;
        
        // Internal benchmarking loop
        long result = 0;
        for (int i = 0; i < runs; i++) {
            result = fib(n);
        }
        
        // Output result
        System.out.println(result);
    }
} 