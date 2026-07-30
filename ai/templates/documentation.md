# Pack: Documentation

Extends [`_base.md`](_base.md).

**Status:** active  
**Prompt:** [`../prompts/documentation.md`](../prompts/documentation.md)  
**Workflow:** prompt-led (use human doc skeletons under the project’s docs templates directory)

## Intent

Record verified behaviour, contracts, and decisions so humans and agents share the same truth — without inventing conventions to fill space.

## When to use / when not

**Use when** behaviour, schema, operations, or decisions changed; when a new durable page/context pack is needed; or when existing docs contradict sources.

**Do not use when** the task is implementation-only with no knowledge impact, or when the requester wants speculative architecture essays.

## Primary roles

| Role | Responsibility |
|------|----------------|
| Documentation | Artifact choice, accuracy, indexes |
| Implementer / Database | Provide source pointers and review factual claims |
| Architect | ADR content when a lasting decision is recorded |

## Required inputs

- What changed (or what question the page answers)
- Canonical sources (code paths, SQL, config, prior ADR)
- Audience: human docs vs agent context/memory vs both
- Desired artifact type if known: doc page / ADR / context pack / memory note

## Required context

- Existing docs in the same folder/topic
- Related agent context packs
- Project documentation standards and templates

## Stages

1. **Choose artifact** — doc page, ADR, context pack, or memory note  
2. **Collect sources** — list canonical paths; refuse to invent  
3. **Draft** — fill the appropriate skeleton; link instead of copy  
4. **Cross-link** — related docs, ADRs, examples, rules  
5. **Index** — update folder README / INDEX tables  
6. **Mark stale** — call out siblings that now contradict sources  

## Output schema

```text
## Documentation report
- Artifact type(s):
- Paths created/updated:
- Sources cited:
- Indexes updated:
- Verified vs TODO sections:
- Stale siblings noted:
```

## Constraints

- Source of truth wins over docs on conflict; update the doc.
- Prefer links to duplication.
- Docs-only tasks do not change application source unless explicitly requested.
- Do not hand-edit generated documentation trees.
- Leave unknowns as TODO; do not fabricate conventions.
- ADRs are append-only; supersede instead of rewriting accepted history.

## Gates

| Gate | Fail if |
|------|---------|
| Sources cited | Claims without a canonical reference |
| Template used | New page/ADR skips required front matter |
| Index updated | New page missing from folder index |
| Scope respected | Unrelated application code edited on a docs-only task |

## Stop / escalate

- Stop when sources are unavailable and the fact is material.
- Escalate to Architect for decision records that change platform rules.
- Escalate to Database when schema docs would otherwise guess.

## Definition of done

- [ ] Artifact matches cited sources
- [ ] Required metadata/front matter present
- [ ] Indexes updated
- [ ] TODOs explicitly marked (none silently filled)

## Index updates

Always update the owning folder’s README or INDEX when adding or renaming pages/packs.
