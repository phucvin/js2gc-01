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
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedI32 (struct (field i32)))
 (type $String (array (mut i8)))
 (type $10 (func (param i32)))
 (type $11 (func (param f64)))
 (type $12 (func (result (ref $Shape))))
 (type $13 (func (param (ref $Shape) i32 i32) (result (ref $Shape))))
 (type $14 (func (param (ref $Shape) i32) (result (ref $Object))))
 (type $15 (func (param (ref $Object) i32 anyref)))
 (type $16 (func (param (ref $Shape) i32) (result i32)))
 (type $17 (func (param (ref $Object) (ref $CallSite) i32) (result anyref)))
 (type $18 (func (param (ref $String))))
 (type $19 (func (param anyref)))
 (type $20 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $10) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $11) (param f64)))
 (import "env" "print_char" (func $print_char (type $10) (param i32)))
 (global $site_0 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
 ))
 (export "main" (func $main))
 (func $new_root_shape (type $12) (result (ref $Shape))
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
 )
 (func $extend_shape (type $13) (param $parent (ref $Shape)) (param $key i32) (param $offset i32) (result (ref $Shape))
  (struct.new $Shape
   (local.get $parent)
   (local.get $key)
   (local.get $offset)
  )
 )
 (func $new_object (type $14) (param $shape (ref $Shape)) (param $size i32) (result (ref $Object))
  (struct.new $Object
   (local.get $shape)
   (array.new_default $Storage
    (local.get $size)
   )
  )
 )
 (func $set_storage (type $15) (param $obj (ref $Object)) (param $idx i32) (param $val anyref)
  (array.set $Storage
   (struct.get $Object $storage
    (local.get $obj)
   )
   (local.get $idx)
   (local.get $val)
  )
 )
 (func $lookup_in_shape (type $16) (param $shape (ref $Shape)) (param $key i32) (result i32)
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
 (func $get_field_slow (type $17) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
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
 (func $get_field_cached (type $17) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
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
 (func $print_string_helper (type $18) (param $str (ref $String))
  (local $len i32)
  (local $i i32)
  (local.set $len
   (array.len
    (local.get $str)
   )
  )
  (local.set $i
   (i32.const 0)
  )
  (loop $l
   (if
    (i32.lt_u
     (local.get $i)
     (local.get $len)
    )
    (then
     (call $print_char
      (array.get_u $String
       (local.get $str)
       (local.get $i)
      )
     )
     (local.set $i
      (i32.add
       (local.get $i)
       (i32.const 1)
      )
     )
     (br $l)
    )
   )
  )
 )
 (func $console_log (type $19) (param $val anyref)
  (if
   (ref.is_null
    (local.get $val)
   )
   (then
    (call $print_string_helper
     (array.new_fixed $String 4
      (i32.const 110)
      (i32.const 117)
      (i32.const 108)
      (i32.const 108)
     )
    )
    (call $print_char
     (i32.const 10)
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
           (ref.test (ref $String)
            (local.get $val)
           )
           (then
            (call $print_string_helper
             (ref.cast (ref $String)
              (local.get $val)
             )
            )
            (call $print_char
             (i32.const 10)
            )
           )
           (else
            (if
             (ref.test (ref $Object)
              (local.get $val)
             )
             (then
              (call $print_string_helper
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
              (call $print_char
               (i32.const 10)
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
 (func $main (type $20) (result anyref)
  (local $user_obj anyref)
  (local $temp_0 (ref null $Object))
  (local.set $user_obj
   (block (result (ref $Object))
    (call $set_storage
     (ref.as_non_null
      (local.tee $temp_0
       (call $new_object
        (call $extend_shape
         (call $new_root_shape)
         (i32.const 0)
         (i32.const 0)
        )
        (i32.const 1)
       )
      )
     )
     (i32.const 0)
     (ref.i31
      (i32.const 100)
     )
    )
    (ref.as_non_null
     (local.get $temp_0)
    )
   )
  )
  (block (result anyref)
   (call $console_log
    (call $get_field_cached
     (ref.cast (ref $Object)
      (local.get $user_obj)
     )
     (global.get $site_0)
     (i32.const 0)
    )
   )
   (ref.null none)
  )
 )
)
