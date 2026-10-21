# Changelog

All notable changes to the plan and project are recorded here.

Format follows [Keep a Changelog](https://keepachangelog.com/) conventions.

## [Unreleased]

### Added
- Phase 0 — project bootstrap
- Hybrid model routing via agents (`config/agents/`): `assistant`/`researcher`/`analyst`
  use the thinking model (qwen3:8b); `file-organizer` uses the fast model (qwen3:4b)
- Agent symlink support in `scripts/setup/link-config.sh`
- Local/ignored workspace: `.local/`, `reports/`, `.venv/` (gitignored)
- Comprehensive `.gitignore` keeping all personal/local/secret files out of the repo

### Changed
- Provider config → `@ai-sdk/openai-compatible` + `/v1` endpoint, long timeouts
- `small_model` → `llama3.2:latest` (avoids qwen3 reasoning stall on title-gen)
- Scripts now select an agent (`--agent file-organizer|assistant`) instead of a raw model
- `morning-brief` derives its own directory (no hardcoded clone path)
- `link-config.sh` stashes stray `opencode.jsonc` into `<repo>/.local/stashed/`

## [0.1.0] — 2026-10-21

### Added
- Initial plan: local AI assistant (Ollama + OpenCode) for research, file org, Gmail, notes, portfolio
- Project structure: `docs/`, `config/`, `skills/`, `scripts/`, `tests/`
- Prerequisites doc (manual-only steps)
- Modular test plan (unit / integration / functional)
- Skills layer (Phase 2.5) for deterministic workflows
- Flow diagram for README
- Mobile access phase (Phase 8, future)
