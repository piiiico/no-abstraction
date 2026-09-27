(module
  (import "wasi_snapshot_preview1" "fd_read" (func $fd_read (param i32 i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 2)

  (func (export "_start")
    (local $len i32) (local $i i32) (local $c i32) (local $n i64) (local $res i64) (local $bit i64) (local $t i64) (local $p i32)
    ;; read up to 200 bytes at 1024
    (loop $l
      (i32.store (i32.const 0) (i32.add (i32.const 1024) (local.get $len)))
      (i32.store (i32.const 4) (i32.sub (i32.const 200) (local.get $len)))
      (i32.store (i32.const 8) (i32.const 0))
      (drop (call $fd_read (i32.const 0) (i32.const 0) (i32.const 1) (i32.const 8)))
      (if (i32.gt_s (i32.load (i32.const 8)) (i32.const 0))
        (then (local.set $len (i32.add (local.get $len) (i32.load (i32.const 8)))) (br $l))))
    (block $e (loop $d
      (br_if $e (i32.ge_u (local.get $i) (local.get $len)))
      (local.set $c (i32.sub (i32.load8_u (i32.add (i32.const 1024) (local.get $i))) (i32.const 48)))
      (br_if $e (i32.gt_u (local.get $c) (i32.const 9)))
      (local.set $n (i64.add (i64.mul (local.get $n) (i64.const 10)) (i64.extend_i32_u (local.get $c))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $d)))
    (local.set $bit (i64.shl (i64.const 1) (i64.const 62)))
    (block $b (loop $l
      (br_if $b (i64.le_u (local.get $bit) (local.get $n)))
      (local.set $bit (i64.shr_u (local.get $bit) (i64.const 2)))
      (br_if $l (i64.ne (local.get $bit) (i64.const 0)))))
    (block $b2 (loop $l
      (br_if $b2 (i64.eqz (local.get $bit)))
      (local.set $t (i64.add (local.get $res) (local.get $bit)))
      (if (i64.ge_u (local.get $n) (local.get $t))
        (then
          (local.set $n (i64.sub (local.get $n) (local.get $t)))
          (local.set $res (i64.add (i64.shr_u (local.get $res) (i64.const 1)) (local.get $bit))))
        (else (local.set $res (i64.shr_u (local.get $res) (i64.const 1)))))
      (local.set $bit (i64.shr_u (local.get $bit) (i64.const 2)))
      (br $l)))
    ;; format into 2048.. backwards from 2100
    (local.set $p (i32.const 2100))
    (i32.store8 (local.get $p) (i32.const 10))
    (loop $d
      (local.set $p (i32.sub (local.get $p) (i32.const 1)))
      (i32.store8 (local.get $p) (i32.wrap_i64 (i64.add (i64.rem_u (local.get $res) (i64.const 10)) (i64.const 48))))
      (local.set $res (i64.div_u (local.get $res) (i64.const 10)))
      (br_if $d (i64.ne (local.get $res) (i64.const 0))))
    (i32.store (i32.const 16) (local.get $p))
    (i32.store (i32.const 20) (i32.sub (i32.const 2101) (local.get $p)))
    (drop (call $fd_write (i32.const 1) (i32.const 16) (i32.const 1) (i32.const 24))))
)
