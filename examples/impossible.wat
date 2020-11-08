(module
    (func $impossible (export "impossible") (param i32) (result i32)
    local.get 0
    local.get 0
        (if (i32.const 0)
            (then (i32.add))
            (else (i32.sub))
        )
    )
)
