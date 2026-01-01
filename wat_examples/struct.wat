(module
  (type $Point (struct (field (mut i32) (mut f64))))

  (func $make_and_get_x (param $val i32) (result i32)
    (struct.get $Point 0
      (struct.new $Point
        (local.get $val)
        (f64.const 20.5)
      )
    )
  )

  (func $main (result i32)
    (call $make_and_get_x (i32.const 42))
  )

  (export "main" (func $main))
)
