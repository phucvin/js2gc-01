(module
  (type $BoxedF64 (struct (field f64)))
  (type $BoxedI32 (struct (field i32)))
  (type $BoxedString (struct (field (ref string))))
  (import "env" "print_i32" (func $print_i32 (param i32)))
  (import "env" "print_f64" (func $print_f64 (param f64)))
  (import "env" "print_string" (func $print_string (param (ref string))))

  (func $console_log (param $val anyref) (result anyref)
    (if (ref.test i31ref (local.get $val))
      (then
        (call $print_i32 (i31.get_s (ref.cast i31ref (local.get $val))))
      )
      (else
        (if (ref.test (ref $BoxedI32) (local.get $val))
          (then
            (call $print_i32 (struct.get $BoxedI32 0 (ref.cast (ref $BoxedI32) (local.get $val))))
          )
          (else
            (if (ref.test (ref $BoxedF64) (local.get $val))
              (then
                (call $print_f64 (struct.get $BoxedF64 0 (ref.cast (ref $BoxedF64) (local.get $val))))
              )
              (else
                (if (ref.test (ref $BoxedString) (local.get $val))
                  (then
                    (call $print_string (struct.get $BoxedString 0 (ref.cast (ref $BoxedString) (local.get $val))))
                  )
                )
              )
            )
          )
        )
      )
    )
    (ref.null any)
  )

  (func $add (param $lhs anyref) (param $rhs anyref) (result anyref)
    (if (result anyref) (ref.test i31ref (local.get $lhs))
      (then
        (if (result anyref) (ref.test i31ref (local.get $rhs))
          (then
            (ref.i31 (i32.add
              (i31.get_s (ref.cast i31ref (local.get $lhs)))
              (i31.get_s (ref.cast i31ref (local.get $rhs)))
            ))
          )
          (else
            (ref.null any)
          )
        )
      )
      (else
        (ref.null any)
      )
    )
  )

  (func $main (export "main") (result anyref)
    (struct.new $BoxedF64 (f64.const 1234.56))
  )
  (func $test (export "test") (result anyref)
    (call $console_log (call $main))
  )
)