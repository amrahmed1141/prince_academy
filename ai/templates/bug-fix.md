# Pack: Bug Fix

Extends [`_base.md`](_base.md).

**Status:** active  
**Prompt:** [`../prompts/bug-fix.md`](../prompts/bug-fix.md)  
**Workflow:** [`../workflows/bug-fix.md`](../workflows/bug-fix.md)  
**Urgent variant:** [`../workflows/hot-fix.md`](../workflows/hot-fix.md)

## Intent

Restore correct behaviour with the smallest safe change, backed by a clear root cause and regression evidence.

## When to use / when not

**Use when** behaviour is wrong relative to an agreed expectation and can be reproduced.

**Do not use when** the request is a new capability (Feature), a pure schema change (SQL Change), or speculative cleanup.

**Hot Fix:** same pack, abbreviated documentation and optional review depth when production impact is high and the change is tightly scoped.

## Primary roles

| Role | Responsibility |
|------|----------------|
| Implementer | Reproduce, isolate, fix in the owning layer |
| Database | Own fix when root cause is SQL/RPC/policy |
| Reviewer | Diff compliance (may be abbreviated on Hot Fix) |
| QA | Confirm repro no longer fails; spot regressions |
| Documentation | Only if published behaviour or context was wrong |

## Required inputs

- Expected vs actual behaviour
- Reproduction steps (or reliable signal: log, screenshot, failing test)
- Environment notes (app version, role, platform) when relevant
- Suspect area if known (UI / domain / data / cache / SQL) — optional

## Required context

- Domain context for the affected area
- Data/API context if persistence or policies are involved
- Known pitfalls / memory notes if they exist for this area

## Stages

1. **Reproduce** — confirm failure; capture evidence  
2. **Isolate** — identify owning layer and root cause (cite source)  
3. **Fix** — minimal change; no opportunistic cleanups  
4. **Regress** — re-run repro; check adjacent paths (cache, sync, auth) when implicated  
5. **Review** — Review pack (full or abbreviated)  
6. **Document** — only if user-facing docs or agent context were incorrect  

**Hot Fix stages:** 1–4 required; 5 abbreviated; 6 deferred with an explicit follow-up note.

## Output schema

```text
## Bug fix report
- Summary:
- Repro:
- Root cause (file / query / contract):
- Fix summary:
- Regression evidence:
- Follow-ups deferred:
- Residual risk:
```

## Constraints

- Fix stays in the owning layer (do not “also” rewrite adjacent modules).
- Do not change public contracts unless required to correct the bug; call out contract changes explicitly.
- Do not invent product behaviour to justify a fix.

## Gates

| Gate | Fail if |
|------|---------|
| Repro confirmed | Cannot demonstrate the failure (unless approved theoretical fix with strong evidence) |
| Root cause named | Only symptoms addressed |
| Minimal diff | Unrelated refactors present |
| Regression | Original repro still fails |

## Stop / escalate

- Stop if unreproducible and no reliable signal exists — ask for more input.
- Escalate to Database/Security for privileged SQL or auth boundary bugs.
- Escalate to Architect if the “fix” implies a new architectural pattern.

## Definition of done

- [ ] Root cause documented
- [ ] Repro passes after fix
- [ ] Diff limited to the fix (and necessary tests/docs)
- [ ] Hot Fix follow-ups filed when review/docs were deferred

## Index updates

Usually none. Update context/memory only when a durable lesson or corrected rule is recorded.
