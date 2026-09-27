#!/usr/bin/env python3
"""Build + test one or more (arm, task) cells. usage: run.py <arm> [task...] [--tag attemptN]
Records results/<arm>/<task>.<tag>.json. arms: c asm wat raw"""
import json, os, subprocess, sys, time, glob, re
D = os.path.dirname(os.path.abspath(__file__)); os.chdir(D)
TASKS = ["csvsum", "isqrt", "b64enc", "utf8", "sort", "jsonget", "lru", "wc", "crc32", "floordiv"]
EXT = dict(c="c", asm="s", wat="wat", raw="hex")

def sh(cmd, **kw): return subprocess.run(cmd, shell=True, capture_output=True, **kw)

SRC = os.environ.get("NOABS_SRC", "src"); RES = os.environ.get("NOABS_RES", "results")
def build(arm, task):
    src = f"{SRC}/{arm}/{task}.{EXT[arm]}"; os.makedirs("build", exist_ok=True)
    if not os.path.exists(src): return None, "missing source"
    b = f"build/{SRC.replace('/', '_')}-{arm}-{task}"
    if arm == "c": r = sh(f"gcc -O2 -o {b} {src}")
    elif arm == "asm": r = sh(f"as -o {b}.o {src} && ld -o {b} {b}.o")
    elif arm == "wat": r = sh(f"node wat2wasm.mjs {src} {b}.wasm"); b += ".wasm"
    elif arm == "raw":
        txt = re.sub(r"#[^\n]*", "", open(src).read()); hx = re.sub(r"\s", "", txt)
        try: open(b, "wb").write(bytes.fromhex(hx)); os.chmod(b, 0o755); r = None
        except ValueError as e: return None, f"hex: {e}"
    if r is not None and r.returncode: return None, (r.stderr or r.stdout).decode()[-1500:]
    return b, ""

def run(arm, b, inp):
    cmd = ["node", "run-wasm.mjs", b] if b.endswith(".wasm") else [f"./{b}"]
    t = time.perf_counter()
    try: p = subprocess.run(cmd, stdin=open(inp, "rb"), capture_output=True, timeout=20)
    except subprocess.TimeoutExpired: return None, 20.0, "timeout"
    return p, time.perf_counter() - t, ""

def cell(arm, task, tag):
    b, err = build(arm, task)
    res = dict(arm=arm, task=task, tag=tag, built=b is not None, build_err=err, passed=0, total=0, fails=[])
    ins = sorted(glob.glob(f"tests/{task}/*.in")); res["total"] = len(ins)
    if b:
        res["size"] = os.path.getsize(b)
        for i in ins:
            p, dt, e = run(arm, b, i); exp = open(i[:-3] + ".out", "rb").read()
            if p is not None and p.returncode == 0 and p.stdout == exp: res["passed"] += 1
            else:
                got = e or (p.stdout[:80] + b" rc=%d" % p.returncode).decode(errors="replace")
                res["fails"].append(f"{os.path.basename(i)}: exp {exp[:60]!r} got {got!r}")
        pf = f"perf/{task}.in"
        if os.path.exists(pf):
            ts = []
            for _ in range(3):
                p, dt, e = run(arm, b, pf); ok = p is not None and p.returncode == 0 and p.stdout == open(pf[:-3] + ".out", "rb").read()
                ts.append(dt if ok else None)
            res["perf_s"] = None if None in ts else round(min(ts), 4)
    os.makedirs(f"{RES}/{arm}", exist_ok=True)
    json.dump(res, open(f"{RES}/{arm}/{task}.{tag}.json", "w"), indent=1)
    return res

if __name__ == "__main__":
    a = sys.argv[1:]; tag = "a1"
    if "--tag" in a: i = a.index("--tag"); tag = a[i + 1]; del a[i:i + 2]
    arm, tasks = a[0], (a[1:] or TASKS)
    for t in tasks:
        r = cell(arm, t, tag)
        print(f"{arm:4} {t:9} {tag:4} built={r['built']!s:5} {r['passed']}/{r['total']} size={r.get('size')} perf={r.get('perf_s')}")
        if r["build_err"]: print("   BUILD:", r["build_err"][:600])
        for f in r["fails"][:3]: print("   FAIL", f)
