(module
  (import "wasi_snapshot_preview1" "fd_read" (func $fd_read (param i32 i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 512)
  (data (i32.const 128) "null\n")
  (global $IN i32 (i32.const 1048576))
  (global $OUT i32 (i32.const 17825792))
  (global $o (mut i32) (i32.const 17825792))

  (func $read_all (result i32) (local $n i32)
    (loop $l
      (i32.store (i32.const 0) (i32.add (global.get $IN) (local.get $n)))
      (i32.store (i32.const 4) (i32.sub (i32.const 16777216) (local.get $n)))
      (i32.store (i32.const 8) (i32.const 0))
      (drop (call $fd_read (i32.const 0) (i32.const 0) (i32.const 1) (i32.const 8)))
      (if (i32.gt_s (i32.load (i32.const 8)) (i32.const 0))
        (then (local.set $n (i32.add (local.get $n) (i32.load (i32.const 8)))) (br $l))))
    (local.get $n))
  (func $write_all (param $p i32) (param $len i32)
    (loop $l
      (if (i32.gt_s (local.get $len) (i32.const 0)) (then
        (i32.store (i32.const 16) (local.get $p))
        (i32.store (i32.const 20) (local.get $len))
        (i32.store (i32.const 24) (i32.const 0))
        (drop (call $fd_write (i32.const 1) (i32.const 16) (i32.const 1) (i32.const 24)))
        (if (i32.le_s (i32.load (i32.const 24)) (i32.const 0)) (then (return)))
        (local.set $p (i32.add (local.get $p) (i32.load (i32.const 24))))
        (local.set $len (i32.sub (local.get $len) (i32.load (i32.const 24))))
        (br $l)))))
  (func $at (param $i i32) (result i32) (i32.load8_u (i32.add (global.get $IN) (local.get $i))))
  (func $put (param $b i32)
    (i32.store8 (global.get $o) (local.get $b))
    (global.set $o (i32.add (global.get $o) (i32.const 1))))
  (func $hex (param $c i32) (result i32)
    (if (result i32) (i32.le_u (local.get $c) (i32.const 57))
      (then (i32.sub (local.get $c) (i32.const 48)))
      (else (i32.sub (i32.or (local.get $c) (i32.const 32)) (i32.const 87)))))

  (func (export "_start")
    (local $n i32) (local $i i32) (local $c i32) (local $klen i32) (local $ks i32) (local $kl i32)
    (local $match i32) (local $j i32) (local $vs i32)
    (local.set $n (call $read_all))
    (block $f (loop $l
      (br_if $f (i32.ge_u (local.get $i) (local.get $n)))
      (br_if $f (i32.eq (call $at (local.get $i)) (i32.const 10)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l)))
    (local.set $klen (local.get $i))
    (block $f (loop $l
      (br_if $f (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $c (call $at (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $l (i32.ne (local.get $c) (i32.const 123)))))
    (block $notfound (loop $obj
      (br_if $notfound (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $c (call $at (local.get $i)))
      (br_if $notfound (i32.eq (local.get $c) (i32.const 125)))
      (if (i32.ne (local.get $c) (i32.const 34)) (then
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $obj)))
      ;; key string
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (local.set $ks (local.get $i))
      (block $e (loop $k
        (br_if $e (i32.eq (call $at (local.get $i)) (i32.const 34)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $k)))
      (local.set $kl (i32.sub (local.get $i) (local.get $ks)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (local.set $match (i32.const 0))
      (if (i32.eq (local.get $kl) (local.get $klen)) (then
        (local.set $match (i32.const 1))
        (local.set $j (i32.const 0))
        (block $e (loop $cmp
          (br_if $e (i32.ge_u (local.get $j) (local.get $klen)))
          (if (i32.ne (call $at (local.get $j)) (call $at (i32.add (local.get $ks) (local.get $j))))
            (then (local.set $match (i32.const 0)) (br $e)))
          (local.set $j (i32.add (local.get $j) (i32.const 1)))
          (br $cmp)))))
      ;; skip to value start
      (block $e (loop $s
        (local.set $c (call $at (local.get $i)))
        (br_if $e (i32.eq (local.get $c) (i32.const 34)))
        (br_if $e (i32.eq (local.get $c) (i32.const 45)))
        (br_if $e (i32.le_u (i32.sub (local.get $c) (i32.const 48)) (i32.const 9)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $s)))
      (global.set $o (global.get $OUT))
      (if (i32.eq (local.get $c) (i32.const 34))
        (then
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (block $e (loop $str
            (local.set $c (call $at (local.get $i)))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br_if $e (i32.eq (local.get $c) (i32.const 34)))
            (if (i32.eq (local.get $c) (i32.const 92)) (then
              (local.set $c (call $at (local.get $i)))
              (local.set $i (i32.add (local.get $i) (i32.const 1)))
              (if (i32.eq (local.get $c) (i32.const 110)) (then (local.set $c (i32.const 10))))
              (if (i32.eq (local.get $c) (i32.const 116)) (then (local.set $c (i32.const 9))))
              (if (i32.eq (local.get $c) (i32.const 117)) (then
                (local.set $c (i32.or (i32.or
                  (i32.shl (call $hex (call $at (local.get $i))) (i32.const 12))
                  (i32.shl (call $hex (call $at (i32.add (local.get $i) (i32.const 1)))) (i32.const 8)))
                  (i32.or
                  (i32.shl (call $hex (call $at (i32.add (local.get $i) (i32.const 2)))) (i32.const 4))
                  (call $hex (call $at (i32.add (local.get $i) (i32.const 3)))))))
                (local.set $i (i32.add (local.get $i) (i32.const 4)))))))
            (call $put (local.get $c))
            (br $str))))
        (else
          (local.set $vs (local.get $i))
          (block $e (loop $num
            (br_if $e (i32.ge_u (local.get $i) (local.get $n)))
            (local.set $c (call $at (local.get $i)))
            (br_if $e (i32.and (i32.ne (local.get $c) (i32.const 45))
                               (i32.gt_u (i32.sub (local.get $c) (i32.const 48)) (i32.const 9))))
            (call $put (local.get $c))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $num)))))
      (if (local.get $match) (then
        (call $put (i32.const 10))
        (call $write_all (global.get $OUT) (i32.sub (global.get $o) (global.get $OUT)))
        (return)))
      (br $obj)))
    (call $write_all (i32.const 128) (i32.const 5)))
)
