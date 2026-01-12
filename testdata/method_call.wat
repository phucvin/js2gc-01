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
 (type $ClosureSig2 (func (param anyref anyref anyref anyref) (result anyref)))
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedI32 (struct (field i32)))
 (type $String (array (mut i8)))
 (type $11 (func (param i32)))
 (type $12 (func (param f64)))
 (type $13 (func (result (ref $Shape))))
 (type $14 (func (param (ref $Shape) i32 i32) (result (ref $Shape))))
 (type $15 (func (param (ref $Shape) i32) (result (ref $Object))))
 (type $16 (func (param (ref $Object) i32 anyref)))
 (type $17 (func (param (ref $Shape) i32) (result i32)))
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
 (global $site_1 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
 ))
 (global $site_bin_0 (mut (ref $BinaryOpCallSite)) (struct.new $BinaryOpCallSite
  (i32.const 0)
  (i32.const 0)
  (ref.null nofunc)
 ))
 (global $site_bin_1 (mut (ref $BinaryOpCallSite)) (struct.new $BinaryOpCallSite
  (i32.const 0)
  (i32.const 0)
  (ref.null nofunc)
 ))
 (elem declare func $add_f64_f64 $add_f64_i32 $add_i32_f64 $add_i32_i32 $add_unsupported $closure_0 $closure_1 $sub_f64_f64 $sub_f64_i32 $sub_i32_f64 $sub_i32_i32 $sub_unsupported)
 (export "main" (func $main))
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
 (func $put_field (type $16) (param $obj (ref $Object)) (param $key i32) (param $val anyref)
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
 (func $lookup_in_shape (type $17) (param $shape (ref $Shape)) (param $key i32) (result i32)
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
 (func $get_field_slow (type $18) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
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
 (func $get_field_cached (type $18) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
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
   (ref.as_non_null
    (local.get $target)
   )
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
     (ref.as_non_null
      (struct.get $BinaryOpCallSite $target
       (local.get $cache)
      )
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
 (func $sub_i32_i32 (type $BinaryOpFunc) (param $0 anyref) (param $1 anyref) (result anyref)
  (ref.i31
   (i32.sub
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
 (func $sub_f64_f64 (type $BinaryOpFunc) (param $0 anyref) (param $1 anyref) (result anyref)
  (struct.new $BoxedF64
   (f64.sub
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
 (func $sub_i32_f64 (type $BinaryOpFunc) (param $0 anyref) (param $1 anyref) (result anyref)
  (struct.new $BoxedF64
   (f64.sub
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
 (func $sub_f64_i32 (type $BinaryOpFunc) (param $0 anyref) (param $1 anyref) (result anyref)
  (struct.new $BoxedF64
   (f64.sub
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
 (func $sub_unsupported (type $BinaryOpFunc) (param $0 anyref) (param $1 anyref) (result anyref)
  (ref.null none)
 )
 (func $sub_slow (type $22) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
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
   (ref.func $sub_unsupported)
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
       (ref.func $sub_i32_i32)
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
         (ref.func $sub_i32_f64)
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
         (ref.func $sub_f64_i32)
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
           (ref.func $sub_f64_f64)
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
   (ref.as_non_null
    (local.get $target)
   )
  )
 )
 (func $sub_cached (type $22) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
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
     (ref.as_non_null
      (struct.get $BinaryOpCallSite $target
       (local.get $cache)
      )
     )
    )
   )
  )
  (call $sub_slow
   (local.get $lhs)
   (local.get $rhs)
   (local.get $cache)
  )
 )
 (func $main (type $23) (result anyref)
  (local $user_obj anyref)
  (local $temp_0 (ref null $Object))
  (local $temp_1 (ref null $Object))
  (local $temp_2 anyref)
  (local $temp_3 (ref null $Closure))
  (local $user_obj2 anyref)
  (local $temp_4 (ref null $Object))
  (local $temp_5 (ref null $Object))
  (local $temp_6 anyref)
  (local $temp_7 (ref null $Closure))
  (local.set $user_obj
   (block (result (ref $Object))
    (local.set $temp_0
     (call $new_object
      (call $new_root_shape)
      (i32.const 0)
     )
    )
    (ref.as_non_null
     (local.get $temp_0)
    )
   )
  )
  (call $put_field
   (ref.cast (ref $Object)
    (local.get $user_obj)
   )
   (i32.const 0)
   (block (result (ref $Closure))
    (local.set $temp_1
     (call $new_object
      (call $new_root_shape)
      (i32.const 0)
     )
    )
    (struct.new $Closure
     (ref.func $closure_0)
     (ref.as_non_null
      (local.get $temp_1)
     )
    )
   )
  )
  (call $console_log
   (block (result anyref)
    (local.set $temp_2
     (local.get $user_obj)
    )
    (local.set $temp_3
     (ref.cast (ref $Closure)
      (call $get_field_cached
       (ref.cast (ref $Object)
        (local.get $temp_2)
       )
       (global.get $site_0)
       (i32.const 0)
      )
     )
    )
    (call_ref $ClosureSig2
     (struct.get $Closure $env
      (ref.as_non_null
       (local.get $temp_3)
      )
     )
     (local.get $temp_2)
     (ref.i31
      (i32.const 1)
     )
     (ref.i31
      (i32.const 2)
     )
     (ref.cast (ref $ClosureSig2)
      (struct.get $Closure $func
       (ref.as_non_null
        (local.get $temp_3)
       )
      )
     )
    )
   )
  )
  (local.set $user_obj2
   (block (result (ref $Object))
    (local.set $temp_4
     (call $new_object
      (call $extend_shape
       (call $new_root_shape)
       (i32.const 1)
       (i32.const 0)
      )
      (i32.const 1)
     )
    )
    (call $set_storage
     (ref.as_non_null
      (local.get $temp_4)
     )
     (i32.const 0)
     (block (result (ref $Closure))
      (local.set $temp_5
       (call $new_object
        (call $new_root_shape)
        (i32.const 0)
       )
      )
      (struct.new $Closure
       (ref.func $closure_1)
       (ref.as_non_null
        (local.get $temp_5)
       )
      )
     )
    )
    (ref.as_non_null
     (local.get $temp_4)
    )
   )
  )
  (block (result anyref)
   (call $console_log
    (block (result anyref)
     (local.set $temp_6
      (local.get $user_obj2)
     )
     (local.set $temp_7
      (ref.cast (ref $Closure)
       (call $get_field_cached
        (ref.cast (ref $Object)
         (local.get $temp_6)
        )
        (global.get $site_1)
        (i32.const 1)
       )
      )
     )
     (call_ref $ClosureSig2
      (struct.get $Closure $env
       (ref.as_non_null
        (local.get $temp_7)
       )
      )
      (local.get $temp_6)
      (ref.i31
       (i32.const 5)
      )
      (ref.i31
       (i32.const 3)
      )
      (ref.cast (ref $ClosureSig2)
       (struct.get $Closure $func
        (ref.as_non_null
         (local.get $temp_7)
        )
       )
      )
     )
    )
   )
   (ref.null none)
  )
 )
 (func $closure_0 (type $ClosureSig2) (param $env anyref) (param $this anyref) (param $user_a anyref) (param $user_b anyref) (result anyref)
  (call $add_cached
   (local.get $user_a)
   (local.get $user_b)
   (global.get $site_bin_0)
  )
 )
 (func $closure_1 (type $ClosureSig2) (param $env anyref) (param $this anyref) (param $user_a anyref) (param $user_b anyref) (result anyref)
  (call $sub_cached
   (local.get $user_a)
   (local.get $user_b)
   (global.get $site_bin_1)
  )
 )
)
