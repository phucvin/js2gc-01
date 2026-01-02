(module
 (type $0 (func (param i32)))
 (type $1 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $0) (param i32)))
 (export "main" (func $main))
 (export "test" (func $test))
 (func $main (type $1) (result anyref)
  (ref.i31
   (i32.const 42)
  )
 )
 (func $test (type $1) (result anyref)
  (call $print_i32
   (i32.const 42)
  )
  (ref.null none)
 )
)
