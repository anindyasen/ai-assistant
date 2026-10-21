# Local AI Assistant

A compact, version-controlled setup for a **local, CPU-only AI assistant** that handles
research, file organization, Gmail, notes, and portfolio analysis.

**Stack**: [Ollama](https://ollama.com) (models) + [OpenCode](https://opencode.ai) (agent engine).
No OpenWebUI, no extra daemons.

- **Plan**: [docs/plan.md](docs/plan.md)
- **Manual setup**: [docs/PREREQUISITES.md](docs/PREREQUISITES.md)
- **Revisions**: [docs/CHANGELOG.md](docs/CHANGELOG.md)

## How it works

```
  ┌──────────────────────────────────────────────────────────────┐
  │  YOUR INPUT                                                   │
  │  TUI (opencode) · Browser (opencode web) · Phone (serve API)  │
  │  Script (opencode run) · Scheduled (systemd timer)            │
  └───────────────────────────┬──────────────────────────────────┘
                              ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  OPENCODE AGENT                                               │
  │  Loads: config/opencode.json (model, permissions, MCP)        │
  │  Loads: skill matching the task → SOP rules injected          │
  └───────────────────────────┬──────────────────────────────────┘
                              ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  MODEL (Ollama: qwen3:8b or :4b)                              │
  │  Reads SOP + context → decides tool calls                     │
  └───────────────────────────┬──────────────────────────────────┘
                              ▼
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
  ┌───────────┐        ┌────────────┐        ┌────────────┐
  │  bash     │        │ MCP servers│        │ webfetch / │
  │  scripts, │        │ gmail,     │        │ websearch  │
  │  system   │        │ notion,    │        │            │
  │  commands │        │ gdrive     │        │            │
  └─────┬─────┘        └─────┬──────┘        └─────┬──────┘
        └─────────────────────┼─────────────────────┘
                              ▼
                   results back to model
                              ▼
                   final answer / action report
```

### Example runs

| You type | Flow |
|----------|------|
| "Organize my downloads" | model → skill `organize-files` → bash `scripts/organize-downloads` → files sorted → report |
| "Summarize unread emails" | model → skill `email` → gmail MCP → inbox → summary |
| "Portfolio report" | model → skill `portfolio` → bash `scripts/portfolio-report` → yfinance → markdown |
| "Find notes about X" | model → skill `notes` → search Obsidian vault → results |
| "Research topic Y" | model → skill `research` → websearch + webfetch → sourced summary |

Scripts are thin entry points; the **skill** supplies the rules (naming, layout, safety),
so interactive chat and automation behave identically.

## Quick start

```bash
# 1. Complete manual prerequisites
#    (Notion key, Gmail OAuth, portfolio CSV — see docs/PREREQUISITES.md)

# 2. One-time setup (deps + models + config link)
./scripts/setup/install-deps.sh
./scripts/setup/pull-models.sh
./scripts/setup/link-config.sh

# 3. Use
opencode                    # interactive TUI
./scripts/morning-brief     # daily briefing
./scripts/organize-downloads

# 4. Test (sanity / regression)
./tests/run-all.sh
```

## Repository layout

| Path | Purpose |
|------|---------|
| `docs/plan.md` | Canonical plan (phases, decisions) |
| `docs/PREREQUISITES.md` | Manual one-time steps |
| `docs/CHANGELOG.md` | Plan/project revisions |
| `config/opencode.json` | OpenCode config (symlinked to `~/.config/opencode/`) |
| `config/modelfiles/` | Ollama Modelfiles (personas) |
| `config/mcp/*.example` | Secrets templates (real files in `~/.config/local-ai/`, gitignored) |
| `skills/*/SKILL.md` | Task SOPs — the determinism layer |
| `scripts/` | Automation entry points |
| `scripts/setup/` | One-time install helpers |
| `tests/` | Modular sanity/regression suite |

## Models

| Model | Role |
|-------|------|
| `qwen3:8b` | Main reasoning, research, tool calling |
| `qwen3:4b` | Fast classification, bulk operations |
| `moondream` | Photo understanding (vision) |
| `nomic-embed-text` | Embeddings for semantic search |

## Testing

```bash
./tests/run-all.sh          # everything
./tests/run-all.sh --fast   # unit only
```

- Exit 0 = pass · 1 = fail · 77 = skip (optional service not configured)
- Functional tests use `tests/fixtures/` only — never your real data
- New feature → new test file; behavior change → update the existing test
- Full suite green = safe to proceed

## Mobile access (Phase 8, future)

```bash
opencode serve --port 4096 --hostname 0.0.0.0
```

Reach `http://<lan-ip>:4096` from your phone. Prefer [Tailscale](https://tailscale.com)
over port-forwarding for remote access. Auth hardening is tracked in the plan.

## Safety rules (baked into config)

- `bash` defaults to `ask` — only read-only commands auto-allowed
- File edits require approval
- Scripts **never delete** — duplicates move to `_duplicates/`
- Credentials and `.env` files are gitignored

## Adding a new capability

1. Add a phase to `docs/plan.md` (+ Changelog entry)
2. Write a skill under `skills/<name>/SKILL.md` (the SOP)
3. Add a thin script under `scripts/` if it should be runnable standalone
4. Add tests under `tests/functional/` + fixtures
5. Update `docs/PREREQUISITES.md` if manual steps are needed
6. Commit
