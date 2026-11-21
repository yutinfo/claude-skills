#!/usr/bin/env bash
# install.sh — link this repo's skills into Claude Code (~/.claude/skills) on any machine.
#   ./install.sh            link every skill in ./skills (symlink → `git pull` updates them instantly)
#   ./install.sh --copy     copy instead of symlink (e.g. Windows without symlink rights)
#   ./install.sh --check    also run each skill's preflight (codex / agy installed & logged in?)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
MODE=link; CHECK=""
for a in "$@"; do case "$a" in --copy) MODE=copy;; --check) CHECK=1;; -h|--help) sed -n '2,6p' "$0"; exit 0;; *) echo "unknown option: $a" >&2; exit 2;; esac; done

mkdir -p "$DEST"
for src in "$REPO"/skills/*/; do
  name="$(basename "$src")"; target="$DEST/$name"
  if [ -L "$target" ]; then rm "$target"
  elif [ -e "$target" ]; then
    # keep backups OUTSIDE the skills dir, otherwise Claude would load them as duplicate skills
    bdir="$(dirname "$DEST")/skills-backup"; mkdir -p "$bdir"
    backup="$bdir/$name-$(date +%Y%m%d-%H%M%S)"; mv "$target" "$backup"; echo "  backed up existing $name → $backup"
  fi
  if [ "$MODE" = link ]; then ln -s "${src%/}" "$target"; echo "✓ linked  $name → ${src%/}"
  else cp -R "${src%/}" "$target"; echo "✓ copied  $name"; fi
  chmod +x "$target"/scripts/*.sh 2>/dev/null || true
done

if [ -n "$CHECK" ]; then
  echo; echo "== preflight =="
  [ -x "$DEST/codex-delegate/scripts/codex-run.sh" ] && { echo "-- codex"; bash "$DEST/codex-delegate/scripts/codex-run.sh" preflight || true; }
  [ -x "$DEST/agy-delegate/scripts/agy-run.sh" ] && { echo "-- agy"; bash "$DEST/agy-delegate/scripts/agy-run.sh" preflight || true; }
fi
echo; echo "Done. Restart Claude Code (or open a new session) to load the skills."
