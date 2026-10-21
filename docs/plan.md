# Plan 001: Local AI Assistant for Daily Tasks

- **Status**: Draft — awaiting approval
- **Created**: 2026-10-21
- **Last updated**: 2026-10-21
- **Stack**: Ollama (models) + OpenCode (agent/tool engine)
- **Hardware**: 16GB RAM, CPU-only, Arch Linux
- **Project path**: `~/Projects/ai-assistant/`

## Goal

A compact, maintainable local AI assistant handling:

1. **Research** — web search, fetch, summarize
2. **File organization** — photos, documents, code, downloads, music
3. **Web tasks** — Gmail via API, portfolio analysis
4. **Notes** — Notion, Obsidian (markdown), Google Docs/Drive, Google Keep (workaround)

## User Requirements

| # | Requirement | How this plan satisfies it |
|---|-------------|---------------------------|
| 1 | Standalone project under `~/Projects/` | Project at `~/Projects/ai-assistant/` (own git repo). Config, scripts, docs, tests all inside. Secrets gitignored → `~/.config/local-ai/`. |
| 2 | Prerequisites = manual steps only | `docs/PREREQUISITES.md`: browser logins, exports, personal paths only. Setup/verification handled by `scripts/setup/` or OpenCode itself. |
| 3 | Default folder for all plans | Working drafts in `opencode/plans/` (generic workspace, `NNN-<name>.md`). Finalized plan copied to project `docs/plan.md` and maintained there going forward. |
| 4 | OpenWebUI required? | **No — dropped.** Stack = Ollama + OpenCode only. |
| 5 | Future mobile access | `opencode serve` → HTTP API/web UI on LAN; Phase 8 hardens it. Scripts are headless-safe (`opencode run`). |
| 6 | Deterministic workflows | Skills (Phase 2.5) encode SOPs — naming conventions, folder layouts, report formats — shared by interactive chat and scripts. Plus a modular test plan (Phase 9) for ongoing sanity checks. |

## Workspace vs Project

| Location | Role | Git |
|----------|------|-----|
| `~/Projects/local-llm/opencode/` | Generic OpenCode workspace. `plans/` = working drafts for all projects. | optional |
| `~/Projects/ai-assistant/` | **The project.** Canonical: `docs/plan.md`, config, scripts, skills, tests, README. | yes — primary repo |

Flow: draft in `opencode/plans/` → on approval, project repo created and plan finalized in `docs/plan.md` → future changes tracked in the project's Changelog.

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Chat UI | OpenCode TUI + `opencode web` + `opencode serve` | OpenWebUI dropped — OpenCode covers TUI, browser, one-shot CLI, HTTP server with zero extra processes. |
| Agent engine | OpenCode | Native tool calling (bash, edit, MCP), skills, git-friendly config. |
| Models | Ollama | Already installed; CPU-friendly catalog. |
| Determinism | Skills + scripts | Skills hold task SOPs (rules, formats); scripts are thin entry points. Same rules apply in chat and automation. |
| Mobile access | `opencode serve` (HTTP API) | LAN-reachable; Phase 8 adds Tailscale/auth. |
| Config location | Project repo | Single source of truth; symlinked into `~/.config/opencode/`. |
| Secrets | `~/.config/local-ai/` (outside repo) | Repo stays committable; `.example` templates tracked. |
| Testing | Modular shell test suite in `tests/` | Unit + integration + functional layers; skips gracefully for unconfigured services. Re-runnable for regression/sanity. |

## Model Roster (16GB RAM / CPU) — hybrid routing

| Ollama Model | Class | Role | ~RAM |
|--------------|-------|------|------|
| `qwen3:8b` | thinking | Orchestration, research, analysis — anything requiring reasoning | 5.0 GB |
| `qwen3:4b` | fast | Mechanical classification, bulk file operations | 2.5 GB |
| `moondream` | vision | Photo description / vision tasks | 1.7 GB |
| `nomic-embed-text` | embedding | Semantic search, RAG over notes/docs | 0.3 GB |

> One large model loaded at a time (Ollama unloads after ~5min idle).

### Hybrid routing via agents (`config/agents/`)

Mechanical work must not wait on slow reasoning. Agents bind a task to a model class:

| Agent | Mode | Model | Responsibility |
|-------|------|-------|----------------|
| `assistant` | primary | `qwen3:8b` (thinking) | Orchestrate, research, analyze; delegate bulk work via Task tool |
| `researcher` | subagent | `qwen3:8b` (thinking) | Web research → sourced summary |
| `analyst` | subagent | `qwen3:8b` (thinking) | Portfolio risk report |
| `file-organizer` | all | `qwen3:4b` (fast) | Mechanical sorting (downloads/photos/music) |

Rule of thumb: **reasoning/research/analysis/orchestration → thinking model; repetition/classification/bulk ops → fast model.**
Scripts pick the agent explicitly (`--agent file-organizer` vs `--agent assistant`).

## How It Works (flow — goes into README)

```
  ┌──────────────────────────────────────────────────────────────┐
  │  YOUR INPUT                                                   │
  │  TUI (opencode) · Browser (opencode web) · Phone (serve API)  │
  │  Script (opencode run) · Scheduled (systemd timer)            │
  └───────────────────────────┬──────────────────────────────────┘
                              ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  OPENCODE AGENT                                               │
  │  Loads: opencode.json (model, permissions, MCP servers)       │
  │  Loads: skill matching the task (if any) → SOP rules injected │
  └───────────────────────────┬──────────────────────────────────┘
                              ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  MODEL (Ollama: qwen3:8b or :4b)                              │
  │  Reads SOP + context → decides tool calls (may be several)    │
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

**Example runs:**

| You type | Flow |
|----------|------|
| "Organize my downloads" | model → skill `organize-files` (SOP) → bash `scripts/organize-downloads` → files sorted per SOP → report |
| "Summarize unread emails" | model → skill `email` → gmail MCP → inbox data → summarized |
| "Portfolio report" | model → skill `portfolio` → bash `scripts/portfolio-report` → yfinance → markdown report |
| "Find notes about X" | model → skill `notes` → grep/rg over Obsidian vault → results |
| "Research topic Y" | model → skill `research` → websearch + webfetch → sourced summary |

## Skills (Phase 2.5 — determinism layer)

Skills = `SKILL.md` files auto-loaded by OpenCode when a task matches. They inject fixed SOPs so the model doesn't reinvent conventions each run.

| Skill | Encodes |
|-------|---------|
| `organize-files` | Folder layouts (YYYY/MM photos, type-based downloads), naming patterns, "never delete", duplicates → `_duplicates/`, report format |
| `research` | Source requirements, summary template, citation format |
| `notes` | Vault path, note naming, frontmatter format, where new notes go |
| `email` | Read/draft-only default, grouping taxonomy (action/fyi/noise), never send without explicit confirm |
| `portfolio` | CSV schema, report template, flag thresholds (>15% loss, >25% concentration) |

Scripts stay as thin entry points that invoke `opencode run` — the skill supplies the rules, so interactive chat and scripts behave identically.

## Project Layout (created on approval)

```
~/Projects/ai-assistant/                 # primary git repo
├── docs/
│   ├── plan.md                          # this file (canonical)
│   ├── PREREQUISITES.md                 # manual-only steps
│   └── CHANGELOG.md                     # plan revisions
├── config/
│   ├── opencode.json
│   ├── agents/                          # hybrid model routing (symlinked)
│   │   ├── assistant.md
│   │   ├── researcher.md
│   │   ├── analyst.md
│   │   └── file-organizer.md
│   ├── modelfiles/
│   │   └── organizer
│   └── mcp/
│       ├── gmail.env.example
│       └── notion.env.example
├── skills/
│   ├── organize-files/SKILL.md
│   ├── research/SKILL.md
│   ├── notes/SKILL.md
│   ├── email/SKILL.md
│   └── portfolio/SKILL.md
├── scripts/
│   ├── organize-photos
│   ├── organize-downloads
│   ├── organize-music
│   ├── portfolio-report
│   ├── morning-brief
│   └── setup/
│       ├── pull-models.sh
│       ├── install-deps.sh
│       └── link-config.sh
├── tests/
│   ├── README.md                        # how to run, test taxonomy
│   ├── run-all.sh                       # runs everything, summary
│   ├── lib/common.sh                    # shared assert/skip helpers
│   ├── unit/
│   │   ├── 01-config-valid.sh           # JSON valid, schema check
│   │   ├── 02-models-present.sh         # ollama models pulled
│   │   ├── 03-deps-installed.sh         # exiftool, fdupes, ffprobe, yfinance
│   │   └── 04-scripts-executable.sh     # all scripts have +x
│   ├── integration/
│   │   ├── 10-opencode-model-connect.sh # opencode can reach model
│   │   ├── 11-skills-loadable.sh        # each SKILL.md parses, referenced tools exist
│   │   ├── 12-mcp-notion.sh             # notion MCP responds (skip if unconfigured)
│   │   ├── 13-mcp-gmail.sh              # gmail MCP responds (skip if unconfigured)
│   │   └── 14-web-tools.sh              # webfetch + websearch work
│   ├── functional/
│   │   ├── 20-organize-downloads.sh     # fixture dir → expected structure
│   │   ├── 21-organize-photos.sh        # fixture photos → YYYY/MM + dedup
│   │   ├── 22-organize-music.sh         # fixture audio → Artist/Album
│   │   ├── 23-portfolio-report.sh       # fixture CSV → report file
│   │   ├── 24-morning-brief.sh          # smoke: completes without error
│   │   └── 25-notes-obsidian.sh         # create/find note in test vault
│   └── fixtures/
│       ├── downloads/                   # sample files per type
│       ├── photos/                      # images w/ and w/o EXIF
│       ├── music/                       # sample audio w/ mixed tags
│       ├── portfolio.csv
│       └── vault/                       # throwaway Obsidian-style vault
├── README.md                            # overview + flow diagram
└── .gitignore
```

**Test conventions:**
- Exit 0 = pass; exit 1 = fail; special exit 77 = skip (missing optional prerequisite)
- `run-all.sh` prints per-test PASS/FAIL/SKIP + summary; `--fast` runs unit only
- Functional tests operate only on `tests/fixtures/` — never touch real user data
- New features → new test file; modified behavior → update the existing test
- Full suite re-run = sanity/regression check after any change

**Committability & privacy rules:**
- The repo contains **no personal paths, usernames, tokens, or local state**. All paths are
  relative or `~`-based; the clone location is irrelevant.
- Anything machine-specific lives in `<repo>/.local/` (gitignored) or `~/.config/local-ai/`.
- Secrets are gitignored with `.example` templates committed; generated reports → `reports/`.
- `link-config.sh` stashes any stray local config into `<repo>/.local/stashed/` instead of
  leaving it outside the project.

## PREREQUISITES.md scope (manual only)

1. **Obsidian vault** — provide path or create new
2. **Notion** — create integration in browser → API key into env file
3. **Gmail + Google Drive** — Google Cloud project, enable APIs, download OAuth JSON
4. **Portfolio CSV** — export from Indian broker to `~/Finance/portfolio.csv`
5. *(Optional)* **Mobile/LAN** — Tailscale vs LAN-only decision

Excluded (OpenCode/setup handles): Ollama status, model pulls, package installs, config symlink.

## Phases

### Phase 0 — Project bootstrap
- [ ] Create `~/Projects/ai-assistant/` + `git init`
- [ ] `docs/plan.md` (this file), `docs/PREREQUISITES.md`, `docs/CHANGELOG.md`
- [ ] `config/`, `skills/`, `scripts/`, `tests/` scaffolding
- [ ] `README.md` with flow diagram
- [ ] `.gitignore` → first commit
- [ ] Clean `opencode/` — keep only `plans/`

### Phase 1 — Base (models + config)
- [ ] `scripts/setup/` — install deps, pull models, link config
- [ ] `config/opencode.json` — Ollama provider, permissions, MCP stubs
- [ ] `config/modelfiles/organizer`
- [ ] Verify: `opencode` connects to `ollama/qwen3:8b`
- [ ] Tests: `unit/01–04`, `integration/10`

### Phase 2 — File organization
- [ ] `scripts/organize-photos|downloads|music`
- [ ] Verify: run each on a test folder
- [ ] Tests: `functional/20–22` + fixtures

### Phase 2.5 — Skills (determinism layer)
- [ ] Write 5 skills: organize-files, research, notes, email, portfolio
- [ ] Wire skills dir into OpenCode config
- [ ] Verify: interactive prompts produce SOP-conformant output
- [ ] Tests: `integration/11`

### Phase 3 — Notes (Obsidian → Notion → Drive)
- [ ] Obsidian: vault path from PREREQUISITES
- [ ] Notion: enable MCP after key present
- [ ] Google Docs/Drive: same OAuth as Gmail
- [ ] Google Keep: workaround (deferred)
- [ ] Tests: `functional/25`, `integration/12`

### Phase 4 — Gmail
- [ ] User completes OAuth (PREREQUISITES step 3)
- [ ] Enable Gmail MCP
- [ ] Verify: "summarize unread emails"
- [ ] Tests: `integration/13`

### Phase 5 — Portfolio
- [ ] `scripts/portfolio-report`
- [ ] User exports CSV (PREREQUISITES step 4)
- [ ] Tests: `functional/23`

### Phase 6 — Daily drivers
- [ ] `scripts/morning-brief`
- [ ] Optional systemd timers
- [ ] Tests: `functional/24`

### Phase 7 — Web research polish
- [ ] Research skill refinement (sources, templates)
- [ ] Tests: `integration/14`

### Phase 8 — Mobile access
- [ ] `opencode serve` on LAN
- [ ] Tailscale (recommended) or reverse proxy
- [ ] Phone: bookmark web UI / call API

### Phase 9 — Test suite maintenance
- [ ] `tests/run-all.sh` green across unit + integration + functional
- [ ] Document skip conditions per service in `tests/README.md`
- [ ] Re-run full suite after every future change (regression gate)

## Out of Scope (deliberately)

- OpenWebUI — dropped (compact stack; OpenCode covers all interaction modes)
- Voice interface
- Fully offline mode (user opted into cloud APIs)
- Google Keep native API (no official API — workaround only)

## Changelog

| Date | Change |
|------|--------|
| 2026-10-21 | Initial draft |
| 2026-10-21 | Restructured: project → `~/Projects/ai-assistant/`; `opencode/plans/` = generic drafts; prerequisites trimmed to manual-only |
| 2026-10-21 | Added: skills phase (2.5) for determinism; modular test plan (Phase 9 + `tests/` layout); flow diagram spec for README |
| 2026-10-21 | Added hybrid model routing via agents (`config/agents/`); privacy/committability rules; `.local/` ignored workspace |
