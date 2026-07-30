# README_AI

AI entry point for this repository.

## Load order

1. [`AGENTS.md`](AGENTS.md)
2. Active role under [`agents/`](agents/) (see [`agents/INDEX.md`](agents/INDEX.md))
3. Matching pack under [`ai/templates/`](ai/templates/)
4. Matching [`ai/workflows/`](ai/workflows/)
5. Matching [`ai/prompts/`](ai/prompts/)
6. Only needed [`ai/context/`](ai/context/) packs
7. [`examples/`](examples/) + gold-standard features
8. [`ai/memory/`](ai/memory/) if relevant

## Maps

| Area | Path |
|------|------|
| AI platform | [`ai/`](ai/) |
| Agents | [`agents/`](agents/) |
| Work-type templates | [`ai/templates/`](ai/templates/) |
| Prompts | [`ai/prompts/`](ai/prompts/) |
| Context packs | [`ai/context/`](ai/context/) |
| Workflows | [`ai/workflows/`](ai/workflows/) |
| Memory | [`ai/memory/`](ai/memory/) |
| Standards | [`ai/standards/`](ai/standards/) |
| Examples | [`examples/`](examples/) |
| Docs | [`docs/`](docs/) |
| Cursor rules | [`.cursor/rules/`](.cursor/rules/) |

## Notes

- Work-type packs: [`ai/templates/`](ai/templates/) (generic process; bind to project contract at runtime).
- Context packs: major domains only — see [`ai/context/INDEX.md`](ai/context/INDEX.md) (loading model + budget).
- Existing scoped rules under `.cursor/rules/*.mdc` remain active.
- New grouped stubs under `.cursor/rules/{core,flutter,data,quality,product}/` are inactive placeholders (`alwaysApply: false`).
