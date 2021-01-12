(module
    (func $fib (export "fib") (param $n i32) (result i32)
        (if (result i32)
            
            ;;if $n <= 1
            (i32.le_s (local.get $n) (i32.const 1))

            (then 
                local.get $n ;;stack: n
            )

            (else 
                local.get $n ;;stack: n
                i32.const 1  ;;stack: 1, n
                i32.sub      ;;stack: n - 1
                call $fib    ;;stack: fib(n - 1)

                local.get $n ;;stack: n, fib(n - 1)
                i32.const 2  ;;stack: 2, n, fib(n - 1)
                i32.sub      ;;stack: n - 2, fib(n - 1)
                call $fib    ;;stack: fib(n - 2), fib(n - 1)

                i32.add      ;;stack: fib(n - 1) + fib(n - 2)
            )
        
        )
    
    )
)