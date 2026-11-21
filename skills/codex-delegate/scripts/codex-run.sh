#!/usr/bin/env bash
# codex-run.sh — portable helper for delegating work to OpenAI Codex CLI.
# Works on macOS, Linux and WSL with bash 3.2+. No machine-specific paths.
#
#   codex-run.sh preflight [--model <slug>]
#   codex-run.sh run --dir <repo> (--prompt "<text>" | --task-file <file>)
#                    [--model gpt-6.2-sol] [--effort medium] [--sandbox workspace-write]
#                    [--image <file>]... [--worktree] [--json] [--log-dir <dir>]
#   codex-run.sh smoke [--model <slug>]      # 1-line prompt to prove auth+model work
set -uo pipefail

die()  { printf 'error: %s\n' "$*" >&2; exit 2; }
info() { printf '%s\n' "$*"; }
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"

need_codex() {
  command -v codex >/dev/null 2>&1 || die "codex not found in PATH. Install: npm install -g @openai/codex (needs Node.js), then: codex login"
}

list_models() {  # prints "slug<TAB>visibility" from the local models cache, if present
  local cache="$CODEX_HOME_DIR/models_cache.json"
  [ -f "$cache" ] || return 1
  command -v python3 >/dev/null 2>&1 || return 1
  python3 - "$cache" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
m = d.get("models", d) if isinstance(d, dict) else d
for x in (m if isinstance(m, list) else []):
    s = x.get("slug") or x.get("id")
    if s: print(f"{s}\t{x.get('visibility','')}")
PY
}

config_model() {
  local cfg="$CODEX_HOME_DIR/config.toml"
  [ -f "$cfg" ] || return 0
  # first top-level `model = "..."` line (before any [table])
  awk '/^\[/{exit} /^[[:space:]]*model[[:space:]]*=/{gsub(/.*=[[:space:]]*"|".*/,""); print; exit}' "$cfg"
}

model_ok() {  # returns 0 if slug is in cache (or cache unavailable → unknown → 0)
  local slug="$1" models
  models="$(list_models 2>/dev/null)" || return 0
  [ -z "$models" ] && return 0
  printf '%s\n' "$models" | cut -f1 | grep -qx "$slug"
}

cmd_preflight() {
  local want=""
  while [ $# -gt 0 ]; do case "$1" in --model) want="$2"; shift 2;; *) die "unknown arg $1";; esac; done
  need_codex
  info "codex:   $(codex --version 2>/dev/null | head -1)"
  info "login:   $(codex login status 2>&1 | head -1)"
  local cm; cm="$(config_model)"
  if [ -n "$cm" ]; then
    if model_ok "$cm"; then info "config:  model=$cm (available)"
    else info "config:  model=$cm  ⚠ NOT in this account's model list → always pass --model"; fi
  else info "config:  no default model set"; fi
  local models; models="$(list_models 2>/dev/null)"
  if [ -n "$models" ]; then
    info "models (listed):"; printf '%s\n' "$models" | awk -F'\t' '$2=="list"{print "  - "$1}'
  else info "models:  cache not found yet (run any codex command once), trust \`/model\` inside codex"; fi
  if [ -n "$want" ]; then model_ok "$want" && info "check:   $want OK" || info "check:   $want NOT available"; fi
  case "$(uname -s)" in Darwin) info "note:    macOS blocks CLI writes in ~/Downloads, ~/Desktop, ~/Documents unless granted — prefer ~/Projects";; esac
}

cmd_smoke() {
  local model="gpt-6.2-sol"
  while [ $# -gt 0 ]; do case "$1" in --model) model="$2"; shift 2;; *) die "unknown arg $1";; esac; done
  need_codex
  local tmp; tmp="$(mktemp -d)"
  ( cd "$tmp" && codex exec --skip-git-repo-check --ephemeral -s read-only -m "$model" \
      -c 'model_reasoning_effort="low"' -- "Reply with exactly: OK" < /dev/null 2>&1 ) | tail -n 3
  rm -rf "$tmp"
}

cmd_run() {
  local dir="" prompt="" task="" model="gpt-6.2-sol" effort="medium" sandbox="workspace-write"
  local worktree="" json="" logdir="" ; local -a images=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) dir="$2"; shift 2;;
      --prompt) prompt="$2"; shift 2;;
      --task-file) task="$2"; shift 2;;
      --model) model="$2"; shift 2;;
      --effort) effort="$2"; shift 2;;
      --sandbox) sandbox="$2"; shift 2;;
      --image) images+=("$2"); shift 2;;
      --worktree) worktree=1; shift;;
      --json) json=1; shift;;
      --log-dir) logdir="$2"; shift 2;;
      *) die "unknown arg $1";;
    esac
  done
  need_codex
  [ -n "$dir" ] || die "--dir is required"
  [ -d "$dir" ] || die "dir not found: $dir"
  dir="$(cd "$dir" && pwd)"
  case "$sandbox" in read-only|workspace-write) ;; *) die "sandbox must be read-only or workspace-write (bypass modes are intentionally not offered)";; esac
  case "$effort" in minimal|low|medium|high|xhigh) ;; *) die "effort must be minimal|low|medium|high|xhigh";; esac
  if [ -n "$task" ]; then
    [ -f "$dir/$task" ] || [ -f "$task" ] || die "task file not found: $task"
    prompt="อ่าน AGENTS.md (ถ้ามี) แล้วทำใบงาน ${task} ให้เสร็จสมบูรณ์ตามเกณฑ์ผ่านในใบงาน สรุปไฟล์ที่แก้ คำสั่งที่รัน และผลทดสอบจริง${prompt:+ — หมายเหตุเพิ่มเติม: $prompt}"
  fi
  [ -n "$prompt" ] || die "--prompt or --task-file is required"
  model_ok "$model" || die "model '$model' is not in this account's model list (run: $0 preflight)"

  local -a args=(exec -C "$dir" -m "$model" -c "model_reasoning_effort=\"$effort\"" -s "$sandbox")
  git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || args+=(--skip-git-repo-check)
  [ -n "$worktree" ] && args+=(--worktree)
  [ -n "$json" ] && args+=(--json)
  local img; for img in ${images[@]+"${images[@]}"}; do
    [ -f "$img" ] || [ -f "$dir/$img" ] || die "image not found: $img"; args+=(-i "$img")
  done

  [ -n "$logdir" ] || logdir="$dir/.codex-runs"
  mkdir -p "$logdir" || die "cannot create $logdir"
  # keep run logs out of `git status` locally (never touches the shared .gitignore)
  local gitdir; gitdir="$(git -C "$dir" rev-parse --git-dir 2>/dev/null)" && {
    case "$gitdir" in /*) ;; *) gitdir="$dir/$gitdir";; esac
    mkdir -p "$gitdir/info" && { grep -qx '.codex-runs/' "$gitdir/info/exclude" 2>/dev/null || echo '.codex-runs/' >> "$gitdir/info/exclude"; }
  }
  local stamp; stamp="$(date +%Y%m%d-%H%M%S)"
  local log="$logdir/$stamp.log" last="$logdir/$stamp.last.md"
  args+=(-o "$last" -- "$prompt")

  info "▶ codex ${args[*]:0:9} … (log: $log)"
  local start=$SECONDS rc
  ( cd "$dir" && codex "${args[@]}" < /dev/null ) > "$log" 2>&1; rc=$?
  info "■ exit=$rc  time=$((SECONDS-start))s  $(grep -A1 -i '^tokens used' "$log" | tail -1 | sed 's/^/tokens=/')"
  if [ -s "$last" ]; then info "--- final message ($last) ---"; sed -n '1,40p' "$last"; echo; else info "--- tail of log ---"; tail -n 20 "$log"; fi
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    info "--- git status ---"; git -C "$dir" status --short | grep -v '\.codex-runs/' | head -40
    info "--- diff --stat ---"; git -C "$dir" diff --stat | tail -20
  fi
  return $rc
}

sub="${1:-}"; [ $# -gt 0 ] && shift
case "$sub" in
  preflight) cmd_preflight "$@";;
  smoke)     cmd_smoke "$@";;
  run)       cmd_run "$@";;
  *) sed -n '2,9p' "$0"; exit 1;;
esac
