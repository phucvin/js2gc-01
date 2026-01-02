(module
 (type $BoxedF64 (struct (field f64)))
 (type $1 (func (param f64)))
 (type $2 (func (result anyref)))
 (import "env" "print_f64" (func $print_f64 (type $1) (param f64)))
 (export "main" (func $main))
 (export "test" (func $test))
 (func $main (type $2) (result anyref)
  (struct.new $BoxedF64
   (f64.const 1234.56)
  )
 )
 (func $test (type $2) (result anyref)
  (call $print_f64
   (f64.const 1234.56)
  )
  (ref.null none)
 )
)
