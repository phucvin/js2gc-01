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
 (type $15 (func (result (ref $Shape))))
 (type $16 (func (param (ref $Shape) i32 i32) (result (ref $Shape))))
 (type $17 (func (param (ref $Shape) i32) (result (ref $Object))))
 (type $18 (func (param (ref $Object) i32 anyref)))
 (type $19 (func (param (ref $Shape) i32) (result i32)))
 (type $20 (func (param (ref $Object) (ref $CallSite) i32) (result anyref)))
 (type $21 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $12) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $13) (param f64)))
 (import "env" "print_string" (func $print_string (type $14) (param (ref $String))))
 (global $site_0 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
 ))
 (global $site_1 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
 ))
 (export "main" (func $main))
 (func $new_root_shape (type $15) (result (ref $Shape))
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
 )
 (func $extend_shape (type $16) (param $parent (ref $Shape)) (param $key i32) (param $offset i32) (result (ref $Shape))
  (struct.new $Shape
   (local.get $parent)
   (local.get $key)
   (local.get $offset)
  )
 )
 (func $new_object (type $17) (param $shape (ref $Shape)) (param $size i32) (result (ref $Object))
  (struct.new $Object
   (local.get $shape)
   (array.new_default $Storage
    (local.get $size)
   )
  )
 )
 (func $set_storage (type $18) (param $obj (ref $Object)) (param $idx i32) (param $val anyref)
  (array.set $Storage
   (struct.get $Object $storage
    (local.get $obj)
   )
   (local.get $idx)
   (local.get $val)
  )
 )
 (func $lookup_in_shape (type $19) (param $shape (ref $Shape)) (param $key i32) (result i32)
  (local $curr (ref null $Shape))
  (local.set $curr
   (local.get $shape)
  )
  (loop $search
   (if
    (ref.is_null
     (local.get $curr)
    )
    (then
     (return
      (i32.const -1)
     )
    )
   )
   (if
    (i32.eq
     (struct.get $Shape $key
      (ref.as_non_null
       (local.get $curr)
      )
     )
     (local.get $key)
    )
    (then
     (return
      (struct.get $Shape $offset
       (ref.as_non_null
        (local.get $curr)
       )
      )
     )
    )
    (else
     (local.set $curr
      (struct.get $Shape $parent
       (ref.as_non_null
        (local.get $curr)
       )
      )
     )
     (br $search)
    )
   )
  )
  (i32.const -1)
 )
 (func $get_field_slow (type $20) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
  (local $offset i32)
  (local $shape (ref $Shape))
  (local.set $shape
   (struct.get $Object $shape
    (local.get $obj)
   )
  )
  (local.set $offset
   (call $lookup_in_shape
    (local.get $shape)
    (local.get $key)
   )
  )
  (if
   (i32.ge_s
    (local.get $offset)
    (i32.const 0)
   )
   (then
    (struct.set $CallSite $expected_shape
     (local.get $cache)
     (local.get $shape)
    )
    (struct.set $CallSite $offset
     (local.get $cache)
     (local.get $offset)
    )
    (return
     (array.get $Storage
      (struct.get $Object $storage
       (local.get $obj)
      )
      (local.get $offset)
     )
    )
   )
  )
  (ref.null none)
 )
 (func $get_field_cached (type $20) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
  (if
   (ref.eq
    (struct.get $Object $shape
     (local.get $obj)
    )
    (struct.get $CallSite $expected_shape
     (local.get $cache)
    )
   )
   (then
    (return
     (array.get $Storage
      (struct.get $Object $storage
       (local.get $obj)
      )
      (struct.get $CallSite $offset
       (local.get $cache)
      )
     )
    )
   )
  )
  (call $get_field_slow
   (local.get $obj)
   (local.get $cache)
   (local.get $key)
  )
 )
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
 (func $main (type $21) (result anyref)
  (local $user_o anyref)
  (local $temp_0 (ref null $Object))
  (local.set $user_o
   (block (result (ref $Object))
    (local.set $temp_0
     (call $new_object
      (call $extend_shape
       (call $extend_shape
        (call $new_root_shape)
        (i32.const 0)
        (i32.const 0)
       )
       (i32.const 1)
       (i32.const 1)
      )
      (i32.const 2)
     )
    )
    (call $set_storage
     (ref.as_non_null
      (local.get $temp_0)
     )
     (i32.const 0)
     (ref.i31
      (i32.const 1)
     )
    )
    (call $set_storage
     (ref.as_non_null
      (local.get $temp_0)
     )
     (i32.const 1)
     (ref.i31
      (i32.const 2)
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
  (drop
   (call $console_log
    (call $get_field_cached
     (ref.cast (ref $Object)
      (local.get $user_o)
     )
     (global.get $site_0)
     (i32.const 0)
    )
   )
  )
  (call $console_log
   (call $get_field_cached
    (ref.cast (ref $Object)
     (local.get $user_o)
    )
    (global.get $site_1)
    (i32.const 1)
   )
  )
 )
)
