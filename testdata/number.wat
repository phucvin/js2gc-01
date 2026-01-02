(module
  (rec
    (type $Shape (struct
      (field $parent (ref null $Shape))
      (field $key i32)
      (field $offset i32)
    ))

    (type $Storage (array (mut anyref)))

    (type $Object (struct
      (field $shape (mut (ref $Shape)))
      (field $storage (mut (ref $Storage)))
    ))

    (type $CallSite (struct
      (field $expected_shape (mut (ref null $Shape)))
      (field $offset (mut i32))
    ))
  )

  (type $BoxedF64 (struct (field f64)))
  (type $BoxedI32 (struct (field i32)))
  (type $BoxedString (struct (field (ref string))))
  (import "env" "print_i32" (func $print_i32 (param i32)))
  (import "env" "print_f64" (func $print_f64 (param f64)))
  (import "env" "print_string" (func $print_string (param (ref string))))

  (func $new_root_shape (result (ref $Shape))
    (struct.new $Shape
      (ref.null $Shape)
      (i32.const -1)
      (i32.const -1)
    )
  )

  (func $extend_shape (param $parent (ref $Shape)) (param $key i32) (param $offset i32) (result (ref $Shape))
    (struct.new $Shape
      (local.get $parent)
      (local.get $key)
      (local.get $offset)
    )
  )

  (func $new_object (param $shape (ref $Shape)) (param $size i32) (result (ref $Object))
    (struct.new $Object
      (local.get $shape)
      (array.new_default $Storage (local.get $size))
    )
  )

  (func $set_storage (param $obj (ref $Object)) (param $idx i32) (param $val anyref)
    (array.set $Storage (struct.get $Object $storage (local.get $obj))
      (local.get $idx)
      (local.get $val)
    )
  )

  (func $new_callsite (result (ref $CallSite))
    (struct.new $CallSite
      (ref.null $Shape)
      (i32.const -1)
    )
  )

  (func $lookup_in_shape (param $shape (ref $Shape)) (param $key i32) (result i32)
    (local $curr (ref null $Shape))
    (local.set $curr (local.get $shape))

    (loop $search
      (if (ref.is_null (local.get $curr))
        (then (return (i32.const -1)))
      )

      (if (i32.eq (struct.get $Shape $key (ref.as_non_null (local.get $curr))) (local.get $key))
        (then (return (struct.get $Shape $offset (ref.as_non_null (local.get $curr)))))
      )

      (local.set $curr (struct.get $Shape $parent (ref.as_non_null (local.get $curr))))
      (br $search)
    )
    (i32.const -1)
  )

  (func $get_field_slow (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
    (local $offset i32)
    (local $shape (ref $Shape))

    (local.set $shape (struct.get $Object $shape (local.get $obj)))
    (local.set $offset (call $lookup_in_shape (local.get $shape) (local.get $key)))

    (if (i32.ge_s (local.get $offset) (i32.const 0))
      (then
        (struct.set $CallSite $expected_shape (local.get $cache) (local.get $shape))
        (struct.set $CallSite $offset (local.get $cache) (local.get $offset))
        (return (array.get $Storage (struct.get $Object $storage (local.get $obj)) (local.get $offset)))
      )
    )
    (ref.null any)
  )

  (func $get_field_cached (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
    (if (ref.eq
          (struct.get $Object $shape (local.get $obj))
          (struct.get $CallSite $expected_shape (local.get $cache))
        )
      (then
        (return (array.get $Storage
          (struct.get $Object $storage (local.get $obj))
          (struct.get $CallSite $offset (local.get $cache))
        ))
      )
    )
    (call $get_field_slow (local.get $obj) (local.get $cache) (local.get $key))
  )

  (func $console_log (param $val anyref) (result anyref)
    (if (ref.is_null (local.get $val))
      (then
        (call $print_string (string.const "null"))
      )
      (else
        (if (ref.test (ref i31) (local.get $val))
          (then
            (call $print_i32 (i31.get_s (ref.cast (ref i31) (local.get $val))))
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
                      (else
                         (if (ref.test (ref $Object) (local.get $val))
                           (then
                             (call $print_string (string.const "[object Object]"))
                           )
                         )
                      )
                    )
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
    (if (result anyref) (ref.test (ref i31) (local.get $lhs))
      (then
        (if (result anyref) (ref.test (ref i31) (local.get $rhs))
          (then
            (ref.i31 (i32.add
              (i31.get_s (ref.cast (ref i31) (local.get $lhs)))
              (i31.get_s (ref.cast (ref i31) (local.get $rhs)))
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

  (func $less_than (param $lhs anyref) (param $rhs anyref) (result anyref)
    (if (result anyref) (ref.test (ref i31) (local.get $lhs))
      (then
        (if (result anyref) (ref.test (ref i31) (local.get $rhs))
          (then
            (ref.i31 (i32.lt_s
              (i31.get_s (ref.cast (ref i31) (local.get $lhs)))
              (i31.get_s (ref.cast (ref i31) (local.get $rhs)))
            ))
          )
          (else
            (ref.i31 (i32.const 0))
          )
        )
      )
      (else
        (ref.i31 (i32.const 0))
      )
    )
  )

  (func $main (export "main") (result anyref)

    (return (ref.i31 (i32.const 42)))
  )
  (func $test (export "test") (result anyref)

    (call $console_log (call $main))
  )
)