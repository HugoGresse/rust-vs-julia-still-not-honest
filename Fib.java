import java.math.BigInteger;

public class Fib {
    public static BigInteger fib(int n) {
        if (n == 1 || n == 2) {
            return BigInteger.ONE;
        }
        
        BigInteger a = BigInteger.ONE;
        BigInteger b = BigInteger.ONE;
        
        for (int i = 3; i <= n; i++) {
            BigInteger next = a.add(b);
            a = b;
            b = next;
        }
        
        return b;
    }
    
    public static void main(String[] args) {
        BigInteger val = fib(60);
        System.out.println(val);
    }
} 