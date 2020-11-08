(module
    (func $factorial (export "fact") (param i32) (result i32)
        ;;Function execution starts from an empty stack
        ;;Due to the result type, the function execution should end
        ;;with a single i32 value on the stack.
        (if (result i32) ;;Both if-branches must end with 1 i32 on the stack
            (i32.lt_s (local.get 0) (i32.const 2)) ;;Condition (if n < 2)
            (then (i32.const 1)) ;;Push value 1 to stack
            (else
                (i32.sub (local.get 0) (i32.const 1)) ;;Push value n - 1 to stack
                call $factorial ;;Pops one value (n - 1) from stack and pushes
                                ;;factorial(n - 1) to stack
                local.get 0     ;;Push n to stack
                i32.mul         ;;Pops 2 values from stack (n, n - 1)
                                ;;and replaces with their multiplication
            )
        )
    )
)