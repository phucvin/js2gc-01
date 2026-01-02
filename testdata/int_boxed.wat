(module
 (type $BoxedI32 (struct (field i32)))
 (type $1 (func (param i32)))
 (type $2 (func (result anyref)))
 (import "env" "print_i32" (func $print_i32 (type $1) (param i32)))
 (export "main" (func $main))
 (export "test" (func $test))
 (func $main (type $2) (result anyref)
  (struct.new $BoxedI32
   (i32.const 1073741824)
  )
 )
 (func $test (type $2) (result anyref)
  (call $print_i32
   (i32.const 1073741824)
  )
  (ref.null none)
 )
)
