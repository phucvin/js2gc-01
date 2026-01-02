(module
 (rec
  (type $Shape (struct (field $parent (ref null $Shape)) (field $key i32) (field $offset i32)))
  (type $Storage (array (mut anyref)))
  (type $Object (struct (field $shape (mut (ref $Shape))) (field $storage (mut (ref $Storage)))))
  (type $CallSite (struct (field $expected_shape (mut (ref null $Shape))) (field $offset (mut i32))))
 )
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedString (struct (field (ref string))))
 (type $6 (func (param (ref string))))
 (type $7 (func (result anyref)))
 (type $8 (func (result (ref (exact $Shape)))))
 (type $9 (func (param (ref (exact $Shape))) (result (ref (exact $Object)))))
 (type $10 (func (param (ref $Object) i32 (ref eq))))
 (type $11 (func (result nullref)))
 (import "env" "print_string" (func $print_string (type $6) (param (ref string))))
 (global $"string.const_\"[object Object]\"" (ref string) (string.const "[object Object]"))
 (global $"string.const_\"hello\"" (ref string) (string.const "hello"))
 (export "test" (func $test))
 (func $new_root_shape (type $8) (result (ref (exact $Shape)))
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
 )
 (func $new_object (type $9) (param $0 (ref (exact $Shape))) (result (ref (exact $Object)))
  (struct.new $Object
   (local.get $0)
   (array.new_default $Storage
    (i32.const 2)
   )
  )
 )
 (func $set_storage (type $10) (param $0 (ref $Object)) (param $1 i32) (param $2 (ref eq))
  (array.set $Storage
   (struct.get $Object $storage
    (local.get $0)
   )
   (local.get $1)
   (local.get $2)
  )
 )
 (func $console_log (type $11) (result nullref)
  (call $print_string
   (global.get $"string.const_\"[object Object]\"")
  )
  (ref.null none)
 )
 (func $test (type $7) (result anyref)
  (local $0 (ref (exact $Object)))
  (call $set_storage
   (local.tee $0
    (call $new_object
     (struct.new $Shape
      (struct.new $Shape
       (call $new_root_shape)
       (i32.const 0)
       (i32.const 0)
      )
      (i32.const 1)
      (i32.const 1)
     )
    )
   )
   (i32.const 0)
   (ref.i31
    (i32.const 10)
   )
  )
  (call $set_storage
   (local.get $0)
   (i32.const 1)
   (ref.i31
    (i32.const 20)
   )
  )
  (drop
   (call $console_log)
  )
  (call $set_storage
   (local.tee $0
    (call $new_object
     (struct.new $Shape
      (struct.new $Shape
       (call $new_root_shape)
       (i32.const 2)
       (i32.const 0)
      )
      (i32.const 3)
      (i32.const 1)
     )
    )
   )
   (i32.const 0)
   (struct.new $BoxedString
    (global.get $"string.const_\"hello\"")
   )
  )
  (call $set_storage
   (local.get $0)
   (i32.const 1)
   (struct.new $BoxedF64
    (f64.const 3.14)
   )
  )
  (call $console_log)
 )
)
