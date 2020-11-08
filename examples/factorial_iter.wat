(module
    (func $factorial (export "fact") (param i32) (result i32)
        (local $res i32) ;;stack = <empty> || declare local var res
        (local.set $res (i32.const 1)) ;;stack = <empty> || $res = 1
        (loop $fact (result i32)
            local.get 0     ;;stack: n
            local.get 0     ;;stack: n, n
            local.get $res  ;;stack: $res, n, n
            i32.mul         ;;stack: n * $res, n
            local.set $res  ;;stack: n || $res = n * $res 
            i32.const 1     ;;stack: 1, n
            i32.sub         ;;stack: n - 1
            local.tee 0     ;;stack: n - 1 || n = n - 1
            i32.const 1     ;;stack: 1, n - 1
            i32.gt_s        ;;stack: n - 1 > 1
            br_if $fact     ;;stack: <empty>
            local.get $res  ;;stack: $res
        )
    )
)