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
 (type $String (array (mut i8)))
 (type $BoxedString (struct (field (ref $String))))
 (type $12 (func (param i32)))
 (type $13 (func (param f64)))
 (type $14 (func (param (ref $String))))
 (type $15 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $12) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $13) (param f64)))
 (import "env" "print_string" (func $print_string (type $14) (param (ref $String))))
 (export "main" (func $main))
 (func $console_log (type $ClosureSig0) (param $val anyref) (result anyref)
  (if
   (ref.is_null
    (local.get $val)
   )
   (then
    (call $print_string
     (array.new_fixed $String 4
      (i32.const 110)
      (i32.const 117)
      (i32.const 108)
      (i32.const 108)
     )
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
               (array.new_fixed $String 15
                (i32.const 91)
                (i32.const 111)
                (i32.const 98)
                (i32.const 106)
                (i32.const 101)
                (i32.const 99)
                (i32.const 116)
                (i32.const 32)
                (i32.const 79)
                (i32.const 98)
                (i32.const 106)
                (i32.const 101)
                (i32.const 99)
                (i32.const 116)
                (i32.const 93)
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
  )
  (ref.null none)
 )
 (func $main (type $15) (result anyref)
  (call $console_log
   (ref.i31
    (i32.const 100)
   )
  )
 )
)
