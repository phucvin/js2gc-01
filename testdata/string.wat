(module
 (type $BoxedString (struct (field (ref string))))
 (type $1 (func (result anyref)))
 (global $"string.const_\"hello world\"" (ref string) (string.const "hello world"))
 (export "main" (func $main))
 (func $main (type $1) (result anyref)
  (struct.new $BoxedString
   (global.get $"string.const_\"hello world\"")
  )
 )
)
