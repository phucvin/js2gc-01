(module
  (func $main (export "main") (result i32)
    (local $s (ref string))
    (local $len i32)

    ;; Create a string "Hello"
    (local.set $s (string.const "Hello"))

    ;; Check if string equals "Hello" (returns 1 if true)
    (if (i32.eq (string.eq (local.get $s) (string.const "Hello")) (i32.const 1))
      (then
        ;; Check if concatenation works
        (local.set $s (string.concat (local.get $s) (string.const " World")))

        ;; Check if result is "Hello World"
        (if (string.eq (local.get $s) (string.const "Hello World"))
          (then
            (return (i32.const 1)) ;; Success
          )
        )
      )
    )

    (i32.const 0) ;; Failure
  )
)
