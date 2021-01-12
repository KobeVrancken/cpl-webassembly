(module
    ;; Import the required fd_write WASI function which will write the given io vectors to stdout
    ;; The function signature for fd_write is:
    ;; (File Descriptor, *iovs, iovs_len, nwritten) -> Returns number of bytes written
    (import "wasi_unstable" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))

    (memory $mem 1)
    (export "memory" (memory $mem))

    (data (i32.const 8) "0")
    (data (i32.const 10) "Fizz\n")
    (data (i32.const 15) "Buzz\n")
    (data (i32.const 20) "FizzBuzz\n")

    (func $print (param $addr i32) (param $len i32)
        (i32.store (i32.const 0) (local.get $addr))
        (i32.store (i32.const 4) (local.get $len))
        (call $fd_write
            (i32.const 1)
            (i32.const 0)
            (i32.const 1)
            (i32.const 0)
        )
        drop
    )

    (func $print_fizz
        (call $print  (i32.const 10) (i32.const 5))
    )

    (func $print_buzz
        (call $print  (i32.const 15) (i32.const 5))
    )

    (func $print_fizzbuzz
        (call $print  (i32.const 20) (i32.const 9))
    )

    (func $print_char (param i32)
        (i32.store8 (i32.const 8) (local.get 0)) ;;convert to byte representation
        (call $print  (i32.const 8) (i32.const 1))
    )

    ;;https://stackoverflow.com/questions/15921047/printing-the-digits-of-an-integer-in-correct-order-using-recursion
    (func $print_uint (param i32)
        (local $div10 i32)
        (local.set $div10 (i32.div_u (local.get 0) (i32.const 10))) ;; $div10 = n / 10
        (if
            (i32.gt_u (local.get $div10) (i32.const 0))
            (call $print_uint (local.get $div10))
        )
        (call $print_char (i32.add (i32.rem_u (local.get 0) (i32.const 10)) (i32.const 48)))
    )

    (func $can_divide (param $a i32) (param $b i32) (result i32)
         local.get $a ;;stack: a
         local.get $b ;;stack: b, a
         i32.rem_s    ;;stack: a % b
         i32.const 0  ;;stack: 0, a % b
         i32.eq       ;;stack: a % b == 0
    )

    (func $fizzbuzz
        (local $i i32)
        (local $div3 i32)
        (local $div5 i32)
        (local $div3and5 i32)
        i32.const 1
        local.set $i
        (loop $fizzbuzzloop
            local.get $i ;;stack: i
            i32.const 3  ;;stack: 3, i
            call $can_divide ;;stack: (i % 3 == 0)
            local.tee $div3 ;; $div3 = (i % 3 == 0), stack: (i % 3 == 0)

            local.get $i ;;stack: i, (i % 3 == 0)
            i32.const 5  ;;stack: 5, i, (i % 3 == 0)
            call $can_divide ;;stack: (i % 5 == 0), (i % 3 == 0)
            local.tee $div5 ;; $div5 = (i % 5 == 0), stack: (i % 5 == 0), (i % 3 == 0)

            i32.and ;;stack: (i % 5 == 0) & (i % 3 == 0) <= binary and used here, works!
            i32.const 1 ;; stack: 1, (i % 5 == 0) & (i % 3 == 0)
            i32.eq ;;stack: ((i % 5 == 0) & (i % 3 == 0)) == 1
            local.set $div3and5 ;;stack: <empty>

            (if
                (local.get $div3and5)
                (then 
                    call $print_fizzbuzz
                )
                (else
                    (if
                        (local.get $div3)
                        (then
                            call $print_fizz
                        )
                        (else
                            (if
                                (local.get $div5)
                                (then
                                    call $print_buzz
                                )
                                (else
                                    local.get $i
                                    call $print_uint
                                    i32.const 10
                                    call $print_char ;;print \n
                                )
                            )
                        )
                    )
                )
            )

            local.get $i ;;stack: i
            i32.const 1  ;;stack: 1, i
            i32.add    ;;stack: i + 1
            local.tee $i ;;i = i + 1, stack: i + 1 
            i32.const 100 ;;stack: 100, i + 1
            i32.le_s ;;stack: i + 1 < 100
            br_if $fizzbuzzloop
        )
    )
    

    (func $main (export "_start")
        (call $fizzbuzz)
    )
)
