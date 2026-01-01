(module
  ;; Define a base struct type Point2D
  ;; We declare it as (sub ...) to allow subtyping (it makes it non-final in some contexts, or explicitly allows subtypes)
  (type $Point2D (sub (struct (field $x (mut i32)) (field $y (mut i32)))))

  ;; Define a subtype Point3D that extends Point2D.
  ;; It must declare $Point2D as its supertype.
  ;; The fields must match the supertype's fields (prefix).
  (type $Point3D (sub $Point2D (struct (field $x (mut i32)) (field $y (mut i32)) (field $z (mut i32)))))

  ;; Function that accepts a Point2D and returns its X + Y
  (func $sum_2d (param $p (ref $Point2D)) (result i32)
    (i32.add
      (struct.get $Point2D $x (local.get $p))
      (struct.get $Point2D $y (local.get $p))
    )
  )

  (func $main (result i32)
    (local $p3d (ref $Point3D))

    ;; Create a Point3D
    (local.set $p3d
      (struct.new $Point3D
        (i32.const 10)
        (i32.const 20)
        (i32.const 30)
      )
    )

    ;; Call sum_2d with the Point3D.
    ;; With explicit (sub ...) declarations, this is valid.
    (call $sum_2d (local.get $p3d))
  )

  (export "main" (func $main))
)
