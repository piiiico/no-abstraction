(module
  (import "wasi_snapshot_preview1" "fd_read" (func $fd_read (param i32 i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 4)
  (global $IN i32 (i32.const 65536))    ;; 64 KiB input
  (global $RES i32 (i32.const 131072))  ;; u64 columns (<= 6000 x 8)
  (global $OUT i32 (i32.const 196608))

  (func $at (param $i i32) (result i32) (i32.load8_u (i32.add (global.get $IN) (local.get $i))))
  (func $dig (param $i i32) (result i32) (i32.sub (call $at (local.get $i)) (i32.const 48)))
  (func (export "_start")
    (local $n i32) (local $la i32) (local $s2 i32) (local $lb i32) (local $i i32) (local $j i32) (local $xi i64)
    (local $p i32) (local $carry i64) (local $v i64) (local $cols i32) (local $o i32) (local $len i32)
    (loop $l
      (i32.store (i32.const 0) (i32.add (global.get $IN) (local.get $n)))
      (i32.store (i32.const 4) (i32.sub (i32.const 65536) (local.get $n)))
      (i32.store (i32.const 8) (i32.const 0))
      (drop (call $fd_read (i32.const 0) (i32.const 0) (i32.const 1) (i32.const 8)))
      (if (i32.gt_s (i32.load (i32.const 8)) (i32.const 0))
        (then (local.set $n (i32.add (local.get $n) (i32.load (i32.const 8)))) (br $l))))
    (block $e (loop $l
      (br_if $e (i32.gt_u (call $dig (local.get $la)) (i32.const 9)))
      (local.set $la (i32.add (local.get $la) (i32.const 1)))
      (br $l)))
    (local.set $s2 (i32.add (local.get $la) (i32.const 1)))
    (block $e (loop $l
      (br_if $e (i32.ge_u (i32.add (local.get $s2) (local.get $lb)) (local.get $n)))
      (br_if $e (i32.gt_u (call $dig (i32.add (local.get $s2) (local.get $lb))) (i32.const 9)))
      (local.set $lb (i32.add (local.get $lb) (i32.const 1)))
      (br $l)))
    (block $ie (loop $il
      (br_if $ie (i32.ge_u (local.get $i) (local.get $la)))
      (local.set $xi (i64.extend_i32_u (call $dig (i32.sub (i32.sub (local.get $la) (i32.const 1)) (local.get $i)))))
      (if (i64.ne (local.get $xi) (i64.const 0)) (then
        (local.set $j (i32.const 0))
        (block $je (loop $jl
          (br_if $je (i32.ge_u (local.get $j) (local.get $lb)))
          (local.set $p (i32.add (global.get $RES) (i32.shl (i32.add (local.get $i) (local.get $j)) (i32.const 3))))
          (i64.store (local.get $p) (i64.add (i64.load (local.get $p))
            (i64.mul (local.get $xi) (i64.extend_i32_u
              (call $dig (i32.sub (i32.add (local.get $s2) (i32.sub (local.get $lb) (i32.const 1))) (local.get $j)))))))
          (local.set $j (i32.add (local.get $j) (i32.const 1)))
          (br $jl)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $il)))
    (local.set $cols (i32.add (local.get $la) (local.get $lb)))
    (local.set $i (i32.const 0))
    (block $e (loop $l
      (br_if $e (i32.ge_u (local.get $i) (local.get $cols)))
      (local.set $p (i32.add (global.get $RES) (i32.shl (local.get $i) (i32.const 3))))
      (local.set $v (i64.add (i64.load (local.get $p)) (local.get $carry)))
      (i64.store (local.get $p) (i64.rem_u (local.get $v) (i64.const 10)))
      (local.set $carry (i64.div_u (local.get $v) (i64.const 10)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l)))
    (local.set $i (i32.sub (local.get $cols) (i32.const 1)))
    (block $e (loop $l
      (br_if $e (i32.le_s (local.get $i) (i32.const 0)))
      (br_if $e (i64.ne (i64.load (i32.add (global.get $RES) (i32.shl (local.get $i) (i32.const 3)))) (i64.const 0)))
      (local.set $i (i32.sub (local.get $i) (i32.const 1)))
      (br $l)))
    (local.set $o (global.get $OUT))
    (loop $l
      (i32.store8 (local.get $o) (i32.add (i32.wrap_i64 (i64.load (i32.add (global.get $RES) (i32.shl (local.get $i) (i32.const 3))))) (i32.const 48)))
      (local.set $o (i32.add (local.get $o) (i32.const 1)))
      (local.set $i (i32.sub (local.get $i) (i32.const 1)))
      (br_if $l (i32.ge_s (local.get $i) (i32.const 0))))
    (i32.store8 (local.get $o) (i32.const 10))
    (local.set $len (i32.sub (i32.add (local.get $o) (i32.const 1)) (global.get $OUT)))
    (local.set $o (global.get $OUT))
    (loop $w
      (if (i32.gt_s (local.get $len) (i32.const 0)) (then
        (i32.store (i32.const 16) (local.get $o))
        (i32.store (i32.const 20) (local.get $len))
        (i32.store (i32.const 24) (i32.const 0))
        (drop (call $fd_write (i32.const 1) (i32.const 16) (i32.const 1) (i32.const 24)))
        (if (i32.gt_s (i32.load (i32.const 24)) (i32.const 0)) (then
          (local.set $o (i32.add (local.get $o) (i32.load (i32.const 24))))
          (local.set $len (i32.sub (local.get $len) (i32.load (i32.const 24))))
          (br $w)))))))
)
