(module
 (type $BoxedI32 (struct (field i32)))
 (type $1 (func (result anyref)))
 (export "main" (func $main))
 (func $main (type $1) (result anyref)
  (struct.new $BoxedI32
   (i32.const 1073741824)
  )
 )
)
