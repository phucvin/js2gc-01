(module
  ;; Types
  (type $Point2d (struct (field $x i32) (field $y i32)))
  (type $Entry (struct (field $key i32) (field $val (mut (ref $Point2d)))))
  (type $BucketArray (array (mut (ref null $Entry))))
  (type $Map (struct (field $buckets (mut (ref $BucketArray))) (field $size (mut i32))))

  ;; Helper: Hash function (simple modulo)
  (func $hash (param $key i32) (param $cap i32) (result i32)
    (i32.rem_u (local.get $key) (local.get $cap))
  )

  ;; Helper: Create Map
  (func $map_new (param $cap i32) (result (ref $Map))
    (struct.new $Map
      (array.new_default $BucketArray (local.get $cap))
      (i32.const 0)
    )
  )

  ;; Helper: Put
  (func $map_put (param $map (ref $Map)) (param $key i32) (param $val (ref $Point2d))
    (local $buckets (ref $BucketArray))
    (local $cap i32)
    (local $idx i32)
    (local $entry (ref null $Entry))

    (local.set $buckets (struct.get $Map $buckets (local.get $map)))
    (local.set $cap (array.len (local.get $buckets)))
    (local.set $idx (call $hash (local.get $key) (local.get $cap)))

    ;; Linear probe
    (loop $probe
      (local.set $entry (array.get $BucketArray (local.get $buckets) (local.get $idx)))

      ;; If empty slot found
      (if (ref.is_null (local.get $entry))
        (then
            ;; Insert new entry
            (array.set $BucketArray (local.get $buckets) (local.get $idx)
                (struct.new $Entry (local.get $key) (local.get $val))
            )
            ;; Increment size
            (struct.set $Map $size (local.get $map)
                (i32.add (struct.get $Map $size (local.get $map)) (i32.const 1))
            )
            (return)
        )
      )

      ;; If key matches
      (if (i32.eq (struct.get $Entry $key (local.get $entry)) (local.get $key))
        (then
            ;; Update value
            (struct.set $Entry $val (local.get $entry) (local.get $val))
            (return)
        )
      )

      ;; Move to next index
      (local.set $idx (i32.add (local.get $idx) (i32.const 1)))
      (if (i32.eq (local.get $idx) (local.get $cap))
        (then (local.set $idx (i32.const 0)))
      )

      ;; Continue probing (potentially infinite loop if full, but we won't fill it)
      (br $probe)
    )
  )

  ;; Main
  (func $main (result i32)
    (local $map (ref $Map))
    (local.set $map (call $map_new (i32.const 10)))

    ;; Put (1, (10, 20))
    (call $map_put (local.get $map) (i32.const 1) (struct.new $Point2d (i32.const 10) (i32.const 20)))

    ;; Put (2, (30, 40))
    (call $map_put (local.get $map) (i32.const 2) (struct.new $Point2d (i32.const 30) (i32.const 40)))

    ;; Update (1, (50, 60)) - Should not increase size
    (call $map_put (local.get $map) (i32.const 1) (struct.new $Point2d (i32.const 50) (i32.const 60)))

    ;; Return size (should be 2)
    (struct.get $Map $size (local.get $map))
  )

  (export "main" (func $main))
)
