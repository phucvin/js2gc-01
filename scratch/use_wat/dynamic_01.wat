(module
  ;; Define types
  (rec
    ;; The generic Object: contains a linked list of properties
    (type $Object (struct (field $props (mut (ref null $Entry)))))

    ;; Linked list entry for properties (key-value pair)
    (type $Entry (struct
      (field $key stringref)
      (field $val (mut anyref))
      (field $next (mut (ref null $Entry)))
    ))

    ;; Method signature: takes 'self' (the object), returns anyref
    (type $MethodSig (func (param (ref $Object)) (result anyref)))

    ;; Wrapper for function reference so it can be stored as anyref
    (type $Method (struct (field $func (ref $MethodSig))))
  )

  ;; Helper: Create a new empty Object
  (func $new_object (result (ref $Object))
    (struct.new $Object (ref.null $Entry))
  )

  ;; Helper: Find an entry by key
  (func $find_entry (param $obj (ref $Object)) (param $key stringref) (result (ref null $Entry))
    (local $curr (ref null $Entry))
    (local.set $curr (struct.get $Object $props (local.get $obj)))

    (loop $search
      (if (ref.is_null (local.get $curr))
        (then (return (ref.null $Entry)))
      )

      (if (string.eq (struct.get $Entry $key (local.get $curr)) (local.get $key))
        (then (return (local.get $curr)))
      )

      (local.set $curr (struct.get $Entry $next (local.get $curr)))
      (br $search)
    )
    (ref.null $Entry)
  )

  ;; Helper: Set field (create if not exists, update if exists)
  (func $set_field (param $obj (ref $Object)) (param $key stringref) (param $val anyref)
    (local $entry (ref null $Entry))
    (local.set $entry (call $find_entry (local.get $obj) (local.get $key)))

    (if (ref.is_null (local.get $entry))
      (then
        ;; Prepend new entry
        (struct.set $Object $props (local.get $obj)
          (struct.new $Entry
            (local.get $key)
            (local.get $val)
            (struct.get $Object $props (local.get $obj))
          )
        )
      )
      (else
        ;; Update existing
        (struct.set $Entry $val (local.get $entry) (local.get $val))
      )
    )
  )

  ;; Helper: Get field (return value or null)
  (func $get_field (param $obj (ref $Object)) (param $key stringref) (result anyref)
    (local $entry (ref null $Entry))
    (local.set $entry (call $find_entry (local.get $obj) (local.get $key)))

    (if (ref.is_null (local.get $entry))
      (then (return (ref.null any)))
    )
    (struct.get $Entry $val (local.get $entry))
  )

  ;; Helper: Call method
  ;; Looks up the field 'method_name', casts it to $Method, calls the underlying function with $obj
  (func $call_method (param $obj (ref $Object)) (param $method_name stringref) (result anyref)
    (local $val anyref)
    (local $method (ref null $Method))

    (local.set $val (call $get_field (local.get $obj) (local.get $method_name)))

    ;; Cast to Method (trap if not a method or null)
    (local.set $method (ref.cast (ref $Method) (local.get $val)))

    (call_ref $MethodSig (local.get $obj) (struct.get $Method $func (local.get $method)))
  )

  ;; --- User Logic ---

  ;; Method: get_x
  (func $get_x (type $MethodSig) (param $self (ref $Object)) (result anyref)
    (call $get_field (local.get $self) (string.const "x"))
  )

  ;; Method: sum_x_y
  (func $sum_x_y (type $MethodSig) (param $self (ref $Object)) (result anyref)
    (local $x anyref)
    (local $y anyref)
    (local $x_val i32)
    (local $y_val i32)

    (local.set $x (call $get_field (local.get $self) (string.const "x")))
    (local.set $y (call $get_field (local.get $self) (string.const "y")))

    ;; Unbox i31s
    (local.set $x_val (i31.get_s (ref.cast i31ref (local.get $x))))
    (local.set $y_val (i31.get_s (ref.cast i31ref (local.get $y))))

    (ref.i31 (i32.add (local.get $x_val) (local.get $y_val)))
  )

  (func $main (result i32)
    (local $obj (ref $Object))
    (local $res anyref)

    (local.set $obj (call $new_object))

    ;; Add field "x" = 10
    (call $set_field (local.get $obj) (string.const "x") (ref.i31 (i32.const 10)))

    ;; Add field "y" = 20
    (call $set_field (local.get $obj) (string.const "y") (ref.i31 (i32.const 20)))

    ;; Add method "get_x"
    (call $set_field (local.get $obj) (string.const "get_x")
      (struct.new $Method (ref.func $get_x))
    )

    ;; Add method "sum"
    (call $set_field (local.get $obj) (string.const "sum")
      (struct.new $Method (ref.func $sum_x_y))
    )

    ;; Call "sum" -> should be 30
    (local.set $res (call $call_method (local.get $obj) (string.const "sum")))

    ;; Convert result to i32 to return
    (i31.get_s (ref.cast i31ref (local.get $res)))
  )

  (export "main" (func $main))

  (elem declare func $get_x $sum_x_y)
)
