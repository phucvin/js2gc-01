(module
  (rec
    (type $Shape (struct
      (field $parent (ref null $Shape))
      (field $key i32)
      (field $offset i32)
    ))

    (type $Storage (array (mut anyref)))

    (type $Object (struct
      (field $shape (mut (ref $Shape)))
      (field $storage (mut (ref $Storage)))
    ))

    (type $CallSite (struct
      (field $expected_shape (mut (ref null $Shape)))
      (field $offset (mut i32))
    ))
  )

  (func $new_root_shape (result (ref $Shape))
    (struct.new $Shape
      (ref.null $Shape)
      (i32.const -1)
      (i32.const -1)
    )
  )

  (func $extend_shape (param $parent (ref $Shape)) (param $key i32) (param $offset i32) (result (ref $Shape))
    (struct.new $Shape
      (local.get $parent)
      (local.get $key)
      (local.get $offset)
    )
  )

  (func $lookup_in_shape (param $shape (ref $Shape)) (param $key i32) (result i32)
    (local $curr (ref null $Shape))
    (local.set $curr (local.get $shape))

    (loop $search
      (if (ref.is_null (local.get $curr))
        (then (return (i32.const -1)))
      )

      (if (i32.eq (struct.get $Shape $key (ref.as_non_null (local.get $curr))) (local.get $key))
        (then (return (struct.get $Shape $offset (ref.as_non_null (local.get $curr)))))
      )

      (local.set $curr (struct.get $Shape $parent (ref.as_non_null (local.get $curr))))
      (br $search)
    )
    (i32.const -1)
  )

  (func $new_object (param $shape (ref $Shape)) (param $size i32) (result (ref $Object))
    (struct.new $Object
      (local.get $shape)
      (array.new_default $Storage (local.get $size))
    )
  )

  (func $set_storage (param $obj (ref $Object)) (param $idx i32) (param $val anyref)
    (array.set $Storage (struct.get $Object $storage (local.get $obj))
      (local.get $idx)
      (local.get $val)
    )
  )

  (func $new_callsite (result (ref $CallSite))
    (struct.new $CallSite
      (ref.null $Shape)
      (i32.const -1)
    )
  )

  (func $get_field_slow (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
    (local $offset i32)
    (local $shape (ref $Shape))

    (local.set $shape (struct.get $Object $shape (local.get $obj)))
    (local.set $offset (call $lookup_in_shape (local.get $shape) (local.get $key)))

    (if (i32.ge_s (local.get $offset) (i32.const 0))
      (then
        (struct.set $CallSite $expected_shape (local.get $cache) (local.get $shape))
        (struct.set $CallSite $offset (local.get $cache) (local.get $offset))
        (return (array.get $Storage (struct.get $Object $storage (local.get $obj)) (local.get $offset)))
      )
    )
    (ref.null any)
  )

  (func $get_field_cached (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
    (if (ref.eq
          (struct.get $Object $shape (local.get $obj))
          (struct.get $CallSite $expected_shape (local.get $cache))
        )
      (then
        (return (array.get $Storage
          (struct.get $Object $storage (local.get $obj))
          (struct.get $CallSite $offset (local.get $cache))
        ))
      )
    )
    (call $get_field_slow (local.get $obj) (local.get $cache) (local.get $key))
  )

  (func $main (result i32)
    (local $root (ref $Shape))
    (local $shape_pt (ref $Shape))
    (local $obj (ref $Object))
    (local $cache (ref $CallSite))
    (local $val anyref)

    (local.set $root (call $new_root_shape))
    (local.set $shape_pt (call $extend_shape (local.get $root) (i32.const 1) (i32.const 0)))
    (local.set $shape_pt (call $extend_shape (local.get $shape_pt) (i32.const 2) (i32.const 1)))

    (local.set $obj (call $new_object (local.get $shape_pt) (i32.const 2)))
    (call $set_storage (local.get $obj) (i32.const 0) (ref.i31 (i32.const 10)))
    (call $set_storage (local.get $obj) (i32.const 1) (ref.i31 (i32.const 20)))

    (local.set $cache (call $new_callsite))

    (local.set $val (call $get_field_cached (local.get $obj) (local.get $cache) (i32.const 1)))
    (local.set $val (call $get_field_cached (local.get $obj) (local.get $cache) (i32.const 1)))

    (i31.get_s (ref.cast i31ref (local.get $val)))
  )

  (export "main" (func $main))
)
