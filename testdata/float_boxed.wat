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
 (type $14 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $11) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $12) (param f64)))
 (import "env" "print_string" (func $print_string (type $13) (param (ref string))))
 (export "main" (func $main))
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
 (func $main (type $14) (result anyref)
  (call $console_log
   (struct.new $BoxedF64
    (f64.const 1234.56)
   )
  )
 )
)
