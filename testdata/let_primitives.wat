(module
 (type $0 (func (param i32)))
 (type $1 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $0) (param i32)))
 (export "test" (func $test))
 (func $test (type $1) (result anyref)
  (call $print_i32
   (i32.const 30)
  )
  (ref.null none)
 )
)
