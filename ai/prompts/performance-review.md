# Performance Review

**Status:** active  
**Pack:** [`../templates/review.md`](../templates/review.md) (performance lens)  
**Companion:** [`code-review.md`](code-review.md)

## Intent

Review a diff for avoidable cost: redundant queries, broken caching/sync assumptions, and UI rebuild or work amplification — using the shared Review output schema.

## Required context packs

- Originating pack report
- Domain packs for list/dashboard or sync-heavy areas
- Performance standards if present
- Data platform notes for query patterns

## Required inputs

- Diff or change set
- Hot path description (screen, job, query) when known
- Whether cache-first or realtime behaviour is expected for the surface

## Output schema

Same as Code Review, with `Lens(es): performance`.

Focus findings on:

- Extra network or database round-trips
- Cache bypass or stampede risk on list/dashboard paths
- Unnecessary rebuilds or heavy work on the UI thread
- Missing pagination or unbounded reads where relevant

## Constraints

- Prefer measured or clearly reasoned claims over vague “might be slow”.
- Do not propose new caching stacks if the project already has one.
- Follow Review pack severity and verdict rules.

## Stop / escalate

- Escalate data-model changes that force full-table patterns to Database/Architect.
- Mark regressions on known hot paths as Blockers when user-facing latency is clearly harmed.
