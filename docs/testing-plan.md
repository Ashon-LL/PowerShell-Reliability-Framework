# PRF Testing & Evaluation Plan (v0.1)

> Answers one question: **what evidence proves that an agent loaded with PRF
> produces more reliable PowerShell?**
>
> This plan also closes two review findings: the undefined benchmark scoring
> mechanism (review P1-5) and the non-operational §14 success metrics.

## 0. Claims under test → test layer

| ID | Claim | Layer |
|---|---|---|
| T0 | Package integrity: parses, counts match, examples pair 1:1 | L0 |
| T1 | Rule detectors are consistent with their own bad/good snippets | L1 |
| T2 | **Loading the skill raises benchmark scores and eliminates dangerous constructs** (core claim) | L2 |
| T3 | Good samples pass real-world parsing and static analysis | L3 |
| T4 | Rule changes do not introduce regressions | L4 |

## 1. Test pyramid

| Layer | Verifies | Tooling | Environment | Cost | Status |
|---|---|---|---|---|---|
| **L0** package integrity | schema / counts / pairing / detection shape | `tools/validate.py` | any (pyyaml) | seconds | ✅ built, run on every commit |
| **L1** rule consistency | detectors vs own snippets | `tools/rule-selftest.py` | any | seconds | ✅ built (28 patterns: 13 precise / 15 contextual / 0 fail) |
| **L2** skill effectiveness A/B | quality delta with vs without PRF | benchmark runner (to build) | ≥3 LLM/agent APIs | ~720 calls per round | ⬜ protocol in §2 |
| **L3** real-environment static gate | good samples parse + pass PSSA; probe smoke | pwsh + PSScriptAnalyzer | pwsh on Linux suffices; CI adds Windows 5.1 | half day setup | ✅ first run passed (pwsh 7.6 + PSSA 1.25: good=0 errors, bad=10/10 detected) |
| **L4** regression guard | changes trigger full re-test | GitHub Actions gates | CI | low | ⬜ wire L0/L1 first |

## 2. L2 — core A/B evaluation protocol

### 2.1 Design (two-arm controlled)

```text
subjects (≥3 models) × arms (treatment = SKILL.md + rules injected / control) × cases (100) × repeats k=3
```

- **Controlled variables**: pinned model snapshot ID, fixed temperature, identical
  system-prompt skeleton; the *only* difference between arms is PRF material.
- **Why repeats**: LLM output variance is high; k=3 is the floor for separating
  real effect from noise.
- **Artifacts**: `runs/<date>/<agent>/<arm>/<case-id>/answer.ps1 + meta.json`.
  Keep every transcript and publish them with results — reproducibility is the
  benchmark's lifeline.

### 2.2 Two-layer grading (deterministic first, model second)

**Layer 1 — deterministic (code-graded, cannot be sweet-talked):**
1. `negative_checks`: regex list scanned against `answer.ps1`; any hit caps that
   case's score at 0.49;
2. required-behavior subset: e.g. class-D cases must contain `-WhatIf`,
   idempotency cases must contain an existence guard — keyword-level checks.

**Layer 2 — blind LLM-as-judge:**
- judge scores each rubric criterion from `cases.json` (earned weight sums),
  **never seeing the arm label**;
- judge model pinned to one version, temperature 0;
- QA: ≥20% random sample double-reviewed by humans; if judge–human agreement
  < 80%, the round is voided and re-graded.

### 2.3 Statistics & pass thresholds (pre-registered — no post-hoc goalpost moving)

```text
case_score = earned_weight / max_weight      (negative_check hit ⇒ cap at 0.49)
Δ          = mean(score|treatment) − mean(score|control)
CI         : bootstrap(resamples=10000), 95%
```

Pre-registered thresholds, written into the runner config before the first run:
- **Effective**: Δ ≥ +0.15 AND lower CI bound > 0 AND critical-class negative_check
  hits drop to 0;
- **Per-category reporting**: SEC/SAFE improvement must hold on its own (safety
  gains must not be diluted into a blended average).

### 2.4 Operationalizing the original §14 metrics

| Original metric (unmeasurable) | Operationalized replacement (T2 output) |
|---|---|
| Generated Script Failure Reduction 50% | Δ(benchmark score) ≥ +0.15, lower CI bound > 0 |
| Security Issue Detection 80%+ | SEC-case negative_check hit rate down ≥80% vs control arm |
| Benchmark Cases 100 | case count itself (currently 20 pilot) |
| Agent Support 3+ | number of subjects completing the A/B |
| Rules 100+ | corpus size (done; guarded by the L0 gate) |

## 3. L3 — real-environment verification (no Windows box needed to start)

PowerShell 7 is cross-platform: install pwsh on Linux and PSScriptAnalyzer runs natively.
- every `examples/good/*.ps1` must parse cleanly and produce zero Error-severity
  PSScriptAnalyzer diagnostics;
- `tools/probe-environment.ps1` must parse and its `-AsJson` path must emit valid JSON;
- CI matrix: `ubuntu-latest` (pwsh 7.x) + `windows-latest` (adds Windows PowerShell 5.1);
- **hard rule: `bad/*.ps1` are never executed** — text comparison only.

## 4. Rollout order & cost

| Phase | Work | Prerequisite | Estimate |
|---|---|---|---|
| this week | wire L0/L1 into CI; first L3 run on Linux pwsh | none | 0.5 day |
| next | benchmark runner (prompt templates + deterministic grader + runs archive) | none | 1–2 days |
| then | first two-arm round (3 subjects × 2 arms × 100 cases × 3 repeats ≈ 1,800 generations + 1,800 gradings) | ≥1 model API key | moderate token cost |
| pre-release | calibrate thresholds from round 1 → fill README metrics → tag alpha | one completed L2 round | — |

## 5. Current status

- ✅ L0: `validate.py` enforces uniform detection mappings, a verified
  PSScriptAnalyzer-id allowlist, compilable patterns, cross-file reference
  integrity, and CJK-free agent-facing files;
- ✅ L1: first run caught a real defect (IDEM-011 word-boundary missed the
  `…RecordA` variant family) — fixed; 19 detection fields normalized; 1 fabricated
  PSA id removed;
- ✅ benchmark expanded 20 → 100 cases (2026-08-23)
- ✅ L3: all 21 `.ps1` files parse clean under PS 7.6; static gate passes with
  perfect discrimination (good = 0 errors, bad = 10/10 flagged);
- ⬜ L2/L4 proceed per §4; runner code lands once an external API key exists.

> Bottom line: **L0/L1 prove the package is sound today; L2 is what will prove the
> package works; L3 proved the samples are real. Until L2 completes, the public
> claim stays "alpha".**
