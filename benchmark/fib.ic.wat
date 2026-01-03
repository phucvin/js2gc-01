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
 (type $ClosureSig1 (func (param anyref anyref) (result anyref)))
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedI32 (struct (field i32)))
 (type $11 (func (param i32)))
 (type $12 (func (param f64)))
 (type $13 (func (param anyref) (result i32)))
 (type $14 (func (param anyref anyref (ref $BinaryOpCallSite)) (result anyref)))
 (type $15 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $11) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $12) (param f64)))
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
 (elem declare func $add_f64_f64 $add_f64_i32 $add_i32_f64 $add_i32_i32 $add_unsupported $sub_f64_f64 $sub_f64_i32 $sub_i32_f64 $sub_i32_i32 $sub_unsupported)
 (export "main" (func $main))
 (func $console_log (type $ClosureSig0) (param $val anyref) (result anyref)
  (if
   (ref.is_null
    (local.get $val)
   )
   (then
    (nop)
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
          (nop)
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
 (func $get_type_id (type $13) (param $val anyref) (result i32)
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
 (func $add_slow (type $14) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
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
 (func $add_cached (type $14) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
  (if (result anyref)
   (i32.and
    (i32.eq
     (call $get_type_id
      (local.get $lhs)
     )
     (struct.get $BinaryOpCallSite $type_lhs
      (local.get $cache)
     )
    )
    (i32.eq
     (call $get_type_id
      (local.get $rhs)
     )
     (struct.get $BinaryOpCallSite $type_rhs
      (local.get $cache)
     )
    )
   )
   (then
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
   (else
    (call $add_slow
     (local.get $lhs)
     (local.get $rhs)
     (local.get $cache)
    )
   )
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
 (func $sub_slow (type $14) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
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
 (func $sub_cached (type $14) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
  (if (result anyref)
   (i32.eq
    (call $get_type_id
     (local.get $lhs)
    )
    (struct.get $BinaryOpCallSite $type_lhs
     (local.get $cache)
    )
   )
   (then
    (if (result anyref)
     (i32.eq
      (call $get_type_id
       (local.get $rhs)
      )
      (struct.get $BinaryOpCallSite $type_rhs
       (local.get $cache)
      )
     )
     (then
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
     (else
      (call $sub_slow
       (local.get $lhs)
       (local.get $rhs)
       (local.get $cache)
      )
     )
    )
   )
   (else
    (call $sub_slow
     (local.get $lhs)
     (local.get $rhs)
     (local.get $cache)
    )
   )
  )
 )
 (func $less_than (type $ClosureSig1) (param $lhs anyref) (param $rhs anyref) (result anyref)
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
 (func $fib (type $ClosureSig0) (param $user_n anyref) (result anyref)
  (drop
   (if (result nullref)
    (i31.get_s
     (ref.cast (ref i31)
      (call $less_than
       (local.get $user_n)
       (ref.i31
        (i32.const 2)
       )
      )
     )
    )
    (then
     (return
      (local.get $user_n)
     )
    )
    (else
     (ref.null none)
    )
   )
  )
  (call $add_cached
   (call $fib
    (call $sub_cached
     (local.get $user_n)
     (ref.i31
      (i32.const 1)
     )
     (global.get $site_bin_0)
    )
   )
   (call $fib
    (call $sub_cached
     (local.get $user_n)
     (ref.i31
      (i32.const 2)
     )
     (global.get $site_bin_1)
    )
   )
   (global.get $site_bin_2)
  )
 )
 (func $main (type $15) (result anyref)
  (call $console_log
   (call $fib
    (ref.i31
     (i32.const 40)
    )
   )
  )
 )
)
