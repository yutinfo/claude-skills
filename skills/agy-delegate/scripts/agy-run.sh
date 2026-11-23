#!/usr/bin/env bash
# agy-run.sh — portable helper for delegating work to Google Antigravity CLI (agy) in headless mode.
# Works on macOS, Linux and WSL with bash 3.2+. No machine-specific paths.
#
#   agy-run.sh preflight [--model <slug>]
#   agy-run.sh smoke [--model gemini-4-hydrogen-low]
#   agy-run.sh run --dir <repo> (--prompt "<text>" | --task-file <file>)
#                  [--model gemini-4-neon-medium] [--mode accept-edits|plan|auto]
#                  [--allow <program>]... [--timeout <seconds>] [--add-dir <dir>]... [--no-sandbox] [--strict] [--log-dir <dir>]
#
# Permission model (verified on agy 1.5.14):
#   default      sandbox on + toolPermission=proceed-in-sandbox: any command runs without a prompt, but only
#                inside the sandbox (no network, no writes outside the workspace/--add-dir, ~/.ssh unreadable).
#   --strict     sandbox on, only --allow'ed programs run. EVERY program of a pipeline must be allowed
#                (`npx vitest | tail` needs npx AND tail) and one refused command ends the whole run.
#   --no-sandbox no sandbox, only --allow'ed programs run (needed for network: npm install, curl, git push).
set -uo pipefail

die()  { printf 'error: %s\n' "$*" >&2; exit 2; }
info() { printf '%s\n' "$*"; }

need_agy() {
  # agy installs to ~/.local/bin, which non-login shells (e.g. agent tool shells) often lack on PATH
  if ! command -v agy >/dev/null 2>&1 && [ -x "$HOME/.local/bin/agy" ]; then export PATH="$HOME/.local/bin:$PATH"; fi
  command -v agy >/dev/null 2>&1 || die "agy not found in PATH. Install Google Antigravity CLI (see https://antigravity.google/docs/getting-started), then run \`agy\` once to sign in."
}

MODELS_CACHE=""
list_models() {  # "slug<TAB>name"; non-zero if not signed in / failed
  [ -n "$MODELS_CACHE" ] && { printf '%s\n' "$MODELS_CACHE"; return 0; }
  local out; out="$(agy models 2>&1 < /dev/null)" || return 1
  MODELS_CACHE="$(printf '%s\n' "$out" | grep -E $'^[a-z0-9][a-z0-9.-]+\t')" || return 1
  printf '%s\n' "$MODELS_CACHE"
}
model_ok() { list_models >/dev/null 2>&1 || return 0; printf '%s\n' "$MODELS_CACHE" | cut -f1 | grep -qx "$1"; }

json_field() {  # json_field <file> <python-expr on d>  (prints "" if python3 missing)
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$1" "$2" <<'PY'
import json, sys
try:
    raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    d = None
    for line in reversed(raw.splitlines()):          # stream-json: last {"event":"result"} line
        if line.startswith('{"event":"result"'):
            d = json.loads(line)["result"]; break
    if d is None:                                    # plain json output
        start = raw.rfind('{"conversation_id"')
        d = json.loads(raw[start:] if start >= 0 else raw)
    v = eval(sys.argv[2], {}, {"d": d})
    print(v if v is not None else "")
except Exception:
    pass
PY
}

denied_commands() {  # the exact command lines a stream-json log shows as refused, one per line
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$1" <<'PY'
import json, sys
seen = []
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    if not line.startswith('{"event":"step_update"'): continue
    try: info = json.loads(line)["step_update"].get("tool_info") or {}
    except Exception: continue
    msg = (info.get("error") or {}).get("message", "")
    if "permission" not in msg: continue
    cmd = (info.get("parameters") or {}).get("CommandLine") or info.get("name", "?")
    if cmd not in seen: seen.append(cmd)
for c in seen: print(c)
PY
}

cmd_preflight() {
  local want=""
  while [ $# -gt 0 ]; do case "$1" in --model) want="$2"; shift 2;; *) die "unknown arg $1";; esac; done
  need_agy
  info "agy:     $(agy --version 2>/dev/null | head -1) ($(command -v agy))"
  if list_models >/dev/null 2>&1; then
    info "login:   OK (models fetched)"
    info "models:"; printf '%s\n' "$MODELS_CACHE" | awk -F'\t' '{printf "  - %-34s %s\n", $1, $2}'
  else
    info "login:   ✗ could not fetch models — run \`agy\` once interactively to sign in"
  fi
  if [ -n "$want" ]; then model_ok "$want" && info "check:   $want OK" || info "check:   $want NOT available"; fi
  case "$(uname -s)" in Darwin) info "note:    macOS blocks CLI writes in ~/Downloads, ~/Desktop, ~/Documents unless granted — prefer ~/Projects";; esac
}

cmd_smoke() {
  local model="gemini-4-hydrogen-low"
  while [ $# -gt 0 ]; do case "$1" in --model) model="$2"; shift 2;; *) die "unknown arg $1";; esac; done
  need_agy
  local tmp; tmp="$(mktemp -d)"; local out="$tmp/out.json"
  ( cd "$tmp" && agy --model "$model" --mode plan --print-timeout 120s --output-format json \
      -p "Reply with exactly: OK" < /dev/null > "$out" 2>&1 )
  info "status=$(json_field "$out" 'd.get("status")')  response=$(json_field "$out" 'd.get("response","").strip()')  tokens=$(json_field "$out" 'd.get("usage",{}).get("total_tokens")')"
  [ -s "$out" ] && grep -q '"status"' "$out" || { info "--- raw ---"; tail -n 5 "$out"; }
  rm -rf "$tmp"
}

cmd_run() {
  local dir="" prompt="" task="" model="gemini-4-neon-medium" mode="accept-edits" timeout=600 sandbox=1 strict="" logdir=""
  local -a allows=() adddirs=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) dir="$2"; shift 2;;
      --prompt) prompt="$2"; shift 2;;
      --task-file) task="$2"; shift 2;;
      --model) model="$2"; shift 2;;
      --mode) mode="$2"; shift 2;;
      --allow) allows+=("$2"); shift 2;;
      --timeout) timeout="$2"; shift 2;;
      --add-dir) adddirs+=("$2"); shift 2;;
      --no-sandbox) sandbox=""; shift;;
      --strict) strict=1; shift;;
      --log-dir) logdir="$2"; shift 2;;
      *) die "unknown arg $1";;
    esac
  done
  need_agy
  [ -n "$dir" ] || die "--dir is required"; [ -d "$dir" ] || die "dir not found: $dir"
  dir="$(cd "$dir" && pwd)"
  case "$mode" in plan|accept-edits|auto) ;; *) die "mode must be plan|accept-edits|auto";; esac
  case "$timeout" in ''|*[!0-9]*) die "--timeout must be whole seconds";; esac
  local a; for a in ${allows[@]+"${allows[@]}"}; do
    case "$a" in *[\"\\\(\)]*) die "--allow value must be a plain program/prefix: $a";; esac
  done

  local allowed_list="(none)"
  [ ${#allows[@]} -gt 0 ] && allowed_list="$(printf '%s, ' "${allows[@]}" | sed 's/, $//')"
  local rules
  if [ -n "$sandbox" ] && [ -z "$strict" ]; then
    rules="เขียน/แก้ไฟล์ด้วยเครื่องมือแก้ไฟล์เท่านั้น ไม่ใช้ shell เขียนไฟล์; คำสั่ง shell รันใน sandbox: ไม่มีเครือข่าย (ห้าม npm install/curl/git push/fetch) และเขียนนอกโฟลเดอร์งานไม่ได้ — ถ้าคำสั่งล้มเพราะ sandbox ให้รายงานแล้วทำส่วนที่เหลือต่อ ห้าม commit"
  else
    rules="เขียน/แก้ไฟล์ด้วยเครื่องมือแก้ไฟล์เท่านั้น ไม่ใช้ shell เขียนไฟล์; คำสั่ง shell ใช้ได้เฉพาะโปรแกรมเหล่านี้: ${allowed_list} — ทุกโปรแกรมในคำสั่งรวมทั้งหลัง | && ; ต้องอยู่ในรายการ (ห้ามต่อ | head, | tail, | wc ถ้าไม่ได้อนุญาตไว้ ให้ใช้ตัวเลือกของโปรแกรมเองหรืออ่านไฟล์ด้วยเครื่องมืออ่านไฟล์) คำสั่งที่ถูกปฏิเสธเพียงครั้งเดียวจะจบงานทันที"
  fi
  if [ -n "$task" ]; then
    [ -f "$dir/$task" ] || [ -f "$task" ] || die "task file not found: $task"
    prompt="ทำใบงาน ${task} ให้เสร็จตามเกณฑ์ผ่าน (${rules}) แล้วสรุปไฟล์ที่แก้ คำสั่งที่รัน และผลทดสอบจริง${prompt:+ — หมายเหตุ: $prompt}"
  elif [ -n "$prompt" ]; then
    prompt="${prompt} (${rules})"
  else die "--prompt or --task-file is required"; fi
  model_ok "$model" || die "model '$model' is not available for this account (run: $0 preflight)"

  local settings='{'
  [ -n "$sandbox" ] && [ -z "$strict" ] && settings+='"toolPermission":"proceed-in-sandbox",'
  settings+='"permissions":{"allow":['
  local first=1; for a in ${allows[@]+"${allows[@]}"}; do
    [ $first -eq 1 ] || settings+=','; settings+="\"command($a)\""; first=0
  done; settings+=']}}'

  local -a args=(--model "$model" --mode "$mode" --print-timeout "${timeout}s" --output-format stream-json --settings "$settings")
  [ -n "$sandbox" ] && args+=(--sandbox)
  local d; for d in ${adddirs[@]+"${adddirs[@]}"}; do args+=(--add-dir "$d"); done
  args+=(-p "$prompt")   # -p must carry the prompt as its value, and stays last

  [ -n "$logdir" ] || logdir="$dir/.agy-runs"
  mkdir -p "$logdir" || die "cannot create $logdir"
  local gitdir; gitdir="$(git -C "$dir" rev-parse --git-dir 2>/dev/null)" && {
    case "$gitdir" in /*) ;; *) gitdir="$dir/$gitdir";; esac
    mkdir -p "$gitdir/info" && { grep -qx '.agy-runs/' "$gitdir/info/exclude" 2>/dev/null || echo '.agy-runs/' >> "$gitdir/info/exclude"; }
  }
  local log; log="$logdir/$(date +%Y%m%d-%H%M%S).ndjson"

  local policy="allow-list only"; [ -n "$sandbox" ] && [ -z "$strict" ] && policy="any command inside sandbox"
  info "▶ agy --model $model --mode $mode --print-timeout ${timeout}s allow=[${allowed_list}]${sandbox:+ sandbox} policy=[$policy] (log: $log)"
  local start=$SECONDS rc
  (
    cd "$dir" || exit 2
    if [ -n "$sandbox" ]; then
      # Inside the sandbox git cannot read the xcode-select link nor config files included from
      # ~/.gitconfig, and would die on every call. Point it at the toolchain directly and give it
      # an empty global config (so it also has no identity: commits stay the lead's job).
      if [ "$(uname -s)" = "Darwin" ] && [ -z "${DEVELOPER_DIR:-}" ] && command -v xcode-select >/dev/null 2>&1; then
        DEVELOPER_DIR="$(xcode-select -p 2>/dev/null)" && [ -n "$DEVELOPER_DIR" ] && export DEVELOPER_DIR
      fi
      export GIT_CONFIG_GLOBAL=/dev/null
    fi
    agy "${args[@]}" < /dev/null
  ) > "$log" 2>&1; rc=$?
  info "■ exit=$rc  time=$((SECONDS-start))s  status=$(json_field "$log" 'd.get("status")')  tokens=$(json_field "$log" 'd.get("usage",{}).get("total_tokens")')"
  local denied; denied="$(json_field "$log" '", ".join(x.get("action","")+":"+x.get("display_name","") for x in d.get("denied_actions",[]))')"
  if [ -n "$denied" ]; then
    info "⚠ denied_actions: $denied — a refused command ENDS the run, so the work below is incomplete"
    local dc; dc="$(denied_commands "$log")"
    [ -n "$dc" ] && { info "  refused command(s):"; printf '%s\n' "$dc" | sed 's/^/    /' | head -10; }
    if [ -n "$sandbox" ] && [ -z "$strict" ]; then
      info "  → it needed to leave the sandbox (network / path outside the workspace). Use --add-dir for extra folders, or do that step yourself; do not use skip-permissions"
    else
      info "  → every program in the command (also after | && ;) needs its own --allow; or drop --strict to run inside the sandbox instead. Do not use skip-permissions"
    fi
  fi
  local resp; resp="$(json_field "$log" 'd.get("response","")')"
  if [ -n "$resp" ]; then info "--- response ---"; printf '%s\n' "$resp" | sed -n '1,40p'
  else info "--- raw log tail ---"; tail -n 15 "$log"; fi
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    info "--- git status ---"; git -C "$dir" status --short | head -40
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
