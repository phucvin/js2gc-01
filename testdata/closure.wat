(module
 (rec
  (type $Shape (struct (field $parent (ref null $Shape)) (field $key i32) (field $offset i32)))
  (type $Storage (array (mut anyref)))
  (type $Object (struct (field $shape (mut (ref $Shape))) (field $storage (mut (ref $Storage)))))
  (type $CallSite (struct (field $expected_shape (mut (ref null $Shape))) (field $offset (mut i32))))
  (type $Closure (struct (field $func (ref func)) (field $env anyref)))
  (type $BinaryOpFunc (func (param anyref anyref) (result anyref)))
  (type $BinaryOpCallSite (struct (field $type_lhs (mut i32)) (field $type_rhs (mut i32)) (field $target (mut (ref null $BinaryOpFunc)))))
 )
 (type $ClosureSig1 (func (param anyref anyref anyref) (result anyref)))
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedI32 (struct (field i32)))
 (type $String (array (mut i8)))
 (type $11 (func (param i32)))
 (type $12 (func (param f64)))
 (type $13 (func))
 (type $14 (func (param (ref $Shape) i32) (result (ref $Object))))
 (type $15 (func (param (ref $Object) i32 anyref)))
 (type $16 (func (param (ref $Shape) i32) (result i32)))
 (type $17 (func (param (ref $Object) (ref $Shape) (ref $CallSite) i32) (result anyref)))
 (type $18 (func (param (ref $Object) (ref $CallSite) i32) (result anyref)))
 (type $19 (func (param (ref $String))))
 (type $20 (func (param anyref)))
 (type $21 (func (param anyref) (result i32)))
 (type $22 (func (param anyref anyref (ref $BinaryOpCallSite)) (result anyref)))
 (type $23 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $11) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $12) (param f64)))
 (import "env" "print_char" (func $print_char (type $11) (param i32)))
 (global $site_0 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
 ))
 (global $site_bin_0 (mut (ref $BinaryOpCallSite)) (struct.new $BinaryOpCallSite
  (i32.const 0)
  (i32.const 0)
  (ref.null nofunc)
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
 (global $g_str_null (mut (ref null $String)) (ref.null none))
 (global $g_str_obj (mut (ref null $String)) (ref.null none))
 (data $str_data_0 "null")
 (data $str_data_1 "[object Object]")
 (elem declare func $add_f64_f64 $add_f64_i32 $add_i32_f64 $add_i32_i32 $add_unsupported $closure_0)
 (export "main" (func $main))
 (start $runtime_init)
 (func $runtime_init (type $13)
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
 (func $get_field_resolve (type $17) (param $obj (ref $Object)) (param $shape (ref $Shape)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
  (local $offset i32)
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
 (func $get_field_cached (type $18) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
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
 (func $get_type_id (type $21) (param $val anyref) (result i32)
  (if
   (ref.is_null
    (local.get $val)
   )
   (then
    (return
     (i32.const 0)
    )
   )
  )
  (if
   (ref.test (ref i31)
    (local.get $val)
   )
   (then
    (return
     (i32.const 1)
    )
   )
  )
  (if
   (ref.test (ref $BoxedF64)
    (local.get $val)
   )
   (then
    (return
     (i32.const 2)
    )
   )
  )
  (i32.const 0)
 )
 (func $add_i32_i32 (type $BinaryOpFunc) (param $0 anyref) (param $1 anyref) (result anyref)
  (ref.i31
   (i32.add
    (i31.get_s
     (ref.cast (ref i31)
      (local.get $0)
     )
    )
    (i31.get_s
     (ref.cast (ref i31)
      (local.get $1)
     )
    )
   )
  )
 )
 (func $add_f64_f64 (type $BinaryOpFunc) (param $0 anyref) (param $1 anyref) (result anyref)
  (struct.new $BoxedF64
   (f64.add
    (struct.get $BoxedF64 0
     (ref.cast (ref $BoxedF64)
      (local.get $0)
     )
    )
    (struct.get $BoxedF64 0
     (ref.cast (ref $BoxedF64)
      (local.get $1)
     )
    )
   )
  )
 )
 (func $add_i32_f64 (type $BinaryOpFunc) (param $0 anyref) (param $1 anyref) (result anyref)
  (struct.new $BoxedF64
   (f64.add
    (f64.convert_i32_s
     (i31.get_s
      (ref.cast (ref i31)
       (local.get $0)
      )
     )
    )
    (struct.get $BoxedF64 0
     (ref.cast (ref $BoxedF64)
      (local.get $1)
     )
    )
   )
  )
 )
 (func $add_f64_i32 (type $BinaryOpFunc) (param $0 anyref) (param $1 anyref) (result anyref)
  (struct.new $BoxedF64
   (f64.add
    (struct.get $BoxedF64 0
     (ref.cast (ref $BoxedF64)
      (local.get $0)
     )
    )
    (f64.convert_i32_s
     (i31.get_s
      (ref.cast (ref i31)
       (local.get $1)
      )
     )
    )
   )
  )
 )
 (func $add_unsupported (type $BinaryOpFunc) (param $0 anyref) (param $1 anyref) (result anyref)
  (ref.null none)
 )
 (func $add_slow (type $22) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
  (local $t_lhs i32)
  (local $t_rhs i32)
  (local $target (ref null $BinaryOpFunc))
  (local.set $t_lhs
   (call $get_type_id
    (local.get $lhs)
   )
  )
  (local.set $t_rhs
   (call $get_type_id
    (local.get $rhs)
   )
  )
  (local.set $target
   (ref.func $add_unsupported)
  )
  (if
   (i32.eq
    (local.get $t_lhs)
    (i32.const 1)
   )
   (then
    (if
     (i32.eq
      (local.get $t_rhs)
      (i32.const 1)
     )
     (then
      (local.set $target
       (ref.func $add_i32_i32)
      )
     )
     (else
      (if
       (i32.eq
        (local.get $t_rhs)
        (i32.const 2)
       )
       (then
        (local.set $target
         (ref.func $add_i32_f64)
        )
       )
      )
     )
    )
   )
   (else
    (if
     (i32.eq
      (local.get $t_lhs)
      (i32.const 2)
     )
     (then
      (if
       (i32.eq
        (local.get $t_rhs)
        (i32.const 1)
       )
       (then
        (local.set $target
         (ref.func $add_f64_i32)
        )
       )
       (else
        (if
         (i32.eq
          (local.get $t_rhs)
          (i32.const 2)
         )
         (then
          (local.set $target
           (ref.func $add_f64_f64)
          )
         )
        )
       )
      )
     )
    )
   )
  )
  (struct.set $BinaryOpCallSite $type_lhs
   (local.get $cache)
   (local.get $t_lhs)
  )
  (struct.set $BinaryOpCallSite $type_rhs
   (local.get $cache)
   (local.get $t_rhs)
  )
  (struct.set $BinaryOpCallSite $target
   (local.get $cache)
   (local.get $target)
  )
  (call_ref $BinaryOpFunc
   (local.get $lhs)
   (local.get $rhs)
   (local.get $target)
  )
 )
 (func $add_cached (type $22) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
  (block $slow
   (br_if $slow
    (i32.ne
     (call $get_type_id
      (local.get $lhs)
     )
     (struct.get $BinaryOpCallSite $type_lhs
      (local.get $cache)
     )
    )
   )
   (br_if $slow
    (i32.ne
     (call $get_type_id
      (local.get $rhs)
     )
     (struct.get $BinaryOpCallSite $type_rhs
      (local.get $cache)
     )
    )
   )
   (return
    (call_ref $BinaryOpFunc
     (local.get $lhs)
     (local.get $rhs)
     (struct.get $BinaryOpCallSite $target
      (local.get $cache)
     )
    )
   )
  )
  (call $add_slow
   (local.get $lhs)
   (local.get $rhs)
   (local.get $cache)
  )
 )
 (func $main (type $23) (result anyref)
  (local $user_x anyref)
  (local $user_f anyref)
  (local $temp_0 (ref null $Object))
  (local $user_res anyref)
  (local $temp_1 (ref null $Closure))
  (local.set $user_x
   (ref.i31
    (i32.const 10)
   )
  )
  (local.set $user_f
   (block (result (ref $Closure))
    (call $set_storage
     (ref.as_non_null
      (local.tee $temp_0
       (call $new_object
        (global.get $shape_literal_0)
        (i32.const 1)
       )
      )
     )
     (i32.const 0)
     (local.get $user_x)
    )
    (struct.new $Closure
     (ref.func $closure_0)
     (local.get $temp_0)
    )
   )
  )
  (local.set $user_res
   (block (result anyref)
    (call_ref $ClosureSig1
     (struct.get $Closure $env
      (local.tee $temp_1
       (ref.cast (ref $Closure)
        (local.get $user_f)
       )
      )
     )
     (ref.null none)
     (ref.i31
      (i32.const 20)
     )
     (ref.cast (ref $ClosureSig1)
      (struct.get $Closure $func
       (local.get $temp_1)
      )
     )
    )
   )
  )
  (block (result anyref)
   (call $console_log
    (local.get $user_res)
   )
   (ref.null none)
  )
 )
 (func $closure_0 (type $ClosureSig1) (param $env anyref) (param $this anyref) (param $user_y anyref) (result anyref)
  (call $add_cached
   (call $get_field_cached
    (ref.cast (ref $Object)
     (local.get $env)
    )
    (global.get $site_0)
    (i32.const 0)
   )
   (local.get $user_y)
   (global.get $site_bin_0)
  )
 )
)
