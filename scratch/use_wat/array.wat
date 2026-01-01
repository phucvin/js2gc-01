(module
  ;; Define an array type: array of i32
  (type $IntArray (array (mut i32)))

  ;; Function to create an array of size 3, fill it, and return the element at index 1
  (func $main (result i32)
    (local $arr (ref $IntArray))

    ;; Create new array of size 3 initialized with 0
    (local.set $arr
      (array.new_default $IntArray (i32.const 3))
    )

    ;; Set index 0 to 10
    (array.set $IntArray
      (local.get $arr)
      (i32.const 0)
      (i32.const 10)
    )

    ;; Set index 1 to 20
    (array.set $IntArray
      (local.get $arr)
      (i32.const 1)
      (i32.const 20)
    )

    ;; Get index 1
    (array.get $IntArray
      (local.get $arr)
      (i32.const 1)
    )
  )

  (export "main" (func $main))
)
