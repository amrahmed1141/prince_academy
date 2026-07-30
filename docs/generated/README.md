# Generated inventories

Machine-written catalogs only (RPC listings, table inventories, dependency reports, and similar). Treat this folder as **build output**.

## Consumers

Tooling and agents that need an exhaustive list. Humans use it when they need completeness, not narrative.

## Rules

1. **Do not hand-edit** files here to “fix” content. Change the generator or upstream source, then regenerate.
2. Every generated file must open with a header that names the **generator**, **source inputs**, and **generation timestamp**.
3. Generated content never outranks `supabase/*.sql` or `lib/` — if they disagree, fix the source and regenerate.
4. Do not put authored guides, ADRs, or product prose here.

## Index

| Artifact | Generator | Status |
|----------|-----------|--------|
| — | None checked in yet | — |

## Related

- Hand-authored database docs: [`../database/`](../database/)
- Rule: [`.cursor/rules/quality/generated-files.mdc`](../../.cursor/rules/quality/generated-files.mdc)
