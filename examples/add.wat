(module
    (func $add (export "add") (param i32 i32) (result i32)
    local.get 0 ;;Push first parameter to stack
    local.get 1 ;;Push second parameter to stack
    i32.add ;;Consume two values from the stack
            ;;Push the sum of these parameters back to the stack
    )
)