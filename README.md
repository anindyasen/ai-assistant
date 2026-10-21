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
  │  Loads: config/opencode.json (provider, permissions, MCP)     │
  │  Loads: config/agents/*.md   → routes task to the right model │
  │  Loads: skill matching the task → SOP rules injected          │
  └───────────────────────────┬──────────────────────────────────┘
                              ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  HYBRID MODEL ROUTING (see "Agents & models" below)           │
  │  thinking  (qwen3:8b) → reason, research, analyze, orchestrate│
  │  fast      (qwen3:4b) → mechanical file/bulk work             │
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

## Agents & models (hybrid routing)

The assistant uses **two model classes** so slow reasoning never stalls mechanical work:

| Agent | Mode | Model | Used for |
|-------|------|-------|----------|
| `assistant` | primary | `qwen3:8b` (thinking) | Orchestration, research, analysis — anything needing reasoning |
| `researcher` | subagent | `qwen3:8b` (thinking) | Web research with sourced summaries |
| `analyst` | subagent | `qwen3:8b` (thinking) | Portfolio risk analysis |
| `file-organizer` | all | `qwen3:4b` (fast) | Mechanical sorting of downloads/photos/music |

The `assistant` **delegates** bulk file work to `file-organizer` via the Task tool, so the
fast model does the repetitive work while the thinking model only plans and reviews.

Scripts select the agent explicitly:
`scripts/organize-*` → `--agent file-organizer`; `scripts/morning-brief`,
`scripts/portfolio-report` → `--agent assistant`.

Agent definitions live in `config/agents/*.md` (committed) and are symlinked to
`~/.config/opencode/agents/` by `scripts/setup/link-config.sh`.

## Quick start

### 1. Clone anywhere

```bash
git clone https://github.com/anindyasen/ai-assistant.git
cd ai-assistant
```

Nothing is hardcoded to a specific user or location: all paths are relative or use
`~`, and every local/secret file is gitignored. Clone it wherever you like.

### 2. One-time setup

```bash
./scripts/setup/install-deps.sh   # system tools + project-local Python .venv (uv)
./scripts/setup/pull-models.sh    # pulls the Ollama models
./scripts/setup/link-config.sh    # symlinks config + agents into ~/.config/opencode/
```

`install-deps.sh` may ask for your `sudo` password (it installs a few system tools).
`link-config.sh` keeps the repo as the single source of truth — edits here take effect
immediately, and any stray local config is stashed inside the repo's ignored `.local/`.

### 3. Manual prerequisites (optional services)

Notion, Gmail, and a portfolio CSV require one-time manual steps — see
[docs/PREREQUISITES.md](docs/PREREQUISITES.md). Everything else works without them;
the assistant will simply skip unconfigured services.

### 4. Use

```bash
opencode                      # interactive TUI (Tab switches agents)
./scripts/morning-brief       # daily briefing (thinking model)
./scripts/organize-downloads  # sort ~/Downloads (fast model)
./scripts/organize-photos     # sort photos into YYYY/MM (fast model)
./scripts/portfolio-report    # portfolio risk report (thinking model)
```

### 5. Verify

```bash
./tests/run-all.sh            # full suite; functional tests use fixtures only
```

### Where local & secret files live

| Kind | Location | Committed? |
|------|----------|-----------|
| Config + agents | `config/` (symlinked into `~/.config/opencode/`) | yes |
| Secrets / tokens | `~/.config/local-ai/` and `config/mcp/*.env` | no (gitignored) |
| Local overrides / stashes | `<repo>/.local/` | no (gitignored) |
| Generated reports | `<repo>/reports/` | no (gitignored) |
| Python venv | `<repo>/.venv/` | no (gitignored) |

Everything machine-specific stays inside the repo (ignored) or in `~/.config/local-ai/`,
so the repository never carries personal paths, tokens, or local state.

## Repository layout

| Path | Purpose |
|------|---------|
| `docs/plan.md` | Canonical plan (phases, decisions) |
| `docs/PREREQUISITES.md` | Manual one-time steps |
| `docs/CHANGELOG.md` | Plan/project revisions |
| `config/opencode.json` | OpenCode config (symlinked to `~/.config/opencode/`) |
| `config/agents/*.md` | Agent definitions — hybrid model routing (symlinked to `~/.config/opencode/agents/`) |
| `config/modelfiles/` | Ollama Modelfiles (personas) |
| `config/mcp/*.example` | Secrets templates (real files in `~/.config/local-ai/`, gitignored) |
| `skills/*/SKILL.md` | Task SOPs — the determinism layer |
| `scripts/` | Automation entry points |
| `scripts/setup/` | One-time install helpers |
| `tests/` | Modular sanity/regression suite |
| `.local/` | Local stashes/overrides (gitignored, never committed) |

## Models

| Model | Class | Role |
|-------|-------|------|
| `qwen3:8b` | thinking | Reasoning, research, analysis, orchestration |
| `qwen3:4b` | fast | Mechanical classification, bulk file operations |
| `moondream` | vision | Photo understanding |
| `nomic-embed-text` | embedding | Semantic search over notes/docs |

Only one model is resident at a time — Ollama unloads an idle model after ~5 min.
On CPU, expect ~14 tok/s for the 4B model; the thinking model trades speed for quality,
which is why mechanical work is delegated to the fast model.

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
