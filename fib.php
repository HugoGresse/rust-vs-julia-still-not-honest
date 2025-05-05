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

$val = fib(60);
echo $val . "\n";
?> 