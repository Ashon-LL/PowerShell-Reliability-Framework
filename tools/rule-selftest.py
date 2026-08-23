#!/usr/bin/env python3
"""PRF L1 rule-consistency self-test.

For every rule carrying a detection.pattern, verifies against the rule's OWN
bad/good snippets:
  OK      pattern matches bad, not good          -> precise token detector
  WARN    pattern matches both bad and good      -> contextual detector: the
          construct appears in the compliant fix too (expected for IDEM/SAFE
          guard-rules); real gating requires AST/context analysis (v0.2)
  FAIL    inverted (good-only) or dead (neither)

Also sweeps example pairs and reports detectors that fire nowhere.

Usage: python3 tools/rule-selftest.py   (exit 0 unless FAIL entries)
"""
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
rules = yaml.safe_load(
    (ROOT / "rules" / "reliability-rules.yaml").read_text(encoding="utf-8"))["rules"]

example_files = sorted((ROOT / "examples").rglob("*.ps1"))
example_texts = [(p.relative_to(ROOT).as_posix(), p.read_text(errors="ignore"))
                 for p in example_files]

ok, warn, fail = [], [], []
tested = 0
for r in rules:
    pat = (r.get("detection") or {}).get("pattern")
    if not pat:
        continue
    rid = r["id"]
    tested += 1
    rx = re.compile(pat)
    hit_bad = bool(rx.search(r.get("bad", "")))
    hit_good = bool(rx.search(r.get("good", "")))
    if hit_bad and not hit_good:
        ok.append(rid)
    elif hit_bad and hit_good:
        warn.append(f"{rid}: contextual detector - fires on both bad and good "
                    f"(needs context gate, see v0.2)")
    elif hit_good:
        fail.append(f"{rid}: INVERTED - fires only on the compliant snippet")
    else:
        fail.append(f"{rid}: DEAD - fires on neither snippet")

cold = []
for r in rules:
    pat = (r.get("detection") or {}).get("pattern")
    if not pat:
        continue
    rx = re.compile(pat)
    ex_hits = sum(1 for _, t in example_texts if rx.search(t))
    own_hits = bool(rx.search(r.get("bad", ""))) or bool(rx.search(r.get("good", "")))
    if ex_hits == 0 and not own_hits:
        cold.append(r["id"])

print(f"pattern-bearing rules tested : {tested}")
print(f"  precise  (bad only)        : {len(ok)}")
print(f"  contextual (both sides)    : {len(warn)}")
print(f"  FAIL                       : {len(fail)}")
print(f"cold detectors (no corpus/example hit): {len(cold)} {cold}")
if warn:
    print("\ncontextual detectors (WARN):")
    for w in warn:
        print("  ~", w)
if fail:
    print("\nFAILURES:")
    for f in fail:
        print("  x", f)
    sys.exit(1)
print("\nL1 SELF-TEST PASS")
