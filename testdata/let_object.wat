(module
 (rec
  (type $Shape (struct (field $parent (ref null $Shape)) (field $key i32) (field $offset i32)))
  (type $Storage (array (mut anyref)))
  (type $Object (struct (field $shape (mut (ref $Shape))) (field $storage (mut (ref $Storage)))))
  (type $CallSite (struct (field $expected_shape (mut (ref null $Shape))) (field $offset (mut i32))))
 )
 (type $4 (func (param (ref string))))
 (type $5 (func (result anyref)))
 (import "env" "print_string" (func $print_string (type $4) (param (ref string))))
 (global $"string.const_\"[object Object]\"" (ref string) (string.const "[object Object]"))
 (export "test" (func $test))
 (func $test (type $5) (result anyref)
  (array.set $Storage
   (array.new_default $Storage
    (i32.const 1)
   )
   (i32.const 0)
   (ref.i31
    (i32.const 10)
   )
  )
  (call $print_string
   (global.get $"string.const_\"[object Object]\"")
  )
  (ref.null none)
 )
)
