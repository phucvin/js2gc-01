(module
  (rec
    (type $Shape (struct (field $id i32)))

    (type $Storage (array (mut anyref)))

    (type $Object (struct
      (field $shape (mut (ref $Shape)))
      (field $storage (mut (ref $Storage)))
    ))

    (type $BoxedF64 (struct (field $val f64)))

    (type $BinaryOpFunc (func (param (ref $Object)) (param (ref $Object)) (result (ref $Object))))

    (type $BinaryOpCallSite (struct
      (field $shape_lhs (mut (ref null $Shape)))
      (field $shape_rhs (mut (ref null $Shape)))
      (field $target (mut (ref null $BinaryOpFunc)))
    ))
  )

  ;; Globals
  (global $g_shape_int (mut (ref null $Shape)) (ref.null $Shape))
  (global $g_shape_float (mut (ref null $Shape)) (ref.null $Shape))

  ;; Declaration for ref.func
  (elem declare func $add_i32_i32 $add_f64_f64 $add_i32_f64 $add_f64_i32)

  ;; Helpers
  (func $init_shapes
    (global.set $g_shape_int (struct.new $Shape (i32.const 1)))
    (global.set $g_shape_float (struct.new $Shape (i32.const 2)))
  )

  (func $new_int (param $val i32) (result (ref $Object))
    (local $obj (ref $Object))
    (local.set $obj (struct.new $Object
      (ref.as_non_null (global.get $g_shape_int))
      (array.new_fixed $Storage 1 (ref.i31 (local.get $val)))
    ))
    (local.get $obj)
  )

  (func $new_float (param $val f64) (result (ref $Object))
    (local $obj (ref $Object))
    (local.set $obj (struct.new $Object
      (ref.as_non_null (global.get $g_shape_float))
      (array.new_fixed $Storage 1 (struct.new $BoxedF64 (local.get $val)))
    ))
    (local.get $obj)
  )

  (func $get_int (param $obj (ref $Object)) (result i32)
    (i31.get_s (ref.cast (ref i31) (array.get $Storage (struct.get $Object $storage (local.get $obj)) (i32.const 0))))
  )

  (func $get_float (param $obj (ref $Object)) (result f64)
    (struct.get $BoxedF64 $val (ref.cast (ref $BoxedF64) (array.get $Storage (struct.get $Object $storage (local.get $obj)) (i32.const 0))))
  )

  ;; Specialized Adds
  (func $add_i32_i32 (type $BinaryOpFunc)
    (call $new_int (i32.add (call $get_int (local.get 0)) (call $get_int (local.get 1))))
  )

  (func $add_f64_f64 (type $BinaryOpFunc)
    (call $new_float (f64.add (call $get_float (local.get 0)) (call $get_float (local.get 1))))
  )

  (func $add_i32_f64 (type $BinaryOpFunc)
    (call $new_float (f64.add (f64.convert_i32_s (call $get_int (local.get 0))) (call $get_float (local.get 1))))
  )

  (func $add_f64_i32 (type $BinaryOpFunc)
    (call $new_float (f64.add (call $get_float (local.get 0)) (f64.convert_i32_s (call $get_int (local.get 1)))))
  )

  ;; Slow path
  (func $add_slow (param $lhs (ref $Object)) (param $rhs (ref $Object)) (param $cache (ref $BinaryOpCallSite)) (result (ref $Object))
    (local $s_lhs (ref $Shape))
    (local $s_rhs (ref $Shape))
    (local $target (ref null $BinaryOpFunc))

    (local.set $s_lhs (struct.get $Object $shape (local.get $lhs)))
    (local.set $s_rhs (struct.get $Object $shape (local.get $rhs)))

    ;; Default target (safe fallback)
    (local.set $target (ref.func $add_f64_f64))

    ;; Dispatch
    (if (ref.eq (local.get $s_lhs) (ref.as_non_null (global.get $g_shape_int)))
      (then
        (if (ref.eq (local.get $s_rhs) (ref.as_non_null (global.get $g_shape_int)))
          (then (local.set $target (ref.func $add_i32_i32)))
          (else (local.set $target (ref.func $add_i32_f64)))
        )
      )
      (else
        (if (ref.eq (local.get $s_rhs) (ref.as_non_null (global.get $g_shape_int)))
          (then (local.set $target (ref.func $add_f64_i32)))
          (else (local.set $target (ref.func $add_f64_f64)))
        )
      )
    )

    ;; Update Cache
    (struct.set $BinaryOpCallSite $shape_lhs (local.get $cache) (local.get $s_lhs))
    (struct.set $BinaryOpCallSite $shape_rhs (local.get $cache) (local.get $s_rhs))
    (struct.set $BinaryOpCallSite $target (local.get $cache) (local.get $target))

    ;; Call
    (call_ref $BinaryOpFunc (local.get $lhs) (local.get $rhs) (ref.as_non_null (local.get $target)))
  )

  ;; Main Add (with cache)
  (func $add (param $lhs (ref $Object)) (param $rhs (ref $Object)) (param $cache (ref $BinaryOpCallSite)) (result (ref $Object))
    (if (ref.eq (struct.get $Object $shape (local.get $lhs)) (struct.get $BinaryOpCallSite $shape_lhs (local.get $cache)))
      (then
        (if (ref.eq (struct.get $Object $shape (local.get $rhs)) (struct.get $BinaryOpCallSite $shape_rhs (local.get $cache)))
          (then
            (call_ref $BinaryOpFunc (local.get $lhs) (local.get $rhs) (ref.as_non_null (struct.get $BinaryOpCallSite $target (local.get $cache))))
          )
          (else
            (call $add_slow (local.get $lhs) (local.get $rhs) (local.get $cache))
          )
        )
      )
      (else
        (call $add_slow (local.get $lhs) (local.get $rhs) (local.get $cache))
      )
    )
  )

  ;; Main
  (func $main (result i32)
    (local $o1 (ref $Object))
    (local $o2 (ref $Object))
    (local $res (ref $Object))
    (local $cache (ref $BinaryOpCallSite))

    (call $init_shapes)

    (local.set $cache (struct.new $BinaryOpCallSite (ref.null $Shape) (ref.null $Shape) (ref.null $BinaryOpFunc)))

    ;; 10 + 20 = 30 (Int + Int)
    (local.set $o1 (call $new_int (i32.const 10)))
    (local.set $o2 (call $new_int (i32.const 20)))
    (local.set $res (call $add (local.get $o1) (local.get $o2) (local.get $cache)))

    ;; Check result 30
    (if (i32.ne (call $get_int (local.get $res)) (i32.const 30))
      (then (return (i32.const 0)))
    )

    ;; 10 + 2.5 = 12.5 (Int + Float) - This will change cache
    (local.set $o2 (call $new_float (f64.const 2.5)))
    (local.set $res (call $add (local.get $o1) (local.get $o2) (local.get $cache)))

    (if (f64.ne (call $get_float (local.get $res)) (f64.const 12.5))
      (then (return (i32.const 0)))
    )

    ;; 10 + 2.5 again - Should hit cache
    (local.set $res (call $add (local.get $o1) (local.get $o2) (local.get $cache)))
     (if (f64.ne (call $get_float (local.get $res)) (f64.const 12.5))
      (then (return (i32.const 0)))
    )

    (i32.const 1) ;; Success
  )

  (export "main" (func $main))
)
