(module
 (rec
  (type $Shape (struct (field $parent (ref null $Shape)) (field $key i32) (field $offset i32)))
  (type $Storage (array (mut anyref)))
  (type $Object (struct (field $shape (mut (ref $Shape))) (field $storage (mut (ref $Storage)))))
  (type $Closure (struct (field $func funcref) (field $env anyref)))
  (type $BinaryOpFunc (func (param anyref anyref) (result anyref)))
 )
 (type $ClosureSig0 (func (param anyref anyref) (result anyref)))
 (type $BoxedF64 (struct (field f64)))
 (type $BoxedI32 (struct (field i32)))
 (type $String (array (mut i8)))
 (type $9 (func (param i32)))
 (type $10 (func (param f64)))
 (type $11 (func (result (ref $Shape))))
 (type $12 (func (param (ref $Shape) i32 i32) (result (ref $Shape))))
 (type $13 (func (param (ref $Shape) i32) (result (ref $Object))))
 (type $14 (func (param (ref $Object) i32 anyref)))
 (type $15 (func (param (ref $Shape) i32) (result i32)))
 (type $16 (func (param (ref $Object) i32) (result anyref)))
 (type $17 (func (param (ref $String))))
 (type $18 (func (param anyref)))
 (type $19 (func (param anyref) (result i32)))
 (type $20 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $9) (param i32)))
 (import "env" "print_f64" (func $print_f64 (type $10) (param f64)))
 (import "env" "print_char" (func $print_char (type $9) (param i32)))
 (elem declare func $add_f64_f64 $add_f64_i32 $add_i32_f64 $add_i32_i32 $add_unsupported)
 (export "main" (func $main))
 (func $new_root_shape (type $11) (result (ref $Shape))
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
 )
 (func $extend_shape (type $12) (param $parent (ref $Shape)) (param $key i32) (param $offset i32) (result (ref $Shape))
  (struct.new $Shape
   (local.get $parent)
   (local.get $key)
   (local.get $offset)
  )
 )
 (func $new_object (type $13) (param $shape (ref $Shape)) (param $size i32) (result (ref $Object))
  (struct.new $Object
   (local.get $shape)
   (array.new_default $Storage
    (local.get $size)
   )
  )
 )
 (func $set_storage (type $14) (param $obj (ref $Object)) (param $idx i32) (param $val anyref)
  (array.set $Storage
   (struct.get $Object $storage
    (local.get $obj)
   )
   (local.get $idx)
   (local.get $val)
  )
 )
 (func $put_field (type $14) (param $obj (ref $Object)) (param $key i32) (param $val anyref)
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
 (func $lookup_in_shape (type $15) (param $shape (ref $Shape)) (param $key i32) (result i32)
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
 (func $get_field_slow (type $16) (param $obj (ref $Object)) (param $key i32) (result anyref)
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
 (func $get_type_id (type $19) (param $val anyref) (result i32)
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
 (func $add_slow (type $ClosureSig0) (param $lhs anyref) (param $rhs anyref) (result anyref)
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
  (call_ref $BinaryOpFunc
   (local.get $lhs)
   (local.get $rhs)
   (ref.as_non_null
    (local.get $target)
   )
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
 (func $main (type $20) (result anyref)
  (local $user_o anyref)
  (local $temp_0 (ref null $Object))
  (local $user_i anyref)
  (local $temp_1 anyref)
  (local.set $user_o
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
      (i32.const 0)
     )
    )
    (ref.as_non_null
     (local.get $temp_0)
    )
   )
  )
  (local.set $user_i
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
          (local.get $user_i)
          (ref.i31
           (i32.const 1000000)
          )
         )
        )
       )
      )
     )
     (call $put_field
      (ref.cast (ref $Object)
       (local.get $user_o)
      )
      (i32.const 0)
      (call $add_slow
       (call $get_field_slow
        (ref.cast (ref $Object)
         (local.get $user_o)
        )
        (i32.const 0)
       )
       (ref.i31
        (i32.const 1)
       )
      )
     )
     (drop
      (block (result anyref)
       (local.set $temp_1
        (local.get $user_i)
       )
       (local.set $user_i
        (call $add_slow
         (local.get $temp_1)
         (ref.i31
          (i32.const 1)
         )
        )
       )
       (local.get $temp_1)
      )
     )
     (br $continue)
    )
   )
  )
  (block (result nullref)
   (call $console_log
    (call $get_field_slow
     (ref.cast (ref $Object)
      (local.get $user_o)
     )
     (i32.const 0)
    )
   )
   (ref.null none)
  )
 )
)
