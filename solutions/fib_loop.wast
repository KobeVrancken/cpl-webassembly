(module
    
    ;;https://stackoverflow.com/questions/15047116/an-iterative-algorithm-for-fibonacci-numbers
    (func $fib (export "fib") (param $n i32) (result i32)
        (local $a i32)
        (local $b i32)

        i32.const 0  ;;stack: 0
        local.set $a ;;a = 0, stack: <empty>
        
        i32.const 1  ;;stack: 1
        local.set $b ;;b = 1, stack: <empty>
        (loop $fibloop
            local.get $a    ;;stack: a
            local.get $b    ;;stack: b, a
            i32.add         ;;stack: a + b
            local.get $b    ;;stack: a, a + b
            local.set $a    ;;b = a, stack: a + b
            local.set $b    ;;b = a + b, stack: <empty>

            local.get $n    ;;stack: n
            i32.const 1     ;;stack: 1, n
            i32.sub         ;;stack: n - 1
            local.tee $n    ;;n = n - 1, stack: n - 1 

            i32.const 1     ;;stack: 1, n - 1
            i32.gt_s        ;;stack: n - 1 > 1
            br_if $fibloop  ;;stack: <empty>
        )
        local.get $b ;;stack: $b
    )
)