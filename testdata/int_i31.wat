(module
  (type $BoxedF64 (struct (field f64)))
  (type $BoxedI32 (struct (field i32)))
  (type $BoxedString (struct (field (ref string))))
  (func $add (param $lhs anyref) (param $rhs anyref) (result anyref)
    (if (result anyref) (ref.test i31ref (local.get $lhs))
      (then
        (if (result anyref) (ref.test i31ref (local.get $rhs))
          (then
            (ref.i31 (i32.add
              (i31.get_s (ref.cast i31ref (local.get $lhs)))
              (i31.get_s (ref.cast i31ref (local.get $rhs)))
            ))
          )
          (else
            (ref.null any)
          )
        )
      )
      (else
        (ref.null any)
      )
    )
  )

  (func $main (export "main") (result anyref)
    (ref.i31 (i32.const 100))
  )
)