(module
 (rec
  (type $Shape (struct (field $parent (ref null $Shape)) (field $key i32) (field $offset i32)))
  (type $Storage (array (mut anyref)))
  (type $Object (struct (field $shape (mut (ref $Shape))) (field $storage (mut (ref $Storage))) (field $proto (mut (ref null $Object)))))
  (type $CallSite (struct (field $expected_shape (mut (ref null $Shape))) (field $target_object (mut (ref null $Object))) (field $target_shape (mut (ref null $Shape))) (field $offset (mut i32))))
  (type $Closure (struct (field $func (ref func)) (field $env anyref)))
  (type $BinaryOpFunc (func (param anyref anyref) (result anyref)))
  (type $BinaryOpCallSite (struct (field $type_lhs (mut i32)) (field $type_rhs (mut i32)) (field $target (mut (ref null $BinaryOpFunc)))))
 )
 (type $ClosureSig0 (func (param anyref anyref) (result anyref)))
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedI32 (struct (field i32)))
 (type $String (array (mut i8)))
 (type $11 (func (param i32)))
 (type $12 (func (param f64)))
 (type $13 (func))
 (type $14 (func (param (ref $String))))
 (type $15 (func (param anyref)))
 (type $16 (func (param anyref) (result i32)))
 (type $17 (func (param anyref anyref (ref $BinaryOpCallSite)) (result anyref)))
 (type $18 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $11) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $12) (param f64)))
 (import "env" "print_char" (func $print_char (type $11) (param i32)))
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
 (global $site_bin_2 (mut (ref $BinaryOpCallSite)) (struct.new $BinaryOpCallSite
  (i32.const 0)
  (i32.const 0)
  (ref.null nofunc)
 ))
 (global $site_bin_3 (mut (ref $BinaryOpCallSite)) (struct.new $BinaryOpCallSite
  (i32.const 0)
  (i32.const 0)
  (ref.null nofunc)
 ))
 (global $site_bin_4 (mut (ref $BinaryOpCallSite)) (struct.new $BinaryOpCallSite
  (i32.const 0)
  (i32.const 0)
  (ref.null nofunc)
 ))
 (global $site_bin_5 (mut (ref $BinaryOpCallSite)) (struct.new $BinaryOpCallSite
  (i32.const 0)
  (i32.const 0)
  (ref.null nofunc)
 ))
 (global $g_str_null (mut (ref null $String)) (ref.null none))
 (global $g_str_obj (mut (ref null $String)) (ref.null none))
 (data $str_data_0 "null")
 (data $str_data_1 "[object Object]")
 (elem declare func $add_f64_f64 $add_f64_i32 $add_i32_f64 $add_i32_i32 $add_unsupported)
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
 (func $print_string_helper (type $14) (param $str (ref $String))
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
 (func $console_log (type $15) (param $val anyref)
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
                 (br_on_cast $i31 anyref (ref i31)
                  (local.get $val)
                 )
                )
                (drop
                 (br_on_cast $boxed_i32 anyref (ref $BoxedI32)
                  (local.get $val)
                 )
                )
                (drop
                 (br_on_cast $boxed_f64 anyref (ref $BoxedF64)
                  (local.get $val)
                 )
                )
                (drop
                 (br_on_cast $string anyref (ref $String)
                  (local.get $val)
                 )
                )
                (drop
                 (br_on_cast $object anyref (ref $Object)
                  (local.get $val)
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
 (func $get_type_id (type $16) (param $val anyref) (result i32)
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
 (func $add_slow (type $17) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
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
 (func $add_cached (type $17) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
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
 (func $less_than (type $ClosureSig0) (param $lhs anyref) (param $rhs anyref) (result anyref)
  (if (result anyref)
   (ref.test (ref i31)
    (local.get $lhs)
   )
   (then
    (if (result anyref)
     (ref.test (ref i31)
      (local.get $rhs)
     )
     (then
      (ref.i31
       (i32.lt_s
        (i31.get_s
         (ref.cast (ref i31)
          (local.get $lhs)
         )
        )
        (i31.get_s
         (ref.cast (ref i31)
          (local.get $rhs)
         )
        )
       )
      )
     )
     (else
      (ref.i31
       (i32.const 0)
      )
     )
    )
   )
   (else
    (ref.i31
     (i32.const 0)
    )
   )
  )
 )
 (func $main (type $18) (result anyref)
  (local $user_a anyref)
  (local $user_b anyref)
  (local $user_c anyref)
  (local $user_d anyref)
  (local $user_e anyref)
  (local $user_f anyref)
  (local $user_g anyref)
  (local $user_h anyref)
  (local $user_i anyref)
  (local $user_sum anyref)
  (local $user_j anyref)
  (local $temp_0 anyref)
  (local.set $user_a
   (ref.i31
    (i32.const 10)
   )
  )
  (local.set $user_b
   (ref.i31
    (i32.const 20)
   )
  )
  (local.set $user_c
   (call $add_cached
    (local.get $user_a)
    (local.get $user_b)
    (global.get $site_bin_0)
   )
  )
  (call $console_log
   (local.get $user_c)
  )
  (local.set $user_d
   (struct.new $BoxedF64
    (f64.const 2.5)
   )
  )
  (local.set $user_e
   (call $add_cached
    (local.get $user_a)
    (local.get $user_d)
    (global.get $site_bin_1)
   )
  )
  (call $console_log
   (local.get $user_e)
  )
  (local.set $user_f
   (struct.new $BoxedF64
    (f64.const 5.5)
   )
  )
  (local.set $user_g
   (call $add_cached
    (local.get $user_f)
    (local.get $user_a)
    (global.get $site_bin_2)
   )
  )
  (call $console_log
   (local.get $user_g)
  )
  (local.set $user_h
   (struct.new $BoxedF64
    (f64.const 1.1)
   )
  )
  (local.set $user_i
   (call $add_cached
    (local.get $user_d)
    (local.get $user_h)
    (global.get $site_bin_3)
   )
  )
  (call $console_log
   (local.get $user_i)
  )
  (local.set $user_sum
   (ref.i31
    (i32.const 0)
   )
  )
  (local.set $user_j
   (ref.i31
    (i32.const 0)
   )
  )
  (loop $continue
   (block $break
    (block
     (br_if $break
      (i32.eqz
       (i31.get_s
        (ref.cast (ref i31)
         (call $less_than
          (local.get $user_j)
          (ref.i31
           (i32.const 5)
          )
         )
        )
       )
      )
     )
     (local.set $user_sum
      (call $add_cached
       (local.get $user_sum)
       (local.get $user_j)
       (global.get $site_bin_4)
      )
     )
     (drop
      (block (result anyref)
       (local.set $temp_0
        (local.get $user_j)
       )
       (local.set $user_j
        (call $add_cached
         (local.get $temp_0)
         (ref.i31
          (i32.const 1)
         )
         (global.get $site_bin_5)
        )
       )
       (local.get $temp_0)
      )
     )
     (br $continue)
    )
   )
  )
  (block (result nullref)
   (call $console_log
    (local.get $user_sum)
   )
   (ref.null none)
  )
 )
)
