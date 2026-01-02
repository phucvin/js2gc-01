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
 (type $BoxedString (struct (field (ref string))))
 (type $12 (func (param i32)))
 (type $13 (func (param f64)))
 (type $14 (func (param (ref string))))
 (type $15 (func (result (ref $Shape))))
 (type $16 (func (param (ref $Shape) i32 i32) (result (ref $Shape))))
 (type $17 (func (param (ref $Shape) i32) (result (ref $Object))))
 (type $18 (func (param (ref $Object) i32 anyref)))
 (type $19 (func (param (ref $Object) i32 anyref) (result anyref)))
 (type $20 (func (param (ref $Shape) i32) (result i32)))
 (type $21 (func (param (ref $Object) (ref $CallSite) i32) (result anyref)))
 (type $22 (func (param anyref) (result i32)))
 (type $23 (func (param anyref anyref (ref $BinaryOpCallSite)) (result anyref)))
 (type $24 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $12) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $13) (param f64)))
 (import "env" "print_string" (func $print_string (type $14) (param (ref string))))
 (elem declare func $add_f64_f64 $add_f64_i32 $add_i32_f64 $add_i32_i32 $add_unsupported)
 (export "main" (func $main))
 (export "test" (func $test))
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
 (func $put_field (type $19) (param $obj (ref $Object)) (param $key i32) (param $val anyref) (result anyref)
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
  (local.get $val)
 )
 (func $lookup_in_shape (type $20) (param $shape (ref $Shape)) (param $key i32) (result i32)
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
   )
   (local.set $curr
    (struct.get $Shape $parent
     (ref.as_non_null
      (local.get $curr)
     )
    )
   )
   (br $search)
  )
  (i32.const -1)
 )
 (func $get_field_slow (type $21) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
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
 (func $get_field_cached (type $21) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
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
     (string.const "null")
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
               (string.const "[object Object]")
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
 (func $get_type_id (type $22) (param $val anyref) (result i32)
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
 (func $add_slow (type $23) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
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
 (func $add_cached (type $23) (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
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
      (call $add_slow
       (local.get $lhs)
       (local.get $rhs)
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
 (func $add (type $ClosureSig1) (param $lhs anyref) (param $rhs anyref) (result anyref)
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
       (i32.add
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
      (ref.null none)
     )
    )
   )
   (else
    (ref.null none)
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
 (func $main (type $24) (result anyref)
  (return
   (struct.new $BoxedF64
    (f64.const 1234.56)
   )
  )
 )
 (func $test (type $24) (result anyref)
  (call $console_log
   (call $main)
  )
 )
)
