# Tests

Modular sanity/regression suite. Re-run after any change.

## Run

```bash
./tests/run-all.sh           # unit + integration + functional
./tests/run-all.sh --fast    # unit only (quick config/deps check)
./tests/run-all.sh unit      # one layer
./tests/run-all.sh functional/20-organize-downloads.sh   # single test
```

## Conventions

| Exit code | Meaning |
|-----------|---------|
| 0 | PASS |
| 1 | FAIL |
| 77 | SKIP — optional prerequisite not configured |

- Functional tests operate **only** on `tests/fixtures/` — never real user data
- Output written to `tests/fixtures/**/__output/` (gitignored)
- New capability → new test file; changed behavior → update the existing test
- Full suite green = safe to proceed / commit

## Layers

| Layer | What it checks | Examples |
|-------|----------------|----------|
| `unit/` | Static validity: config JSON, model presence, deps installed, script perms | 01–04 |
| `integration/` | OpenCode ↔ external services: model connect, MCP, web tools, skills parse | 10–14 |
| `functional/` | End-to-end script behavior on fixtures | 20–25 |

## Adding a test

1. Create `tests/<layer>/NN-<name>.sh` (executable)
2. Source `tests/lib/common.sh` for helpers (`pass`, `fail`, `skip`, `assert_*`)
3. Use fixtures from `tests/fixtures/`; create `__output/` for results
4. Wire into `run-all.sh` if it doesn't auto-discover (it auto-discovers by default)
