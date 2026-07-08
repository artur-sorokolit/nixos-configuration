# Claude Code config

Backup of my custom [Claude Code](https://claude.com/claude-code) skills and memory.

- `skills/hypr-config/` — the skill that guides Claude when working on this repo's own
  Hyprland + Quickshell config (`config/sessions/hyprland/`).
- `skills/nlm-skill/` — a skill for driving the NotebookLM CLI/MCP server.
- `memory/` — accumulated project/feedback notes Claude's memory system has built up
  (see `MEMORY.md` for the index). One entry (SSH access to a personal server) is
  intentionally excluded since this repo is public.

To use: copy `skills/*` into `~/.claude/skills/` and `memory/*` into
`~/.claude/projects/-home-artur/memory/` (or wherever your Claude Code memory dir lives).
