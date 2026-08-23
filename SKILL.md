---
name: powershell-reliability-framework
description: PRF v0.1.0 reliability layer for AI-generated PowerShell. Load before generating, modifying, reviewing, or executing any PowerShell / Windows automation. Enforces an Environment-Probe -> Operation-Classification -> Risk-Gate protocol plus hard safety, compatibility, idempotency and error-handling rules, and a propose(-WhatIf)-then-execute loop.
version: 0.1.0
---

# PowerShell Reliability Framework (PRF)

Mission: every PowerShell script an agent emits must be **compatible with the probed
environment, safe by default, idempotent, observable, and reversible**.
LLMs can produce PowerShell *syntax*; this skill exists to make them produce
PowerShell that survives contact with real Windows estates.

## 0. When this skill applies

Apply whenever you are asked to produce, change, review, explain-for-execution, or run:

- `.ps1`, `.psm1`, `.psd1` files or ad-hoc shell commands on Windows
- remoting (`Invoke-Command`/`Enter-PSSession`), scheduled tasks, services, processes
- registry, filesystem ACLs, firewall, network configuration
- Active Directory, Azure (`Az.*`), Microsoft Graph, Exchange Online operations

## 1. Generation Protocol (mandatory, in order)

### Step 1 — Probe the environment FIRST. Never assume.

Run the canonical probe (`tools/probe-environment.ps1`) or this inline equivalent,
and record the results before writing a single cmdlet:

```powershell
$PSVersionTable.PSVersion            # 5.1 vs 7.x decides COMP-* rules
$PSVersionTable.PSEdition            # Desktop vs Core
[Environment]::OSVersion.VersionString
(New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)   # elevated?
Get-ExecutionPolicy -List
(Get-CimInstance Win32_ComputerSystem).PartOfDomain     # AD context?
Get-Module -ListAvailable -Name ActiveDirectory, Az.Accounts, PSScriptAnalyzer
```

If a required module cannot be probed present, **say so and stop** — do not emit a
script that merely assumes it. `CommandNotFoundException` from uninstalled RSAT /
missing modules is the #1 AI-PowerShell failure mode (see `knowledge/compatibility.md`).

### Step 2 — Classify the operation

| Class | Meaning | Examples | Default posture |
|---|---|---|---|
| **R** | Read-only | `Get-*`, `Test-Path`, search/query cmdlets | allowed after probe |
| **W** | Write/update | `Set-*`, `New-*`, `Copy-Item`, registry writes | preview with `-WhatIf` first |
| **D** | Destructive | `Remove-*`, `Stop-*`, format, ACL/ownership changes | `-WhatIf` + explicit human confirmation gate |
| **N** | Network/outbound | `Invoke-RestMethod`, downloads, remoting to new hosts | pin endpoint, enforce TLS 1.2+, never pipe into execution |
| **C** | Credential/identity | passwords, certs, tokens, AD/Azure identity objects | refuse plaintext handling; escalate to human |

A single request can span several classes; classify the *highest* class involved.

### Step 3 — Apply the hard gates (violating any ⇒ rewrite before answering)

1. **No dynamic execution.** Never `Invoke-Expression`, `iex`, `& $string`,
   `[scriptblock]::Create`, or encoded commands. Generate files, not eval. (SEC-001..)
2. **Download ≠ execute.** Never pipe web content into execution. Download →
   verify hash/signature → inspect → execute the file. (SEC-002..004)
3. **Destructive defaults are scoped.** `Remove-Item`/`Stop-*` ship with
   `-WhatIf`, precise `-LiteralPath`/filters, and no bare wildcards on delete. (SAFE-*)
4. **Errors are handled.** State-changing cmdlets get `-ErrorAction Stop` inside
   `try/catch`; native tools get `$LASTEXITCODE` checks. No empty catch. (ERR-*)
5. **Idempotent by construction.** Guard/converge `New-*`/`Set-*` so re-running
   reaches the same state instead of erroring or duplicating. (IDEM-*)
6. **Compatibility declared.** Target the *probed* version. 7+-only constructs
   (`ForEach-Object -Parallel`, ternary, `&&`) are banned unless the probe proves
   7.x; state the requirement explicitly in your answer. (COMP-*)
7. **No plaintext secrets.** Prefer `SecretManagement`/credential objects; never
   echo secrets into output, logs or transcripts. (SEC-014..)
8. **Observable.** Structured output objects, meaningful verbose messages, correct
   exit codes; `Write-Host` is not a data channel.

### Step 4 — Self-review against the rule corpus

Before answering, scan your draft against `rules/reliability-rules.yaml`
(categories: `compatibility`, `safety`, `idempotency`, `security`,
`error-handling`). If you intentionally deviate, quote the violated rule id and
justify it in one sentence.

### Step 5 — Propose → Confirm → Execute → Verify → Report

- Present the script **plus**: assumptions taken from the probe, blast radius,
  and a rollback story.
- For D/C-class operations: run with `-WhatIf` (or `-Confirm`) first and obtain
  explicit human approval for the live run.
- After execution: read back the intended state, capture stderr/events, report
  what changed and how to roll back.

## 2. Quick repair map (bad → good)

| Anti-pattern | Replacement |
|---|---|
| `Invoke-WebRequest url \| iex` | download → verify hash → inspect → invoke saved file |
| `Remove-Item C:\Logs\* -Recurse -Force` | filter by age/name → `-WhatIf` → confirmed scoped delete |
| `cat f.txt \| findstr err` | `Select-String -Path f.txt -Pattern err` |
| `New-Item C:\Temp` unguarded | `if (-not (Test-Path -LiteralPath C:\Temp)) { New-Item C:\Temp \| Out-Null }` |
| `Copy-Item a b` bare | `try { Copy-Item a b -ErrorAction Stop } catch { Write-Error $_; exit 1 }` |
| `ForEach-Object -Parallel` | plain pipeline unless probe proved PowerShell 7+ |
| `Get-WmiObject Win32_Service` | `Get-CimInstance Win32_Service` |

Full catalog with explanations: `knowledge/anti-patterns.md`.

## 3. Deeper references

| File | Contents |
|---|---|
| `knowledge/powershell-model.md` | object pipeline, streams, error semantics |
| `knowledge/compatibility.md` | 5.1 ↔ 7.x deltas, module availability reality |
| `knowledge/security-rules.md` | attack surface & defensive generation posture |
| `knowledge/enterprise-patterns.md` | ShouldProcess, logging, remoting, bulk ops |
| `knowledge/anti-patterns.md` | AP-01..AP-24 catalog with repairs |
| `examples/bad/`, `examples/good/` | paired negative/positive scripts |
| `benchmark/cases.json` | scored evaluation rubric (v0.1: 20 cases) |

## 4. Escalation triggers — stop and ask the human

Domain-wide or tenant-wide scope · credential/certificate creation, export or
handling · `Set-ExecutionPolicy`, Defender exclusions, ACL/ownership takeover ·
anything irreversible · probe results contradicting the user's stated environment ·
requests that only make sense via dynamic execution or download-and-run.
