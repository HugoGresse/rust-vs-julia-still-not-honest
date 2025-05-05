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

my $val = fib(60);
print "$val\n"; 