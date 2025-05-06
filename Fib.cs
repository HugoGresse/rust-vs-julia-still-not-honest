using System;
using System.Numerics;

public class Fib
{
    public static object Calculate(int n)
    {
        if (n <= 0)
        {
            throw new ArgumentException("Input must be a positive integer");
        }
        
        if (n == 1 || n == 2)
        {
            return 1;
        }
        
        // Use long for n <= 60, BigInteger for n > 60
        if (n <= 60)
        {
            long a = 1;
            long b = 1;
            
            for (int i = 3; i <= n; i++)
            {
                long next = a + b;
                a = b;
                b = next;
            }
            
            return b;
        }
        else
        {
            BigInteger a = 1;
            BigInteger b = 1;
            
            for (int i = 3; i <= n; i++)
            {
                BigInteger next = a + b;
                a = b;
                b = next;
            }
            
            return b;
        }
    }
    
    public static void Main(string[] args)
    {
        // Parse command line arguments
        int n = args.Length > 0 ? int.Parse(args[0]) : 60;
        int runs = args.Length > 1 ? int.Parse(args[1]) : 1;
        
        // Internal benchmarking loop
        object result = null;
        for (int i = 0; i < runs; i++)
        {
            result = Calculate(n);
        }
        
        // Output the result
        Console.WriteLine(result);
    }
} 