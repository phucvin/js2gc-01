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
 (type $String (array (mut i8)))
 (type $9 (func))
 (type $10 (func (param (ref $Shape) i32 i32) (result (ref $Shape))))
 (type $11 (func (param (ref $Shape) i32) (result (ref $Object))))
 (type $12 (func (param (ref $Object) i32 anyref)))
 (type $13 (func (param (ref $Shape) i32) (result i32)))
 (type $14 (func (param (ref $Object) (ref $Shape) (ref $CallSite) i32) (result anyref)))
 (type $15 (func (param (ref $Object) (ref $CallSite) i32) (result anyref)))
 (type $16 (func (result anyref)))
 (global $site_0 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
 ))
 (global $site_1 (mut (ref $CallSite)) (struct.new $CallSite
  (ref.null none)
  (i32.const -1)
 ))
 (global $shape_literal_0 (ref $Shape) (struct.new $Shape
  (ref.null none)
  (i32.const -1)
  (i32.const -1)
  (ref.null none)
 ))
 (global $shape_literal_1 (ref $Shape) (struct.new $Shape
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
   (ref.null none)
  )
  (i32.const 0)
  (i32.const 0)
  (ref.null none)
 ))
 (global $shape_literal_2 (ref $Shape) (struct.new $Shape
  (struct.new $Shape
   (struct.new $Shape
    (ref.null none)
    (i32.const -1)
    (i32.const -1)
    (ref.null none)
   )
   (i32.const 0)
   (i32.const 0)
   (ref.null none)
  )
  (i32.const 1)
  (i32.const 1)
  (ref.null none)
 ))
 (global $shape_literal_3 (ref $Shape) (struct.new $Shape
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
   (ref.null none)
  )
  (i32.const 3)
  (i32.const 0)
  (ref.null none)
 ))
 (global $shape_literal_4 (ref $Shape) (struct.new $Shape
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
   (ref.null none)
  )
  (i32.const 4)
  (i32.const 0)
  (ref.null none)
 ))
 (global $g_str_null (mut (ref null $String)) (ref.null none))
 (global $g_str_obj (mut (ref null $String)) (ref.null none))
 (data $str_data_0 "null")
 (data $str_data_1 "[object Object]")
 (elem declare func $closure_0 $closure_1 $closure_2)
 (export "main" (func $main))
 (start $runtime_init)
 (func $runtime_init (type $9)
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
 (func $extend_shape (type $10) (param $parent (ref $Shape)) (param $key i32) (param $offset i32) (result (ref $Shape))
  (struct.new $Shape
   (local.get $parent)
   (local.get $key)
   (local.get $offset)
   (struct.get $Shape $proto
    (local.get $parent)
   )
  )
 )
 (func $new_object (type $11) (param $shape (ref $Shape)) (param $size i32) (result (ref $Object))
  (struct.new $Object
   (local.get $shape)
   (array.new_default $Storage
    (local.get $size)
   )
  )
 )
 (func $set_storage (type $12) (param $obj (ref $Object)) (param $idx i32) (param $val anyref)
  (array.set $Storage
   (struct.get $Object $storage
    (local.get $obj)
   )
   (local.get $idx)
   (local.get $val)
  )
 )
 (func $put_field (type $12) (param $obj (ref $Object)) (param $key i32) (param $val anyref)
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
 (func $lookup_in_shape (type $13) (param $shape (ref $Shape)) (param $key i32) (result i32)
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
 (func $get_field_resolve (type $14) (param $obj (ref $Object)) (param $shape (ref $Shape)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
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
 (func $get_field_cached (type $15) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
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
 (func $main (type $16) (result anyref)
  (local $user_empty anyref)
  (local $user_one anyref)
  (local $temp_0 (ref null $Object))
  (local $user_two anyref)
  (local $temp_1 (ref null $Object))
  (local $user_f anyref)
  (local $temp_2 (ref null $Object))
  (local $temp_3 (ref null $Closure))
  (local $temp_4 (ref null $Closure))
  (local $user_x anyref)
  (local $user_g anyref)
  (local $temp_5 (ref null $Object))
  (local $temp_6 (ref null $Closure))
  (local $temp_7 (ref null $Closure))
  (local $user_obj anyref)
  (local $temp_8 (ref null $Object))
  (local $temp_9 (ref null $Object))
  (local $temp_10 (ref null $Closure))
  (local $temp_11 anyref)
  (local $temp_12 (ref null $Closure))
  (local.set $user_empty
   (call $new_object
    (global.get $shape_literal_0)
    (i32.const 0)
   )
  )
  (local.set $user_one
   (block (result (ref $Object))
    (call $set_storage
     (ref.as_non_null
      (local.tee $temp_0
       (call $new_object
        (global.get $shape_literal_1)
        (i32.const 1)
       )
      )
     )
     (i32.const 0)
     (ref.i31
      (i32.const 1)
     )
    )
    (ref.as_non_null
     (local.get $temp_0)
    )
   )
  )
  (local.set $user_two
   (block (result (ref $Object))
    (call $set_storage
     (ref.as_non_null
      (local.tee $temp_1
       (call $new_object
        (global.get $shape_literal_2)
        (i32.const 2)
       )
      )
     )
     (i32.const 0)
     (ref.i31
      (i32.const 1)
     )
    )
    (call $set_storage
     (ref.as_non_null
      (local.get $temp_1)
     )
     (i32.const 1)
     (ref.i31
      (i32.const 2)
     )
    )
    (ref.as_non_null
     (local.get $temp_1)
    )
   )
  )
  (local.set $user_f
   (block (result (ref $Closure))
    (local.set $temp_3
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
      (local.get $temp_3)
     )
     (i32.const 2)
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
  (drop
   (block (result anyref)
    (call_ref $ClosureSig0
     (struct.get $Closure $env
      (local.tee $temp_4
       (ref.cast (ref $Closure)
        (local.get $user_f)
       )
      )
     )
     (ref.null none)
     (ref.cast (ref $ClosureSig0)
      (struct.get $Closure $func
       (local.get $temp_4)
      )
     )
    )
   )
  )
  (local.set $user_x
   (ref.i31
    (i32.const 10)
   )
  )
  (local.set $user_g
   (block (result (ref $Closure))
    (call $set_storage
     (ref.as_non_null
      (local.tee $temp_5
       (call $new_object
        (global.get $shape_literal_3)
        (i32.const 1)
       )
      )
     )
     (i32.const 0)
     (local.get $user_x)
    )
    (local.set $temp_6
     (struct.new $Closure
      (global.get $shape_literal_0)
      (array.new_default $Storage
       (i32.const 0)
      )
      (ref.func $closure_1)
      (local.get $temp_5)
      (ref.null none)
     )
    )
    (call $put_field
     (ref.cast (ref $Closure)
      (local.get $temp_6)
     )
     (i32.const 2)
     (call $new_object
      (global.get $shape_literal_0)
      (i32.const 0)
     )
    )
    (ref.as_non_null
     (local.get $temp_6)
    )
   )
  )
  (drop
   (block (result anyref)
    (call_ref $ClosureSig0
     (struct.get $Closure $env
      (local.tee $temp_7
       (ref.cast (ref $Closure)
        (local.get $user_g)
       )
      )
     )
     (ref.null none)
     (ref.cast (ref $ClosureSig0)
      (struct.get $Closure $func
       (local.get $temp_7)
      )
     )
    )
   )
  )
  (local.set $user_obj
   (block (result (ref $Object))
    (call $set_storage
     (ref.as_non_null
      (local.tee $temp_8
       (call $new_object
        (global.get $shape_literal_4)
        (i32.const 1)
       )
      )
     )
     (i32.const 0)
     (block (result (ref $Closure))
      (local.set $temp_10
       (struct.new $Closure
        (global.get $shape_literal_0)
        (array.new_default $Storage
         (i32.const 0)
        )
        (ref.func $closure_2)
        (call $new_object
         (global.get $shape_literal_0)
         (i32.const 0)
        )
        (ref.null none)
       )
      )
      (call $put_field
       (ref.cast (ref $Closure)
        (local.get $temp_10)
       )
       (i32.const 2)
       (call $new_object
        (global.get $shape_literal_0)
        (i32.const 0)
       )
      )
      (ref.as_non_null
       (local.get $temp_10)
      )
     )
    )
    (ref.as_non_null
     (local.get $temp_8)
    )
   )
  )
  (block (result anyref)
   (local.set $temp_11
    (local.get $user_obj)
   )
   (call_ref $ClosureSig0
    (struct.get $Closure $env
     (local.tee $temp_12
      (ref.cast (ref $Closure)
       (call $get_field_cached
        (ref.cast (ref $Object)
         (local.get $temp_11)
        )
        (global.get $site_1)
        (i32.const 4)
       )
      )
     )
    )
    (local.get $temp_11)
    (ref.cast (ref $ClosureSig0)
     (struct.get $Closure $func
      (local.get $temp_12)
     )
    )
   )
  )
 )
 (func $closure_0 (type $ClosureSig0) (param $env anyref) (param $this anyref) (result anyref)
  (ref.null none)
 )
 (func $closure_1 (type $ClosureSig0) (param $env anyref) (param $this anyref) (result anyref)
  (call $get_field_cached
   (ref.cast (ref $Object)
    (local.get $env)
   )
   (global.get $site_0)
   (i32.const 3)
  )
 )
 (func $closure_2 (type $ClosureSig0) (param $env anyref) (param $this anyref) (result anyref)
  (ref.null none)
 )
)
