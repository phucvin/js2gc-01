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

  (func $get_property (param $obj (ref $Object)) (param $key i32) (result anyref)
    (local $shape (ref null $Shape))
    (local.set $shape (struct.get $Object $shape (local.get $obj)))
    (loop $search
      (if (ref.is_null (local.get $shape))
        (then (return (ref.null any)))
      )
      (if (i32.eq (struct.get $Shape $key (ref.as_non_null (local.get $shape))) (local.get $key))
        (then
          (return (array.get $Storage
            (struct.get $Object $storage (local.get $obj))
            (struct.get $Shape $offset (ref.as_non_null (local.get $shape)))
          ))
        )
      )
      (local.set $shape (struct.get $Shape $parent (ref.as_non_null (local.get $shape))))
      (br $search)
    )
    (ref.null any)
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

  (func $test (export "test") (result anyref)
    (local $user_obj anyref)
(local $temp_0 (ref null $Object))

    (local.set $user_obj (block (result (ref $Object))
         (local.set $temp_0 (call $new_object (call $extend_shape (call $new_root_shape) (i32.const 0) (i32.const 0)) (i32.const 1)))
         (call $set_storage (ref.as_non_null (local.get $temp_0)) (i32.const 0) (ref.i31 (i32.const 100)))

         (ref.as_non_null (local.get $temp_0))
      ))
(ref.null any)
(drop)
(call $console_log (call $get_property (ref.cast (ref $Object) (local.get $user_obj)) (i32.const 0)))
  )
)