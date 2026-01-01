(module
 (type $BoxedF64 (struct (field f64)))
 (type $1 (func (result anyref)))
 (export "main" (func $main))
 (func $main (type $1) (result anyref)
  (struct.new $BoxedF64
   (f64.const 1234.56)
  )
 )
)
