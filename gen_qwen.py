#!/usr/bin/env python3
"""One-shot generations from the Hetzner Qwen rail. usage: gen_qwen.py <model> <gens> <arm>..."""
import json, os, re, sys, time, urllib.request, concurrent.futures as cf
D = os.path.dirname(os.path.abspath(__file__)); os.chdir(D)
env = dict(l.strip().split("=", 1) for l in open("/workspace/.secrets/hetzner-inference.env") if "=" in l and not l.startswith("#"))
MODEL, GENS, ARMS = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
TASKS = ["csvsum", "isqrt", "b64enc", "utf8", "sort", "jsonget", "lru", "wc", "crc32", "floordiv"]
EXT = dict(c="c", asm="s", wat="wat")
SPEC = open("SPEC.md").read()
LANG = dict(
  c="C, compiled with `gcc -O2 prog.c` on aarch64 Linux.",
  asm="aarch64 Linux assembly in GNU `as` syntax, built with `as -o p.o prog.s && ld -o p p.o` — no libc, no C runtime; use raw Linux syscalls.",
  wat="WebAssembly text format (WAT), compiled with wabt's wat2wasm and run under WASI preview1 in node. The module must export `memory` and `_start` and may import fd_read/fd_write/proc_exit from `wasi_snapshot_preview1`.")
tag = re.sub(r"[^A-Za-z0-9]+", "_", MODEL)
def one(arm, task, g):
    out = f"src-{tag}-g{g}/{arm}/{task}.{EXT[arm]}"
    if os.path.exists(out): return out, "cached"
    prompt = (f"{SPEC}\n\nWrite the program `{task}` (number {TASKS.index(task)+1} above) in {LANG[arm]}\n"
              "It will be run against hidden tests. Reply with the complete program in ONE fenced code block.")
    body = json.dumps({"model": MODEL, "messages": [{"role": "user", "content": prompt}], "max_tokens": 24000}).encode()
    for attempt in range(4):
        try:
            req = urllib.request.Request(env["HETZNER_INFERENCE_BASE_URL"] + "/chat/completions", body,
                  {"Authorization": "Bearer " + env["HETZNER_INFERENCE_TOKEN"], "Content-Type": "application/json"})
            d = json.load(urllib.request.urlopen(req, timeout=1500)); break
        except Exception as e:
            err = str(e); time.sleep(30 * (attempt + 1))
    else: return out, "ERR " + err
    txt = d["choices"][0]["message"]["content"] or ""
    blocks = re.findall(r"```[^\n]*\n(.*?)```", txt, re.S)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, "w").write(max(blocks, key=len) if blocks else txt)
    json.dump(d.get("usage"), open(out + ".usage.json", "w"))
    return out, f"ok {d.get('usage',{}).get('completion_tokens')}"
jobs = [(a, t, g) for g in range(1, GENS + 1) for a in ARMS for t in TASKS]
with cf.ThreadPoolExecutor(8) as ex:
    for f in cf.as_completed([ex.submit(one, *j) for j in jobs]):
        print(time.strftime("%H:%M:%S"), *f.result(), flush=True)
