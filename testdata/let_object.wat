(module
 (rec
  (type $Shape (struct (field $parent (ref null $Shape)) (field $key i32) (field $offset i32)))
  (type $Storage (array (mut anyref)))
  (type $Object (struct (field $shape (mut (ref $Shape))) (field $storage (mut (ref $Storage)))))
  (type $CallSite (struct (field $expected_shape (mut (ref null $Shape))) (field $offset (mut i32))))
  (type $Closure (struct (field $func funcref) (field $env anyref)))
  (type $BinaryOpFunc (func (param anyref anyref) (result anyref)))
  (type $BinaryOpCallSite (struct (field $type_lhs (mut i32)) (field $type_rhs (mut i32)) (field $target (mut (ref null $BinaryOpFunc)))))
 )
 (type $ClosureSig0 (func (param anyref) (result anyref)))
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedI32 (struct (field i32)))
 (type $BoxedString (struct (field (ref string))))
 (type $11 (func (param i32)))
 (type $12 (func (param f64)))
 (type $13 (func (param (ref string))))
 (type $14 (func (result (ref $Shape))))
 (type $15 (func (param (ref $Shape) i32 i32) (result (ref $Shape))))
 (type $16 (func (param (ref $Shape) i32) (result (ref $Object))))
 (type $17 (func (param (ref $Object) i32 anyref)))
 (type $18 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $11) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $12) (param f64)))
 (import "env" "print_string" (func $print_string (type $13) (param (ref string))))
 (export "test" (func $test))
 (func $new_root_shape (type $14) (result (ref $Shape))
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
 )
 (func $extend_shape (type $15) (param $parent (ref $Shape)) (param $key i32) (param $offset i32) (result (ref $Shape))
  (struct.new $Shape
   (local.get $parent)
   (local.get $key)
   (local.get $offset)
  )
 )
 (func $new_object (type $16) (param $shape (ref $Shape)) (param $size i32) (result (ref $Object))
  (struct.new $Object
   (local.get $shape)
   (array.new_default $Storage
    (local.get $size)
   )
  )
 )
 (func $set_storage (type $17) (param $obj (ref $Object)) (param $idx i32) (param $val anyref)
  (array.set $Storage
   (struct.get $Object $storage
    (local.get $obj)
   )
   (local.get $idx)
   (local.get $val)
  )
 )
 (func $console_log (type $ClosureSig0) (param $val anyref) (result anyref)
  (if
   (ref.is_null
    (local.get $val)
   )
   (then
    (call $print_string
     (string.const "null")
    )
   )
   (else
    (if
     (ref.test (ref i31)
      (local.get $val)
     )
     (then
      (call $print_i32
       (i31.get_s
        (ref.cast (ref i31)
         (local.get $val)
        )
       )
      )
     )
     (else
      (if
       (ref.test (ref $BoxedI32)
        (local.get $val)
       )
       (then
        (call $print_i32
         (struct.get $BoxedI32 0
          (ref.cast (ref $BoxedI32)
           (local.get $val)
          )
         )
        )
       )
       (else
        (if
         (ref.test (ref $BoxedF64)
          (local.get $val)
         )
         (then
          (call $print_f64
           (struct.get $BoxedF64 0
            (ref.cast (ref $BoxedF64)
             (local.get $val)
            )
           )
          )
         )
         (else
          (if
           (ref.test (ref $BoxedString)
            (local.get $val)
           )
           (then
            (call $print_string
             (struct.get $BoxedString 0
              (ref.cast (ref $BoxedString)
               (local.get $val)
              )
             )
            )
           )
           (else
            (if
             (ref.test (ref $Object)
              (local.get $val)
             )
             (then
              (call $print_string
               (string.const "[object Object]")
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
  )
  (ref.null none)
 )
 (func $test (type $18) (result anyref)
  (local $user_obj anyref)
  (local $temp_0 (ref null $Object))
  (local.set $user_obj
   (block (result (ref $Object))
    (local.set $temp_0
     (call $new_object
      (call $extend_shape
       (call $new_root_shape)
       (i32.const 0)
       (i32.const 0)
      )
      (i32.const 1)
     )
    )
    (call $set_storage
     (ref.as_non_null
      (local.get $temp_0)
     )
     (i32.const 0)
     (ref.i31
      (i32.const 10)
     )
    )
    (ref.as_non_null
     (local.get $temp_0)
    )
   )
  )
  (drop
   (ref.null none)
  )
  (call $console_log
   (local.get $user_obj)
  )
 )
)
