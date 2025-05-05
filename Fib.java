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
        long val = fib(60);
        System.out.println(val);
    }
} 