#!/usr/bin/env python3
"""Evaluate every generated file in src-<model>-g<k>/ dirs. Prints per-arm pass counts per generation."""
import glob, os, subprocess, json, collections, re, sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))
EXT = {"c": "c", "asm": "s", "wat": "wat"}
out = collections.defaultdict(dict)
for d in sorted(glob.glob("src-*-g*")):
    for arm in EXT:
        for f in sorted(glob.glob(f"{d}/{arm}/*.{EXT[arm]}")):
            task = os.path.basename(f).rsplit(".", 1)[0]
            res = f"results-{d[4:]}/{arm}/{task}.a1.json"
            if not os.path.exists(res):
                subprocess.run(["python3", "run.py", arm, task, "--tag", "a1"], env={**os.environ, "NOABS_SRC": d, "NOABS_RES": f"results-{d[4:]}"}, capture_output=True)
            j = json.load(open(res)); u = json.load(open(f + ".usage.json")) if os.path.exists(f + ".usage.json") else {}
            out[(d, arm)][task] = (j["passed"] == j["total"] and j["total"] > 0, j["built"], u.get("completion_tokens"))
for (d, arm), tasks in sorted(out.items()):
    ok = sum(v[0] for v in tasks.values()); built = sum(v[1] for v in tasks.values())
    toks = [v[2] for v in tasks.values() if v[2]]
    print(f"{d:42} {arm:4} pass {ok}/{len(tasks)} built {built}/{len(tasks)} median_tokens {sorted(toks)[len(toks)//2] if toks else '-'}  fails: {[t for t,v in tasks.items() if not v[0]]}")
