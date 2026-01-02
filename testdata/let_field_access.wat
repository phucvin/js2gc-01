(module
 (rec
  (type $Shape (struct (field $parent (ref null $Shape)) (field $key i32) (field $offset i32)))
  (type $Storage (array (mut anyref)))
  (type $Object (struct (field $shape (mut (ref $Shape))) (field $storage (mut (ref $Storage)))))
  (type $CallSite (struct (field $expected_shape (mut (ref null $Shape))) (field $offset (mut i32))))
 )
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedI32 (struct (field i32)))
 (type $BoxedString (struct (field (ref string))))
 (type $7 (func (param i32)))
 (type $8 (func (param f64)))
 (type $9 (func (param (ref string))))
 (type $10 (func))
 (type $11 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $7) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $8) (param f64)))
 (import "env" "print_string" (func $print_string (type $9) (param (ref string))))
 (global $"string.const_\"[object Object]\"" (ref string) (string.const "[object Object]"))
 (global $"string.const_\"null\"" (ref string) (string.const "null"))
 (global $init_done (mut i32) (i32.const 0))
 (global $site_0 (mut (ref null $CallSite)) (ref.null none))
 (export "test" (func $test))
 (start $init_globals)
 (func $init_globals (type $10)
  (if
   (i32.eqz
    (global.get $init_done)
   )
   (then
    (global.set $site_0
     (struct.new $CallSite
      (ref.null none)
      (i32.const -1)
     )
    )
    (global.set $init_done
     (i32.const 1)
    )
   )
  )
 )
 (func $test (type $11) (result anyref)
  (local $0 anyref)
  (local $1 (ref null $Shape))
  (local $2 (ref $CallSite))
  (local $3 (ref (exact $Storage)))
  (local $4 i32)
  (local $5 (ref (exact $Shape)))
  (local $6 (ref null (exact $Shape)))
  (array.set $Storage
   (local.tee $3
    (array.new_default $Storage
     (i32.const 1)
    )
   )
   (i32.const 0)
   (ref.i31
    (i32.const 100)
   )
  )
  (if
   (ref.is_null
    (local.tee $0
     (block $__inlined_func$get_field_cached$6 (result anyref)
      (if
       (ref.eq
        (local.tee $5
         (struct.new $Shape
          (struct.new $Shape
           (ref.null none)
           (i32.const -1)
           (i32.const -1)
          )
          (i32.const 0)
          (i32.const 0)
         )
        )
        (struct.get $CallSite $expected_shape
         (local.tee $2
          (ref.as_non_null
           (global.get $site_0)
          )
         )
        )
       )
       (then
        (br $__inlined_func$get_field_cached$6
         (array.get $Storage
          (local.get $3)
          (struct.get $CallSite $offset
           (local.get $2)
          )
         )
        )
       )
      )
      (block $__inlined_func$get_field_slow$8 (result anyref)
       (if
        (i32.ge_s
         (local.tee $4
          (block $__inlined_func$lookup_in_shape$1 (result i32)
           (local.set $1
            (ref.as_non_null
             (local.tee $6
              (local.get $5)
             )
            )
           )
           (loop $search (result i32)
            (drop
             (br_if $__inlined_func$lookup_in_shape$1
              (i32.const -1)
              (ref.is_null
               (local.get $1)
              )
             )
            )
            (if (result i32)
             (struct.get $Shape $key
              (local.get $1)
             )
             (then
              (local.set $1
               (struct.get $Shape $parent
                (local.get $1)
               )
              )
              (br $search)
             )
             (else
              (struct.get $Shape $offset
               (local.get $1)
              )
             )
            )
           )
          )
         )
         (i32.const 0)
        )
        (then
         (struct.set $CallSite $expected_shape
          (local.get $2)
          (ref.as_non_null
           (local.get $5)
          )
         )
         (struct.set $CallSite $offset
          (local.get $2)
          (local.get $4)
         )
         (br $__inlined_func$get_field_slow$8
          (array.get $Storage
           (local.get $3)
           (local.get $4)
          )
         )
        )
       )
       (ref.null none)
      )
     )
    )
   )
   (then
    (call $print_string
     (global.get $"string.const_\"null\"")
    )
   )
   (else
    (if
     (ref.test (ref i31)
      (local.get $0)
     )
     (then
      (call $print_i32
       (i31.get_s
        (ref.cast (ref i31)
         (local.get $0)
        )
       )
      )
     )
     (else
      (if
       (ref.test (ref $BoxedI32)
        (local.get $0)
       )
       (then
        (call $print_i32
         (struct.get $BoxedI32 0
          (ref.cast (ref $BoxedI32)
           (local.get $0)
          )
         )
        )
       )
       (else
        (if
         (ref.test (ref $BoxedF64)
          (local.get $0)
         )
         (then
          (call $print_f64
           (struct.get $BoxedF64 0
            (ref.cast (ref $BoxedF64)
             (local.get $0)
            )
           )
          )
         )
         (else
          (if
           (ref.test (ref $BoxedString)
            (local.get $0)
           )
           (then
            (call $print_string
             (struct.get $BoxedString 0
              (ref.cast (ref $BoxedString)
               (local.get $0)
              )
             )
            )
           )
           (else
            (if
             (ref.test (ref $Object)
              (local.get $0)
             )
             (then
              (call $print_string
               (global.get $"string.const_\"[object Object]\"")
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
)
