(module
 (type $ClosureSig0 (func (param anyref) (result anyref)))
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedI32 (struct (field i32)))
 (type $3 (func (param i32)))
 (type $4 (func (param f64)))
 (type $5 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $3) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $4) (param f64)))
 (export "main" (func $main))
 (func $console_log (type $ClosureSig0) (param $val anyref) (result anyref)
  (if
   (ref.is_null
    (local.get $val)
   )
   (then
    (nop)
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
          (nop)
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
 (func $main (type $5) (result anyref)
  (call $console_log
   (ref.null none)
  )
 )
)
