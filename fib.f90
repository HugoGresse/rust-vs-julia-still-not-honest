program fibonacci
    implicit none
    integer, parameter :: int64 = selected_int_kind(18)
    integer :: i
    integer(kind=int64) :: a, b, next, val
    
    val = fib(60)
    print *, val
    
contains
    function fib(n) result(res)
        integer, intent(in) :: n
        integer(kind=int64) :: res
        integer(kind=int64) :: a, b, next
        integer :: i
        
        if (n == 1 .or. n == 2) then
            res = 1
            return
        end if
        
        a = 1
        b = 1
        
        do i = 3, n
            next = a + b
            a = b
            b = next
        end do
        
        res = b
    end function fib
end program fibonacci 