<?php
function fib($n) {
    if ($n == 1 || $n == 2) {
        return 1;
    }
    
    $a = 1;
    $b = 1;
    
    for ($i = 3; $i <= $n; $i++) {
        $next = $a + $b;
        $a = $b;
        $b = $next;
    }
    
    return $b;
}

// Parse command line arguments
$n = isset($argv[1]) ? (int)$argv[1] : 60;
$runs = isset($argv[2]) ? (int)$argv[2] : 1;

// Internal benchmarking loop
$result = null;
for ($i = 0; $i < $runs; $i++) {
    $result = fib($n);
}

// Output result
echo $result;
?> 