(module
  ;; A generic wrapper struct that holds an anyref.
  (type $Box (struct (field (mut anyref))))

  ;; Function to wrap an i31 (unboxed scalar) into a Box
  (func $box_i31 (param $val i32) (result (ref $Box))
    (struct.new $Box
      (ref.i31 (local.get $val))
    )
  )

  (func $main (result i32)
    (local $b (ref $Box))
    (local.set $b (call $box_i31 (i32.const 123)))

    ;; We have a Box with anyref inside. We know it's an i31.
    ;; We want to get it out.
    ;; struct.get returns anyref.
    ;; We cast it to i31ref.
    ;; Note: 'i31' is the heap type, so we cast to a reference to that heap type.
    ;; Binaryen syntax for casting to i31ref might be `ref.cast (ref i31)` or just `ref.cast_i31`?
    ;; Or maybe `ref.cast null i31`?
    ;; Let's try to infer from common issues. `ref.cast` expects a reference type.
    ;; `(ref i31)` is a valid reference type in recent Wasm.
    ;; Let's try `(ref.cast (ref i31) ...)` again but maybe I had a syntax error?
    ;; The error was `16:16: error: expected reftype`.
    ;; Line 16 was `(ref.cast (ref i31)`.
    ;; Maybe `i31` is not recognized as a heap type keyword inside `ref` in this parser version?
    ;; `i31ref` is the value type.
    ;; `(ref.cast i31ref ...)` ?

    (i31.get_u
      (ref.cast i31ref
        (struct.get $Box 0 (local.get $b))
      )
    )
  )

  (export "main" (func $main))
)
