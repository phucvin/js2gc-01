(module
  ;; We need to define types in an order that allows forward references or use recursion groups.
  (rec
    ;; Define the function signature for the closure code.
    (type $FuncSig (func (param (ref $Env)) (param i32) (result i32)))

    ;; Define the Environment struct.
    (type $Env (struct (field $captured_val (mut i32))))

    ;; Define the Closure struct.
    (type $Closure (struct
      (field $code (ref $FuncSig))
      (field $env (ref $Env))
    ))
  )

  ;; The code for the closure.
  (func $closure_code (type $FuncSig) (param $env (ref $Env)) (param $arg i32) (result i32)
    (i32.add
      (local.get $arg)
      (struct.get $Env $captured_val (local.get $env))
    )
  )

  ;; A helper to create a closure.
  (func $make_closure (param $val i32) (result (ref $Closure))
    (local $env (ref $Env))
    ;; Create the environment
    (local.set $env
      (struct.new $Env (local.get $val))
    )
    ;; Create the closure struct with the function and the environment
    ;; The error "struct.new operand 0 must have proper type" usually means the first operand to struct.new
    ;; doesn't match the first field type.
    ;; The first field is (ref $FuncSig).
    ;; ref.func $closure_code should produce a funcref, but we need it to be specifically (ref $FuncSig).
    ;; Binaryen might not automatically infer that $closure_code has type $FuncSig just by signature matching.
    ;; We might need to cast or ensure $closure_code is typed correctly.
    ;; But usually `ref.func` produces a `funcref` (which is generic) or a typed function ref if the function is typed?
    ;; Actually, `ref.func` produces `(ref $type)` where `$type` is the type of the function.
    ;; But `$closure_code` definition doesn't explicitly state `(type $FuncSig)`. It just has a signature that matches.
    ;; We should explicitly type the function.

    (struct.new $Closure
      (ref.func $closure_code)
      (local.get $env)
    )
  )

  ;; A helper to call a closure.
  (func $call_closure (param $clos (ref $Closure)) (param $arg i32) (result i32)
    (call_ref $FuncSig
      (struct.get $Closure $env (local.get $clos)) ;; arg 1: env
      (local.get $arg)                             ;; arg 2: regular arg
      (struct.get $Closure $code (local.get $clos)) ;; function pointer
    )
  )

  (func $main (result i32)
    (local $my_closure (ref $Closure))

    (local.set $my_closure (call $make_closure (i32.const 10)))
    (call $call_closure (local.get $my_closure) (i32.const 5))
  )

  (export "main" (func $main))

  (elem declare func $closure_code)
)
