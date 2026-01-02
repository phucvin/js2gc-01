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
 (type $11 (func (param (ref $Object) (ref $CallSite) i32) (result anyref)))
 (type $12 (func (result anyref)))
 (type $13 (func (param (ref $Object) i32 (ref i31))))
 (type $14 (func (result (ref (exact $CallSite)))))
 (type $15 (func (param anyref) (result nullref)))
 (import "env" "print_i32" (func $print_i32 (type $7) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $8) (param f64)))
 (import "env" "print_string" (func $print_string (type $9) (param (ref string))))
 (global $"string.const_\"[object Object]\"" (ref string) (string.const "[object Object]"))
 (global $"string.const_\"null\"" (ref string) (string.const "null"))
 (global $init_done (mut i32) (i32.const 0))
 (global $site_0 (mut (ref null $CallSite)) (ref.null none))
 (global $site_1 (mut (ref null $CallSite)) (ref.null none))
 (export "main" (func $main))
 (start $init_globals)
 (func $set_storage (type $13) (param $0 (ref $Object)) (param $1 i32) (param $2 (ref i31))
  (array.set $Storage
   (struct.get $Object $storage
    (local.get $0)
   )
   (local.get $1)
   (local.get $2)
  )
 )
 (func $new_callsite (type $14) (result (ref (exact $CallSite)))
  (struct.new $CallSite
   (ref.null none)
   (i32.const -1)
  )
 )
 (func $init_globals (type $10)
  (if
   (i32.eqz
    (global.get $init_done)
   )
   (then
    (global.set $site_0
     (call $new_callsite)
    )
    (global.set $site_1
     (call $new_callsite)
    )
    (global.set $init_done
     (i32.const 1)
    )
   )
  )
 )
 (func $get_field_cached (type $11) (param $0 (ref $Object)) (param $1 (ref $CallSite)) (param $2 i32) (result anyref)
  (local $3 (ref null $Shape))
  (local $4 (ref null $Object))
  (local $5 (ref null $Shape))
  (if
   (ref.eq
    (struct.get $Object $shape
     (local.get $0)
    )
    (struct.get $CallSite $expected_shape
     (local.get $1)
    )
   )
   (then
    (return
     (array.get $Storage
      (struct.get $Object $storage
       (local.get $0)
      )
      (struct.get $CallSite $offset
       (local.get $1)
      )
     )
    )
   )
  )
  (block $__inlined_func$get_field_slow$5 (result anyref)
   (if
    (i32.ge_s
     (local.tee $2
      (block $__inlined_func$lookup_in_shape (result i32)
       (local.set $3
        (ref.as_non_null
         (local.tee $5
          (struct.get $Object $shape
           (local.tee $4
            (local.get $0)
           )
          )
         )
        )
       )
       (loop $search (result i32)
        (drop
         (br_if $__inlined_func$lookup_in_shape
          (i32.const -1)
          (ref.is_null
           (local.get $3)
          )
         )
        )
        (if (result i32)
         (i32.eq
          (struct.get $Shape $key
           (local.get $3)
          )
          (local.get $2)
         )
         (then
          (struct.get $Shape $offset
           (local.get $3)
          )
         )
         (else
          (local.set $3
           (struct.get $Shape $parent
            (local.get $3)
           )
          )
          (br $search)
         )
        )
       )
      )
     )
     (i32.const 0)
    )
    (then
     (struct.set $CallSite $expected_shape
      (local.get $1)
      (ref.as_non_null
       (local.get $5)
      )
     )
     (struct.set $CallSite $offset
      (local.get $1)
      (local.get $2)
     )
     (br $__inlined_func$get_field_slow$5
      (array.get $Storage
       (struct.get $Object $storage
        (local.get $0)
       )
       (local.get $2)
      )
     )
    )
   )
   (ref.null none)
  )
 )
 (func $console_log (type $15) (param $0 anyref) (result nullref)
  (if
   (ref.is_null
    (local.get $0)
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
 (func $main (type $12) (result anyref)
  (local $0 (ref (exact $Object)))
  (call $set_storage
   (local.tee $0
    (struct.new $Object
     (struct.new $Shape
      (struct.new $Shape
       (struct.new $Shape
        (ref.null none)
        (i32.const -1)
        (i32.const -1)
       )
       (i32.const 0)
       (i32.const 0)
      )
      (i32.const 1)
      (i32.const 1)
     )
     (array.new_default $Storage
      (i32.const 2)
     )
    )
   )
   (i32.const 0)
   (ref.i31
    (i32.const 1)
   )
  )
  (call $set_storage
   (local.get $0)
   (i32.const 1)
   (ref.i31
    (i32.const 2)
   )
  )
  (drop
   (call $console_log
    (call $get_field_cached
     (local.get $0)
     (ref.as_non_null
      (global.get $site_0)
     )
     (i32.const 0)
    )
   )
  )
  (call $console_log
   (call $get_field_cached
    (local.get $0)
    (ref.as_non_null
     (global.get $site_1)
    )
    (i32.const 1)
   )
  )
 )
)
