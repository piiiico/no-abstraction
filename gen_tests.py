#!/usr/bin/env python3
"""Tests FIRST: reference behaviour in Python (not an arm) -> tests/<task>/NN.in / NN.out. Seeded, reproducible."""
import base64, json, os, random, zlib, math, re

R = random.Random(20260927)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tests")

def emit(task, cases):
    d = os.path.join(OUT, task); os.makedirs(d, exist_ok=True)
    for i, inp in enumerate(cases):
        if isinstance(inp, str): inp = inp.encode()
        open(f"{d}/{i:02d}.in", "wb").write(inp)
        open(f"{d}/{i:02d}.out", "wb").write(REF[task](inp))

def csvsum(b):
    lines = b.decode().split("\n")[1:]
    return f"{sum(int(l.split(',')[1]) for l in lines if l != '')}\n".encode()
def isqrt(b): return f"{math.isqrt(int(b.decode().strip()))}\n".encode()
def b64enc(b): return base64.b64encode(b) + b"\n"
def utf8(b):
    try: b.decode("utf-8", errors="strict"); return b"valid\n"
    except UnicodeDecodeError: return b"invalid\n"
def sort_(b):
    xs = sorted(int(x) for x in b.split())
    return "".join(f"{x}\n" for x in xs).encode()
def jsonget(b):
    s = b.decode(); key, rest = s.split("\n", 1)
    pairs = json.loads(rest, object_pairs_hook=lambda p: p)
    for k, v in pairs:
        if k == key: return (f"{v}\n").encode()
    return b"null\n"
def lru(b):
    lines = b.decode().split("\n"); cap = int(lines[0]); from collections import OrderedDict
    c = OrderedDict(); out = []
    for l in lines[1:]:
        if not l: continue
        p = l.split()
        if p[0] == "get":
            k = int(p[1])
            if k in c: c.move_to_end(k); out.append(str(c[k]))
            else: out.append("-1")
        else:
            k, v = int(p[1]), int(p[2])
            if k in c: c[k] = v; c.move_to_end(k)
            else:
                if len(c) >= cap: c.popitem(last=False)
                c[k] = v
    return "".join(x + "\n" for x in out).encode()
def wc(b):
    ws = set(b" \t\n\r\v\f"); w = 0; inw = False
    for ch in b:
        if ch in ws: inw = False
        elif not inw: inw = True; w += 1
    return f"{b.count(10)} {w} {len(b)}\n".encode()
def crc32(b): return f"{zlib.crc32(b) & 0xffffffff:08x}\n".encode()
def floordiv(b):
    out = []
    for l in b.decode().split("\n"):
        if not l: continue
        a, c = map(int, l.split(" "))
        if c == 0: out.append("div0")
        elif a == -2**63 and c == -1: out.append("overflow")
        else: out.append(f"{a // c} {a - (a // c) * c}")
    return "".join(x + "\n" for x in out).encode()

REF = dict(csvsum=csvsum, isqrt=isqrt, b64enc=b64enc, utf8=utf8, sort=sort_, jsonget=jsonget, lru=lru, wc=wc,
           crc32=crc32, floordiv=floordiv)
I64 = 2**63

def rbytes(n): return bytes(R.randrange(256) for _ in range(n))

emit("csvsum", ["name,val\n", "h,v\na,1\nb,2\n", "h,v\nx,-5\ny,7", "h,v\n\na,10\n\nb,-3\n\n",
    "h,v,w\n,4,z\nq,-9223372036854775807,1\nr,1,2\n",
    "h,v\n" + "".join(f"r{i},{R.randrange(-10**9, 10**9)}\n" for i in range(5000)),
    "id,amount,note\n" + "".join(f"{i},{R.randrange(-10**12, 10**12)},n{i}\n" for i in range(300))])
emit("isqrt", ["0\n", "1\n", "2", "3\n", "4\n", "15\n", "16\n", "17\n", "99999999999999999\n", "18446744073709551615\n",
    "18446744065119617025\n", "18446744065119617024\n", "4294967296\n", "4294967295\n",
    f"{(2**32-1)**2 - 1}\n"] + [f"{R.randrange(2**64)}\n" for _ in range(10)])
emit("b64enc", [b"", b"f", b"fo", b"foo", b"foob", b"fooba", b"foobar", b"\x00\xff\xfe", rbytes(1000),
    rbytes(3 * 4096 + 1), rbytes(100001)])
emit("utf8", [b"", b"hello", "æøå €".encode(), "𝄞 ok".encode(), b"\xc0\xaf", b"\xe0\x80\xaf", b"\xed\xa0\x80",
    b"\xf4\x90\x80\x80", b"\xf4\x8f\xbf\xbf", b"\xef\xbf\xbf", b"\x80", b"abc\xe2\x82", b"\xc2", b"\xff",
    b"\xf8\x88\x80\x80\x80", b"\xc2\x80", b"\xdf\xbf", b"\xe0\xa0\x80", b"\xf0\x90\x80\x80", b"\xf0\x8f\xbf\xbf",
    b"\xed\x9f\xbf", b"\xee\x80\x80", b"\xe2\x28\xa1", "Grüße, 世界!".encode() * 500,
    ("x" * 5000).encode() + b"\xc3"])
emit("sort", ["", "5\n", "3 1 2\n", "  -1\t\n0   1\n\n", f"{-I64} {I64-1} 0 -1\n", "7 7 7 -7\n",
    " ".join(str(R.randrange(-I64, I64)) for _ in range(2000)) + "\n",
    "\n".join(str(R.randrange(-50, 50)) for _ in range(20000)),
    "\n".join(str(x) for x in range(3000, 0, -1)) + "\n"])
emit("jsonget", ['a\n{"a":1}', 'b\n{"a":1}', 'name\n{ "name" : "Bob" }\n',
    'x\n{"y": "has \\"x\\": 5 inside", "x": -42}',
    'k\n{"k":"line\\nbreak\\ttab \\\\ slash\\/ quote\\" \\u0041\\u007e"}',
    'dup\n{"dup":"first","dup":"second"}', 'v\n{\n\t"a" : "v",\r\n  "v" : 0\n}\n',
    'id\n{"idx": 1, "id": 9223372036854775807}', 'e\n{"e": ""}',
    'name\n{"title": "name", "other": "{\\"name\\": 1}", "name": "real"}'])
def lru_case(cap, n, keyspace):
    ls = [str(cap)]
    for _ in range(n):
        k = R.randrange(keyspace)
        ls.append(f"get {k}" if R.random() < 0.5 else f"put {k} {R.randrange(10**9 + 1)}")
    return "\n".join(ls) + "\n"
emit("lru", ["1\nput 1 1\nput 2 2\nget 1\nget 2\n", "2\nput 1 1\nput 2 2\nget 1\nput 3 3\nget 2\nget 3\nget 1\n",
    "2\nput 1 1\nput 1 5\nput 2 2\nput 3 3\nget 1\nget 2\nget 3\n", "3\nget 0\n", lru_case(10, 2000, 30),
    lru_case(1000, 100000, 3000), lru_case(1, 500, 3)])
emit("wc", [b"", b"a", b"\n", b"hello world\n", b"  lead\tand trail  ", b"a\r\nb\vc\fd\n\n", rbytes(5000),
    b"one two three\nfour\n" * 1000])
emit("crc32", [b"", b"123456789", b"a", b"\x00" * 32, b"\xff" * 7, rbytes(10000), rbytes(1 << 20)])
fl = ["7 2", "-7 2", "7 -2", "-7 -2", "0 5", "5 0", f"{-I64} -1", f"{-I64} 1", f"{I64-1} -1", f"{-I64} 2",
      f"{-I64} {-I64}", "1 -9223372036854775808", "-1 9223372036854775807"]
emit("floordiv", ["\n".join(fl) + "\n", "".join(f"{R.randrange(-I64, I64)} {R.randrange(-I64, I64)}\n" for _ in range(500)),
    "".join(f"{R.randrange(-100, 100)} {R.randrange(-10, 10)}\n" for _ in range(500))])

# perf inputs (timing only; correctness also checked)
P = os.path.join(os.path.dirname(os.path.abspath(__file__)), "perf"); os.makedirs(P, exist_ok=True)
big = rbytes(1 << 22)
perf = {"crc32": big, "wc": big, "b64enc": big[:1 << 20], "utf8": ("Grüße 世界 " * 300000).encode(),
        "sort": ("\n".join(str(R.randrange(-I64, I64)) for _ in range(200000)) + "\n").encode(),
        "lru": lru_case(1000, 100000, 2000).encode(),
        "csvsum": ("h,v\n" + "".join(f"r,{R.randrange(-10**9, 10**9)}\n" for _ in range(300000))).encode()}
for k, v in perf.items():
    open(f"{P}/{k}.in", "wb").write(v); open(f"{P}/{k}.out", "wb").write(REF[k](v))
print({t: len(os.listdir(os.path.join(OUT, t))) // 2 for t in REF})
