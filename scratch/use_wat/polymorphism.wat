(module
  ;; VTable for dynamic dispatch
  ;; We need a recursive definition because Shape refers to VTable and VTable refers to Shape (in the signature)
  (rec
    (type $VTable (struct
      (field $get_area (ref $get_area_sig))
    ))

    (type $get_area_sig (func (param (ref $Shape)) (result i32)))

    (type $Shape (sub (struct
      (field $vtable (ref $VTable))
    )))
  )

  ;; Concrete types
  (type $Rect (sub $Shape (struct
    (field $vtable (ref $VTable))
    (field $w i32)
    (field $h i32)
  )))

  (type $Circle (sub $Shape (struct
    (field $vtable (ref $VTable))
    (field $r i32)
  )))

  ;; Implementations
  ;; Explicitly declare they use $get_area_sig type
  (func $Rect_get_area (type $get_area_sig) (param $this (ref $Shape)) (result i32)
    (local $self (ref $Rect))
    (local.set $self (ref.cast (ref $Rect) (local.get $this)))
    (i32.mul
      (struct.get $Rect 1 (local.get $self))
      (struct.get $Rect 2 (local.get $self))
    )
  )

  (func $Circle_get_area (type $get_area_sig) (param $this (ref $Shape)) (result i32)
    (local $self (ref $Circle))
    (local.set $self (ref.cast (ref $Circle) (local.get $this)))
    ;; Area = 3 * r * r (approx PI = 3)
    (i32.mul
      (i32.const 3)
      (i32.mul
        (struct.get $Circle 1 (local.get $self))
        (struct.get $Circle 1 (local.get $self))
      )
    )
  )

  ;; Declare functions to be used in ref.func
  (elem declare func $Rect_get_area $Circle_get_area)

  ;; VTables
  (global $RectVTable (ref $VTable) (struct.new $VTable (ref.func $Rect_get_area)))
  (global $CircleVTable (ref $VTable) (struct.new $VTable (ref.func $Circle_get_area)))

  ;; Helper to call get_area on a Shape
  (func $call_area (param $s (ref $Shape)) (result i32)
    (call_ref $get_area_sig
      (local.get $s)
      (struct.get $VTable 0 (struct.get $Shape 0 (local.get $s)))
    )
  )

  (func $main (result i32)
    (local $r (ref $Rect))
    (local $c (ref $Circle))
    (local $sum i32)

    ;; Create Rect 10x20
    (local.set $r
      (struct.new $Rect
        (global.get $RectVTable)
        (i32.const 10)
        (i32.const 20)
      )
    )

    ;; Create Circle radius 5
    (local.set $c
      (struct.new $Circle
        (global.get $CircleVTable)
        (i32.const 5)
      )
    )

    ;; Sum areas: (10*20) + (3*5*5) = 200 + 75 = 275
    (local.set $sum
      (i32.add
        (call $call_area (local.get $r))
        (call $call_area (local.get $c))
      )
    )

    (local.get $sum)
  )

  (export "main" (func $main))
)
