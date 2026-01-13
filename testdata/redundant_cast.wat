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
 (type $ClosureSig0 (func (param anyref anyref) (result anyref)))
 (type $String (array (mut i8)))
 (type $9 (func (result (ref $Shape))))
 (type $10 (func (param (ref $Shape) i32 (ref null $Object)) (result (ref $Object))))
 (type $11 (func))
 (type $12 (func (param (ref $Object) i32 anyref)))
 (type $13 (func (param (ref $Shape) i32) (result i32)))
 (type $14 (func (param (ref $Object) (ref $Shape) (ref null $CallSite) i32) (result anyref)))
 (type $15 (func (param (ref $Object) (ref $CallSite) i32) (result anyref)))
 (type $16 (func (result anyref)))
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
  (ref.null none)
  (i32.const -1)
  (i32.const -1)
 ))
 (global $shape_literal_1 (ref $Shape) (struct.new $Shape
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
  (i32.const 0)
  (i32.const 0)
 ))
 (global $shape_literal_2 (ref $Shape) (struct.new $Shape
  (struct.new $Shape
   (struct.new $Shape
    (ref.null none)
    (i32.const -1)
    (i32.const -1)
   )
   (i32.const 0)
   (i32.const 0)
  )
  (i32.const 1)
  (i32.const 1)
 ))
 (global $shape_literal_3 (ref $Shape) (struct.new $Shape
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
  (i32.const 2)
  (i32.const 0)
 ))
 (global $shape_literal_4 (ref $Shape) (struct.new $Shape
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
  (i32.const 3)
  (i32.const 0)
 ))
 (global $g_str_null (mut (ref null $String)) (ref.null none))
 (global $g_str_obj (mut (ref null $String)) (ref.null none))
 (global $g_obj_proto (mut (ref null $Object)) (ref.null none))
 (data $str_data_0 "null")
 (data $str_data_1 "[object Object]")
 (elem declare func $closure_0 $closure_1 $closure_2)
 (export "main" (func $main))
 (start $runtime_init)
 (func $new_root_shape (type $9) (result (ref $Shape))
  (struct.new $Shape
   (ref.null none)
   (i32.const -1)
   (i32.const -1)
  )
 )
 (func $new_object (type $10) (param $shape (ref $Shape)) (param $size i32) (param $proto (ref null $Object)) (result (ref $Object))
  (struct.new $Object
   (local.get $shape)
   (array.new_default $Storage
    (local.get $size)
   )
   (local.get $proto)
  )
 )
 (func $runtime_init (type $11)
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
 (func $set_storage (type $12) (param $obj (ref $Object)) (param $idx i32) (param $val anyref)
  (array.set $Storage
   (struct.get $Object $storage
    (local.get $obj)
   )
   (local.get $idx)
   (local.get $val)
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
 (func $get_field_resolve (type $14) (param $obj (ref $Object)) (param $shape (ref $Shape)) (param $cache (ref null $CallSite)) (param $key i32) (result anyref)
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
 (func $get_field_cached (type $15) (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
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
 (func $main (type $16) (result anyref)
  (local $user_empty anyref)
  (local $user_one anyref)
  (local $temp_0 (ref null $Object))
  (local $user_two anyref)
  (local $temp_1 (ref null $Object))
  (local $user_f anyref)
  (local $temp_2 (ref null $Object))
  (local $temp_3 (ref null $Closure))
  (local $user_x anyref)
  (local $user_g anyref)
  (local $temp_4 (ref null $Object))
  (local $temp_5 (ref null $Closure))
  (local $user_obj anyref)
  (local $temp_6 (ref null $Object))
  (local $temp_7 (ref null $Object))
  (local $temp_8 anyref)
  (local $temp_9 (ref null $Closure))
  (local.set $user_empty
   (call $new_object
    (global.get $shape_literal_0)
    (i32.const 0)
    (global.get $g_obj_proto)
   )
  )
  (local.set $user_one
   (block (result (ref $Object))
    (local.set $temp_0
     (call $new_object
      (global.get $shape_literal_1)
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
    (local.set $temp_1
     (call $new_object
      (global.get $shape_literal_2)
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
   (struct.new $Closure
    (ref.func $closure_0)
    (call $new_object
     (global.get $shape_literal_0)
     (i32.const 0)
     (ref.null none)
    )
   )
  )
  (drop
   (block (result anyref)
    (call_ref $ClosureSig0
     (struct.get $Closure $env
      (local.tee $temp_3
       (ref.cast (ref $Closure)
        (local.get $user_f)
       )
      )
     )
     (ref.null none)
     (ref.cast (ref $ClosureSig0)
      (struct.get $Closure $func
       (local.get $temp_3)
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
      (local.tee $temp_4
       (call $new_object
        (global.get $shape_literal_3)
        (i32.const 1)
        (ref.null none)
       )
      )
     )
     (i32.const 0)
     (local.get $user_x)
    )
    (struct.new $Closure
     (ref.func $closure_1)
     (local.get $temp_4)
    )
   )
  )
  (drop
   (block (result anyref)
    (call_ref $ClosureSig0
     (struct.get $Closure $env
      (local.tee $temp_5
       (ref.cast (ref $Closure)
        (local.get $user_g)
       )
      )
     )
     (ref.null none)
     (ref.cast (ref $ClosureSig0)
      (struct.get $Closure $func
       (local.get $temp_5)
      )
     )
    )
   )
  )
  (local.set $user_obj
   (block (result (ref $Object))
    (local.set $temp_6
     (call $new_object
      (global.get $shape_literal_4)
      (i32.const 1)
      (global.get $g_obj_proto)
     )
    )
    (call $set_storage
     (ref.as_non_null
      (local.get $temp_6)
     )
     (i32.const 0)
     (struct.new $Closure
      (ref.func $closure_2)
      (call $new_object
       (global.get $shape_literal_0)
       (i32.const 0)
       (ref.null none)
      )
     )
    )
    (ref.as_non_null
     (local.get $temp_6)
    )
   )
  )
  (block (result anyref)
   (local.set $temp_8
    (local.get $user_obj)
   )
   (call_ref $ClosureSig0
    (struct.get $Closure $env
     (local.tee $temp_9
      (ref.cast (ref $Closure)
       (call $get_field_cached
        (ref.cast (ref $Object)
         (local.get $temp_8)
        )
        (global.get $site_1)
        (i32.const 3)
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
 (func $closure_0 (type $ClosureSig0) (param $env anyref) (param $this anyref) (result anyref)
  (ref.null none)
 )
 (func $closure_1 (type $ClosureSig0) (param $env anyref) (param $this anyref) (result anyref)
  (call $get_field_cached
   (ref.cast (ref $Object)
    (local.get $env)
   )
   (global.get $site_0)
   (i32.const 2)
  )
 )
 (func $closure_2 (type $ClosureSig0) (param $env anyref) (param $this anyref) (result anyref)
  (ref.null none)
 )
)
