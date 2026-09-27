#!/usr/bin/env python3
import os, random, re, collections, sys
sys.set_int_max_str_digits(0)
R = random.Random(927002); D = os.path.dirname(os.path.abspath(__file__)); OUT = f"{D}/tests"; P = f"{D}/perf"
I64 = 2**63
def wordfreq(b):
    c = collections.Counter(w.lower() for w in re.findall(rb"[A-Za-z]+", b))
    return b"".join(b"%d %s\n" % (n, w) for w, n in sorted(c.items(), key=lambda kv: (-kv[1], kv[0]))[:10])
def bigmul(b):
    x, y = b.split(b"\n")[:2]; return b"%d\n" % (int(x) * int(y))
def tdiv(a, b): q = abs(a) // abs(b); return q if (a < 0) == (b < 0) else -q
def ev(t):
    if t[0] == "n": return t[1]
    if t[0] == "u": return -ev(t[1])
    a, b = ev(t[2]), ev(t[3])
    return {"+": a + b, "-": a - b, "*": a * b, "/": tdiv(a, b) if b else None}[t[1]]
PREC = {"+": 1, "-": 1, "*": 2, "/": 2}
def show(t, sp):
    s = lambda: " " if R.random() < sp else ""
    if t[0] == "n": return str(t[1])
    if t[0] == "u":
        c = show(t[1], sp); return "-" + s() + (f"({c})" if t[1][0] == "b" else c)
    op, l, r = t[1], t[2], t[3]; ls, rs = show(l, sp), show(r, sp)
    if l[0] == "b" and (PREC[l[1]] < PREC[op] or R.random() < 0.2): ls = f"({s()}{ls}{s()})"
    if r[0] == "b" and (PREC[r[1]] <= PREC[op] or R.random() < 0.2): rs = f"({s()}{rs}{s()})"
    return f"{ls}{s()}{op}{s()}{rs}"
def rtree(d):
    if d == 0 or R.random() < 0.25: return ("n", R.choice([0, 1, 2, 7, R.randrange(1000), R.randrange(10**6)]))
    if R.random() < 0.15: return ("u", rtree(d - 1))
    return ("b", R.choice("+-*/"), rtree(d - 1), rtree(d - 1))
def ok(t):
    try:
        if t[0] == "n": return True
        if t[0] == "u": return ok(t[1]) and abs(ev(t)) < I64
        v = ev(t); return ok(t[2]) and ok(t[3]) and v is not None and -I64 <= v < I64
    except TypeError: return False
def calc(b):
    return b"".join(b"%d\n" % ev(parse(l)) for l in b.decode().split("\n") if l.strip())
def parse(s):  # independent recursive-descent reader used only to cross-check the tree printer
    toks = re.findall(r"\d+|[-+*/()]", s); i = [0]
    def peek(): return toks[i[0]] if i[0] < len(toks) else None
    def take(): i[0] += 1; return toks[i[0] - 1]
    def prim():
        t = take()
        if t == "-": return ("u", prim())
        if t == "(": e = expr(); take(); return e
        return ("n", int(t))
    def term():
        e = prim()
        while peek() in ("*", "/"): op = take(); e = ("b", op, e, prim())
        return e
    def expr():
        e = term()
        while peek() in ("+", "-"): op = take(); e = ("b", op, e, term())
        return e
    return expr()
def calc_case(n, depth, sp):
    ls = []
    while len(ls) < n:
        t = rtree(depth)
        if not ok(t): continue
        s = show(t, sp); assert ev(parse(s)) == ev(t), (s, ev(t)); ls.append(s)
    return ("\n".join(ls) + "\n").encode()
def emit(task, f, cases):
    d = f"{OUT}/{task}"; os.makedirs(d, exist_ok=True)
    for i, c in enumerate(cases):
        c = c.encode() if isinstance(c, str) else c
        open(f"{d}/{i:02d}.in", "wb").write(c); open(f"{d}/{i:02d}.out", "wb").write(f(c))
words = [w.strip() for w in open("/usr/share/dict/words")] if os.path.exists("/usr/share/dict/words") else None
vocab = words[:3000] if words else ["".join(R.choice("abcdefghij") for _ in range(R.randrange(1, 9))) for _ in range(3000)]
def text(n): return " ".join(R.choice(vocab[:R.choice([5, 50, 3000])]) if R.random() < .9 else R.choice(["The", "THE", "the,", "x9y", "don't", "a--b"]) for _ in range(n)).encode()
emit("wordfreq", wordfreq, [b"", b"123 456 !!", b"Hello hello HELLO world", b"b a c b a b", b"zz yy xx ww vv uu tt ss rr qq pp oo",
     b"caf\xc3\xa9 caf\xc3\xa9 na\xefve", text(2000), text(50000), b"a" * 70000 + b" b a"])
def num(k): return "0" if k == 0 else str(R.randrange(1, 10)) + "".join(R.choice("0123456789") for _ in range(k - 1))
emit("bigmul", bigmul, ["0\n0\n", "0\n123\n", "1\n999\n", "12\n34\n", "99999999999999999999\n99999999999999999999\n",
     f"{num(3000)}\n{num(3000)}\n", f"{num(1)}\n{num(2999)}\n", f"{10**2999}\n{10**2999}\n", f"{num(500)}\n{num(37)}\n"])
emit("calc", calc, ["1+2\n", "2*3+4\n2+3*4\n(2+3)*4\n", "7/2\n-7/2\n7/-2\n-(7)/2\n", "--5\n- - 5\n-(-(5))\n",
     "10-4-3\n100/10/5\n2*(3-(4-5))\n", "9223372036854775807\n0-9223372036854775807-1\n", " ( 1 + 2 ) * ( 3 + 4 ) \n",
     calc_case(200, 4, 0.0), calc_case(200, 6, 0.3), calc_case(300, 8, 0.1)])
os.makedirs(P, exist_ok=True)
for k, f, v in [("wordfreq", wordfreq, text(600000)), ("bigmul", bigmul, f"{num(3000)}\n{num(3000)}\n".encode()),
                ("calc", calc, calc_case(5000, 8, 0.2))]:
    open(f"{P}/{k}.in", "wb").write(v); open(f"{P}/{k}.out", "wb").write(f(v))
print({t: len(os.listdir(f"{OUT}/{t}")) // 2 for t in ["wordfreq", "bigmul", "calc"]}, "dict" if words else "synthetic vocab")
