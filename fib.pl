#!/usr/bin/env perl
use strict;
use warnings;
use bigint;

sub fib {
    my ($n) = @_;
    
    if ($n == 1 || $n == 2) {
        return 1;
    }
    
    my $a = 1;
    my $b = 1;
    
    for (my $i = 3; $i <= $n; $i++) {
        my $next = $a + $b;
        $a = $b;
        $b = $next;
    }
    
    return $b;
}

# Parse command line arguments
my $n = $ARGV[0] || 60;
my $runs = $ARGV[1] || 1;

# Internal benchmarking loop
my $result;
for (my $i = 0; $i < $runs; $i++) {
    $result = fib($n);
}

# Output result
print "$result\n"; 