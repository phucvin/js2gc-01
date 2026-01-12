(module
 (rec
  (type $Shape (struct (field $parent (ref null $Shape)) (field $key i32) (field $offset i32) (field $proto (mut anyref))))
  (type $Storage (array (mut anyref)))
  (type $Object (sub (struct (field $shape (mut (ref $Shape))) (field $storage (mut (ref $Storage))))))
  (type $CallSite (struct (field $expected_shape (mut (ref null $Shape))) (field $offset (mut i32))))
  (type $Closure (sub $Object (struct (field $shape (mut (ref $Shape))) (field $storage (mut (ref $Storage))) (field $func (ref func)) (field $env anyref) (field $cached_shape (mut (ref null $Shape))))))
  (type $BinaryOpFunc (func (param anyref anyref) (result anyref)))
  (type $BinaryOpCallSite (struct (field $type_lhs (mut i32)) (field $type_rhs (mut i32)) (field $target (mut (ref null $BinaryOpFunc)))))
 )
 (type $ClosureSig0 (func (param anyref anyref) (result anyref)))
 (type $ClosureSig1 (func (param anyref anyref anyref) (result anyref)))
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedI32 (struct (field i32)))
 (type $String (array (mut i8)))
 (type $12 (func (param i32)))
 (type $13 (func (param f64)))
 (type $14 (func))
 (type $15 (func (param anyref) (result (ref $Shape))))
 (type $16 (func (param (ref $Shape) i32 i32) (result (ref $Shape))))
 (type $17 (func (param (ref $Shape) i32) (result (ref $Object))))
 (type $18 (func (param (ref $Object) i32 anyref)))
 (type $19 (func (param (ref $Shape) i32) (result i32)))
 (type $20 (func (param (ref $Object) (ref $Shape) (ref $CallSite) i32) (result anyref)))
 (type $21 (func (param (ref $Object) (ref $CallSite) i32) (result anyref)))
 (type $22 (func (param (ref $String))))
 (type $23 (func (param anyref)))
 (type $24 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $12) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $13) (param f64)))
 (import "env" "print_char" (func $print_char (type $12) (param i32)))
 (global $site_0 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
 ))
 (global $site_1 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
 ))
 (global $site_2 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
 ))
 (global $site_3 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
 ))
 (global $shape_literal_0 (ref $Shape) (struct.new $Shape
  (ref.null none)
  (i32.const -1)
  (i32.const -1)
  (ref.null none)
 ))
 (global $g_str_null (mut (ref null $String)) (ref.null none))
 (global $g_str_obj (mut (ref null $String)) (ref.null none))
 (data $str_data_0 "null")
 (data $str_data_1 "[object Object]")
 (elem declare func $closure_0 $closure_1)
 (export "main" (func $main))
 (start $runtime_init)
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
 )
 (func $new_root_shape_with_proto (type $15) (param $proto anyref) (result (ref $Shape))
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
   (local.get $proto)
  )
 )
 (func $extend_shape (type $16) (param $parent (ref $Shape)) (param $key i32) (param $offset i32) (result (ref $Shape))
  (struct.new $Shape
   (local.get $parent)
   (local.get $key)
   (local.get $offset)
   (struct.get $Shape $proto
    (local.get $parent)
   )
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
 (func $put_field (type $18) (param $obj (ref $Object)) (param $key i32) (param $val anyref)
  (local $shape (ref $Shape))
  (local $offset i32)
  (local $old_storage (ref $Storage))
  (local $new_storage (ref $Storage))
  (local $old_len i32)
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
   (i32.ne
    (local.get $offset)
    (i32.const -1)
   )
   (then
    (array.set $Storage
     (struct.get $Object $storage
      (local.get $obj)
     )
     (local.get $offset)
     (local.get $val)
    )
   )
   (else
    (local.set $old_storage
     (struct.get $Object $storage
      (local.get $obj)
     )
    )
    (local.set $old_len
     (array.len
      (local.get $old_storage)
     )
    )
    (local.set $offset
     (local.get $old_len)
    )
    (local.set $shape
     (call $extend_shape
      (local.get $shape)
      (local.get $key)
      (local.get $offset)
     )
    )
    (struct.set $Object $shape
     (local.get $obj)
     (local.get $shape)
    )
    (local.set $new_storage
     (array.new_default $Storage
      (i32.add
       (local.get $old_len)
       (i32.const 1)
      )
     )
    )
    (array.copy $Storage $Storage
     (local.get $new_storage)
     (i32.const 0)
     (local.get $old_storage)
     (i32.const 0)
     (local.get $old_len)
    )
    (array.set $Storage
     (local.get $new_storage)
     (local.get $offset)
     (local.get $val)
    )
    (struct.set $Object $storage
     (local.get $obj)
     (local.get $new_storage)
    )
   )
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
 (func $get_field_resolve (type $20) (param $obj (ref $Object)) (param $shape (ref $Shape)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
  (local $offset i32)
  (local $curr (ref null $Object))
  (local $curr_shape (ref $Shape))
  (local.set $curr
   (local.get $obj)
  )
  (local.set $curr_shape
   (local.get $shape)
  )
  (loop $search
   (local.set $offset
    (call $lookup_in_shape
     (local.get $curr_shape)
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
      (ref.eq
       (local.get $curr)
       (local.get $obj)
      )
      (then
       (struct.set $CallSite $expected_shape
        (local.get $cache)
        (local.get $curr_shape)
       )
       (struct.set $CallSite $offset
        (local.get $cache)
        (local.get $offset)
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
   )
   (local.set $curr
    (ref.cast (ref null $Object)
     (struct.get $Shape $proto
      (local.get $curr_shape)
     )
    )
   )
   (if
    (ref.is_null
     (local.get $curr)
    )
    (then
     (return
      (ref.null none)
     )
    )
    (else
     (local.set $curr_shape
      (struct.get $Object $shape
       (local.get $curr)
      )
     )
     (br $search)
    )
   )
  )
  (ref.null none)
 )
 (func $get_field_cached (type $21) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
  (local $shape (ref $Shape))
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
  (call $get_field_resolve
   (local.get $obj)
   (local.get $shape)
   (local.get $cache)
   (local.get $key)
  )
 )
 (func $print_string_helper (type $22) (param $str (ref $String))
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
 (func $console_log (type $23) (param $val anyref)
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
 (func $main (type $24) (result anyref)
  (local $user_Person anyref)
  (local $temp_0 (ref null $Object))
  (local $temp_1 (ref null $Closure))
  (local $temp_2 (ref null $Object))
  (local $temp_3 (ref null $Closure))
  (local $user_p anyref)
  (local $temp_4 (ref null $Closure))
  (local $temp_5 anyref)
  (local $temp_6 (ref null $Object))
  (local $temp_7 (ref null $Shape))
  (local $temp_8 anyref)
  (local $temp_9 (ref null $Closure))
  (local.set $user_Person
   (block (result (ref $Closure))
    (local.set $temp_1
     (struct.new $Closure
      (global.get $shape_literal_0)
      (array.new_default $Storage
       (i32.const 0)
      )
      (ref.func $closure_0)
      (call $new_object
       (global.get $shape_literal_0)
       (i32.const 0)
      )
      (ref.null none)
     )
    )
    (call $put_field
     (ref.cast (ref $Closure)
      (local.get $temp_1)
     )
     (i32.const 1)
     (call $new_object
      (global.get $shape_literal_0)
      (i32.const 0)
     )
    )
    (ref.as_non_null
     (local.get $temp_1)
    )
   )
  )
  (call $put_field
   (ref.cast (ref $Object)
    (call $get_field_cached
     (ref.cast (ref $Object)
      (local.get $user_Person)
     )
     (global.get $site_0)
     (i32.const 1)
    )
   )
   (i32.const 2)
   (block (result (ref $Closure))
    (local.set $temp_3
     (struct.new $Closure
      (global.get $shape_literal_0)
      (array.new_default $Storage
       (i32.const 0)
      )
      (ref.func $closure_1)
      (call $new_object
       (global.get $shape_literal_0)
       (i32.const 0)
      )
      (ref.null none)
     )
    )
    (call $put_field
     (ref.cast (ref $Closure)
      (local.get $temp_3)
     )
     (i32.const 1)
     (call $new_object
      (global.get $shape_literal_0)
      (i32.const 0)
     )
    )
    (ref.as_non_null
     (local.get $temp_3)
    )
   )
  )
  (local.set $user_p
   (block (result anyref)
    (local.set $temp_4
     (ref.cast (ref $Closure)
      (local.get $user_Person)
     )
    )
    (local.set $temp_5
     (call $get_field_cached
      (ref.cast (ref $Closure)
       (local.get $temp_4)
      )
      (global.get $site_2)
      (i32.const 1)
     )
    )
    (local.set $temp_7
     (struct.get $Closure $cached_shape
      (local.get $temp_4)
     )
    )
    (if
     (ref.is_null
      (local.get $temp_7)
     )
     (then
      (local.set $temp_7
       (call $new_root_shape_with_proto
        (local.get $temp_5)
       )
      )
      (struct.set $Closure $cached_shape
       (local.get $temp_4)
       (local.get $temp_7)
      )
     )
     (else
      (if
       (i32.eq
        (ref.eq
         (ref.cast eqref
          (struct.get $Shape $proto
           (ref.as_non_null
            (local.get $temp_7)
           )
          )
         )
         (ref.cast eqref
          (local.get $temp_5)
         )
        )
        (i32.const 0)
       )
       (then
        (local.set $temp_7
         (call $new_root_shape_with_proto
          (local.get $temp_5)
         )
        )
        (struct.set $Closure $cached_shape
         (local.get $temp_4)
         (local.get $temp_7)
        )
       )
      )
     )
    )
    (local.set $temp_6
     (call $new_object
      (ref.as_non_null
       (local.get $temp_7)
      )
      (i32.const 0)
     )
    )
    (drop
     (call_ref $ClosureSig1
      (struct.get $Closure $env
       (local.get $temp_4)
      )
      (local.get $temp_6)
      (ref.i31
       (i32.const 100)
      )
      (ref.cast (ref $ClosureSig1)
       (struct.get $Closure $func
        (local.get $temp_4)
       )
      )
     )
    )
    (local.get $temp_6)
   )
  )
  (block (result anyref)
   (call $console_log
    (block (result anyref)
     (local.set $temp_8
      (local.get $user_p)
     )
     (call_ref $ClosureSig0
      (struct.get $Closure $env
       (local.tee $temp_9
        (ref.cast (ref $Closure)
         (call $get_field_cached
          (ref.cast (ref $Object)
           (local.get $temp_8)
          )
          (global.get $site_3)
          (i32.const 2)
         )
        )
       )
      )
      (local.get $temp_8)
      (ref.cast (ref $ClosureSig0)
       (struct.get $Closure $func
        (local.get $temp_9)
       )
      )
     )
    )
   )
   (ref.null none)
  )
 )
 (func $closure_0 (type $ClosureSig1) (param $env anyref) (param $this anyref) (param $user_val anyref) (result anyref)
  (local $temp_0 anyref)
  (call $put_field
   (ref.cast (ref $Object)
    (local.get $this)
   )
   (i32.const 0)
   (local.tee $temp_0
    (local.get $user_val)
   )
  )
  (local.get $temp_0)
 )
 (func $closure_1 (type $ClosureSig0) (param $env anyref) (param $this anyref) (result anyref)
  (call $get_field_cached
   (ref.cast (ref $Object)
    (local.get $this)
   )
   (global.get $site_1)
   (i32.const 0)
  )
 )
)
