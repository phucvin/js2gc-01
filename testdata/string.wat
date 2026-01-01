(module
  (type $BoxedNumber (struct (field f64)))
  (type $BoxedString (struct (field (ref string))))
  (func $main (export "main") (result anyref)
    (struct.new $BoxedString (string.const "hello world"))
  )
)