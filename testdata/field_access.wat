(module
 (rec
  (type $Shape (struct (field $parent (ref null $Shape)) (field $key i32) (field $offset i32)))
  (type $Storage (array (mut anyref)))
  (type $Object (struct (field $shape (mut (ref $Shape))) (field $storage (mut (ref $Storage))) (field $proto (mut (ref null $Object)))))
  (type $CallSite (struct (field $expected_shape (mut (ref null $Shape))) (field $target_offset (mut i32)) (field $cached_proto (mut (ref null $Object))) (field $proto_shape (mut (ref null $Shape))) (field $target_storage (mut (ref null $Storage)))))
  (type $Closure (struct (field $func (ref func)) (field $env anyref)))
  (type $BinaryOpFunc (func (param anyref anyref) (result anyref)))
  (type $BinaryOpCallSite (struct (field $type_lhs (mut i32)) (field $type_rhs (mut i32)) (field $target (mut (ref null $BinaryOpFunc)))))
 )
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedI32 (struct (field i32)))
 (type $String (array (mut i8)))
 (type $10 (func (param i32)))
 (type $11 (func (param f64)))
 (type $12 (func (result (ref $Shape))))
 (type $13 (func (param (ref $Shape) i32 (ref null $Object)) (result (ref $Object))))
 (type $14 (func))
 (type $15 (func (param (ref $Object) i32 anyref)))
 (type $16 (func (param (ref $Shape) i32) (result i32)))
 (type $17 (func (param (ref $Object) (ref $Shape) (ref null $CallSite) i32) (result anyref)))
 (type $18 (func (param (ref $Object) (ref $CallSite) i32) (result anyref)))
 (type $19 (func (param (ref $String))))
 (type $20 (func (param anyref)))
 (type $21 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $10) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $11) (param f64)))
 (import "env" "print_char" (func $print_char (type $10) (param i32)))
 (global $site_0 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
  (ref.null none)
  (ref.null none)
  (ref.null none)
 ))
 (global $site_1 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
  (ref.null none)
  (ref.null none)
  (ref.null none)
 ))
 (global $shape_literal_0 (ref $Shape) (struct.new $Shape
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
  (i32.const 0)
  (i32.const 0)
 ))
 (global $shape_literal_1 (ref $Shape) (struct.new $Shape
  (struct.new $Shape
   (struct.new $Shape
    (ref.null none)
    (i32.const -1)
    (i32.const -1)
   )
   (i32.const 2)
   (i32.const 0)
  )
  (i32.const 1)
  (i32.const 1)
 ))
 (global $g_str_null (mut (ref null $String)) (ref.null none))
 (global $g_str_obj (mut (ref null $String)) (ref.null none))
 (global $g_obj_proto (mut (ref null $Object)) (ref.null none))
 (data $str_data_0 "null")
 (data $str_data_1 "[object Object]")
 (export "main" (func $main))
 (start $runtime_init)
 (func $new_root_shape (type $12) (result (ref $Shape))
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
 )
 (func $new_object (type $13) (param $shape (ref $Shape)) (param $size i32) (param $proto (ref null $Object)) (result (ref $Object))
  (struct.new $Object
   (local.get $shape)
   (array.new_default $Storage
    (local.get $size)
   )
   (local.get $proto)
  )
 )
 (func $runtime_init (type $14)
  (global.set $g_str_null
   (array.new_data $String $str_data_0
    (i32.const 0)
    (i32.const 4)
   )
  )
  (global.set $g_str_obj
   (array.new_data $String $str_data_1
    (i32.const 0)
    (i32.const 15)
   )
  )
  (global.set $g_obj_proto
   (call $new_object
    (call $new_root_shape)
    (i32.const 0)
    (ref.null none)
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
      (local.get $curr)
     )
     (local.get $key)
    )
    (then
     (return
      (struct.get $Shape $offset
       (local.get $curr)
      )
     )
    )
    (else
     (local.set $curr
      (struct.get $Shape $parent
       (local.get $curr)
      )
     )
     (br $search)
    )
   )
  )
  (i32.const -1)
 )
 (func $get_field_resolve (type $17) (param $obj (ref $Object)) (param $shape (ref $Shape)) (param $cache (ref null $CallSite)) (param $key i32) (result anyref)
  (local $curr (ref null $Object))
  (local $offset i32)
  (local.set $curr
   (local.get $obj)
  )
  (loop $l
   (if
    (ref.is_null
     (local.get $curr)
    )
    (then
     (return
      (ref.null none)
     )
    )
   )
   (local.set $offset
    (call $lookup_in_shape
     (struct.get $Object $shape
      (local.get $curr)
     )
     (local.get $key)
    )
   )
   (if
    (i32.ge_s
     (local.get $offset)
     (i32.const 0)
    )
    (then
     (if
      (ref.is_null
       (local.get $cache)
      )
      (then
      )
      (else
       (struct.set $CallSite $expected_shape
        (local.get $cache)
        (local.get $shape)
       )
       (struct.set $CallSite $target_offset
        (local.get $cache)
        (local.get $offset)
       )
       (if
        (ref.eq
         (local.get $curr)
         (local.get $obj)
        )
        (then
         (struct.set $CallSite $cached_proto
          (local.get $cache)
          (ref.null none)
         )
         (struct.set $CallSite $proto_shape
          (local.get $cache)
          (ref.null none)
         )
         (struct.set $CallSite $target_storage
          (local.get $cache)
          (ref.null none)
         )
        )
        (else
         (if
          (ref.eq
           (local.get $curr)
           (struct.get $Object $proto
            (local.get $obj)
           )
          )
          (then
           (struct.set $CallSite $cached_proto
            (local.get $cache)
            (local.get $curr)
           )
           (struct.set $CallSite $proto_shape
            (local.get $cache)
            (struct.get $Object $shape
             (local.get $curr)
            )
           )
           (struct.set $CallSite $target_storage
            (local.get $cache)
            (struct.get $Object $storage
             (local.get $curr)
            )
           )
          )
          (else
           (struct.set $CallSite $cached_proto
            (local.get $cache)
            (ref.null none)
           )
           (struct.set $CallSite $proto_shape
            (local.get $cache)
            (ref.null none)
           )
           (struct.set $CallSite $target_storage
            (local.get $cache)
            (ref.null none)
           )
           (struct.set $CallSite $expected_shape
            (local.get $cache)
            (ref.null none)
           )
          )
         )
        )
       )
      )
     )
     (return
      (array.get $Storage
       (struct.get $Object $storage
        (local.get $curr)
       )
       (local.get $offset)
      )
     )
    )
    (else
     (local.set $curr
      (struct.get $Object $proto
       (local.get $curr)
      )
     )
     (br $l)
    )
   )
  )
  (ref.null none)
 )
 (func $get_field_cached (type $18) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
  (local $shape (ref $Shape))
  (local $proto (ref null $Object))
  (local.set $shape
   (struct.get $Object $shape
    (local.get $obj)
   )
  )
  (if
   (ref.eq
    (local.get $shape)
    (struct.get $CallSite $expected_shape
     (local.get $cache)
    )
   )
   (then
    (if
     (ref.is_null
      (struct.get $CallSite $cached_proto
       (local.get $cache)
      )
     )
     (then
      (return
       (array.get $Storage
        (struct.get $Object $storage
         (local.get $obj)
        )
        (struct.get $CallSite $target_offset
         (local.get $cache)
        )
       )
      )
     )
     (else
      (local.set $proto
       (struct.get $Object $proto
        (local.get $obj)
       )
      )
      (if
       (ref.eq
        (local.get $proto)
        (struct.get $CallSite $cached_proto
         (local.get $cache)
        )
       )
       (then
        (if
         (ref.eq
          (struct.get $Object $shape
           (local.get $proto)
          )
          (struct.get $CallSite $proto_shape
           (local.get $cache)
          )
         )
         (then
          (return
           (array.get $Storage
            (struct.get $CallSite $target_storage
             (local.get $cache)
            )
            (struct.get $CallSite $target_offset
             (local.get $cache)
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
  (call $get_field_resolve
   (local.get $obj)
   (local.get $shape)
   (local.get $cache)
   (local.get $key)
  )
 )
 (func $print_string_helper (type $19) (param $str (ref $String))
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
 (func $console_log (type $20) (param $val anyref)
  (block $null
   (drop
    (br_on_null $null
     (local.get $val)
    )
   )
   (call $print_i32
    (i31.get_s
     (block $i31 (result (ref i31))
      (call $print_i32
       (struct.get $BoxedI32 0
        (block $boxed_i32 (result (ref $BoxedI32))
         (call $print_f64
          (struct.get $BoxedF64 0
           (block $boxed_f64 (result (ref $BoxedF64))
            (call $print_string_helper
             (block $string (result (ref $String))
              (drop
               (block $object (result (ref $Object))
                (drop
                 (br_on_cast $object anyref (ref $Object)
                  (br_on_cast $string anyref (ref $String)
                   (br_on_cast $boxed_f64 anyref (ref $BoxedF64)
                    (br_on_cast $boxed_i32 anyref (ref $BoxedI32)
                     (br_on_cast $i31 anyref (ref i31)
                      (local.get $val)
                     )
                    )
                   )
                  )
                 )
                )
                (return)
               )
              )
              (call $print_string_helper
               (ref.as_non_null
                (global.get $g_str_obj)
               )
              )
              (call $print_char
               (i32.const 10)
              )
              (return)
             )
            )
            (call $print_char
             (i32.const 10)
            )
            (return)
           )
          )
         )
         (return)
        )
       )
      )
      (return)
     )
    )
   )
   (return)
  )
  (call $print_string_helper
   (ref.as_non_null
    (global.get $g_str_null)
   )
  )
  (call $print_char
   (i32.const 10)
  )
 )
 (func $main (type $21) (result anyref)
  (local $temp_0 (ref null $Object))
  (local $temp_1 (ref null $Object))
  (call $console_log
   (call $get_field_cached
    (ref.cast (ref $Object)
     (block (result (ref $Object))
      (local.set $temp_0
       (call $new_object
        (global.get $shape_literal_0)
        (i32.const 1)
        (global.get $g_obj_proto)
       )
      )
      (call $set_storage
       (ref.as_non_null
        (local.get $temp_0)
       )
       (i32.const 0)
       (ref.i31
        (i32.const 123)
       )
      )
      (ref.as_non_null
       (local.get $temp_0)
      )
     )
    )
    (global.get $site_0)
    (i32.const 0)
   )
  )
  (block (result anyref)
   (call $console_log
    (call $get_field_cached
     (ref.cast (ref $Object)
      (block (result (ref $Object))
       (local.set $temp_1
        (call $new_object
         (global.get $shape_literal_1)
         (i32.const 2)
         (global.get $g_obj_proto)
        )
       )
       (call $set_storage
        (ref.as_non_null
         (local.get $temp_1)
        )
        (i32.const 0)
        (ref.i31
         (i32.const 10)
        )
       )
       (call $set_storage
        (ref.as_non_null
         (local.get $temp_1)
        )
        (i32.const 1)
        (ref.i31
         (i32.const 20)
        )
       )
       (ref.as_non_null
        (local.get $temp_1)
       )
      )
     )
     (global.get $site_1)
     (i32.const 1)
    )
   )
   (ref.null none)
  )
 )
)
