(module
    (func $calc (export "calc") (param $a i32) (param $b i32) (param $c i32) (param $d i32) (result i32)
        local.get $a ;;stack: a
        local.get $b ;;stack: b, a
        i32.mul ;;stack: (a*b)
        local.get $c ;;stack: c, (a*b)
        local.get $d ;;stack: d, c, (a*b)
        i32.mul ;;stack: (c*d), (a*b)
        i32.sub ;;stack: (a*b) - (c*d)
    )
)