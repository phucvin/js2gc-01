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
 (type $12 (func))
 (type $13 (func (result (ref $Shape))))
 (type $14 (func (param (ref $Shape) i32 i32) (result (ref $Shape))))
 (type $15 (func (param (ref $Shape) i32) (result (ref $Object))))
 (type $16 (func (param (ref $Object) i32 anyref)))
 (type $17 (func (param (ref $String))))
 (type $18 (func (param anyref)))
 (type $19 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $10) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $11) (param f64)))
 (import "env" "print_char" (func $print_char (type $10) (param i32)))
 (global $g_str_null (mut (ref null $String)) (ref.null none))
 (global $g_str_obj (mut (ref null $String)) (ref.null none))
 (data $str_data_0 "hello")
 (export "main" (func $main))
 (start $runtime_init)
 (func $runtime_init (type $12)
  (global.set $g_str_null
   (array.new_fixed $String 4
    (i32.const 110)
    (i32.const 117)
    (i32.const 108)
    (i32.const 108)
   )
  )
  (global.set $g_str_obj
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
 (func $new_root_shape (type $13) (result (ref $Shape))
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
 )
 (func $extend_shape (type $14) (param $parent (ref $Shape)) (param $key i32) (param $offset i32) (result (ref $Shape))
  (struct.new $Shape
   (local.get $parent)
   (local.get $key)
   (local.get $offset)
  )
 )
 (func $new_object (type $15) (param $shape (ref $Shape)) (param $size i32) (result (ref $Object))
  (struct.new $Object
   (local.get $shape)
   (array.new_default $Storage
    (local.get $size)
   )
  )
 )
 (func $set_storage (type $16) (param $obj (ref $Object)) (param $idx i32) (param $val anyref)
  (array.set $Storage
   (struct.get $Object $storage
    (local.get $obj)
   )
   (local.get $idx)
   (local.get $val)
  )
 )
 (func $print_string_helper (type $17) (param $str (ref $String))
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
 (func $console_log (type $18) (param $val anyref)
  (if
   (ref.is_null
    (local.get $val)
   )
   (then
    (call $print_string_helper
     (ref.as_non_null
      (global.get $g_str_null)
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
               (ref.as_non_null
                (global.get $g_str_obj)
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
 (func $main (type $19) (result anyref)
  (local $temp_0 (ref null $Object))
  (local $temp_1 (ref null $Object))
  (call $console_log
   (block (result (ref $Object))
    (call $set_storage
     (ref.as_non_null
      (local.tee $temp_0
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
     )
     (i32.const 0)
     (ref.i31
      (i32.const 10)
     )
    )
    (call $set_storage
     (ref.as_non_null
      (local.get $temp_0)
     )
     (i32.const 1)
     (ref.i31
      (i32.const 20)
     )
    )
    (ref.as_non_null
     (local.get $temp_0)
    )
   )
  )
  (block (result anyref)
   (call $console_log
    (block (result (ref $Object))
     (call $set_storage
      (ref.as_non_null
       (local.tee $temp_1
        (call $new_object
         (call $extend_shape
          (call $extend_shape
           (call $new_root_shape)
           (i32.const 2)
           (i32.const 0)
          )
          (i32.const 3)
          (i32.const 1)
         )
         (i32.const 2)
        )
       )
      )
      (i32.const 0)
      (array.new_data $String $str_data_0
       (i32.const 0)
       (i32.const 5)
      )
     )
     (call $set_storage
      (ref.as_non_null
       (local.get $temp_1)
      )
      (i32.const 1)
      (struct.new $BoxedF64
       (f64.const 3.14)
      )
     )
     (ref.as_non_null
      (local.get $temp_1)
     )
    )
   )
   (ref.null none)
  )
 )
)
