---
name: agy-delegate
description: สั่งงานให้ Google Antigravity CLI (`agy`) แบบ headless อย่างถูกต้อง ประหยัดโควตา และตรวจสอบได้ — เลือกโมเดล Gemini 4 Hydrogen/Neon/Argon, Orchestrator, Claude 5.5 ฯลฯ ให้พอดีงาน, ตั้งสิทธิ์คำสั่งเฉพาะ session, ตั้ง timeout กันค้าง, เก็บ usage token ทุกรอบ แล้วให้ Claude ตรวจผลเอง ใช้ skill นี้ทุกครั้งที่ผู้ใช้พูดถึง agy, Antigravity, "gem"/ฝั่ง Google ในฐานะลูกทีม, ให้ Claude เป็นหัวหน้าทีมสั่งงาน AI ตัวอื่น, แบ่งงานให้ agy, รีวิว diff ด้วย agy, หรือกังวลเรื่องโควตาของ agy — แม้ไม่ได้เอ่ยชื่อ skill (ถ้าเป็นงานของ Codex ใช้ codex-delegate แทน · งานสร้างภาพทุกชนิดต้องใช้ codex-delegate เพราะ agy สร้างภาพไม่ได้)
---

# agy Delegate

Claude เป็น **หัวหน้างาน** (แตกงาน เขียนใบงาน สั่ง ตรวจ) agy เป็น **ผู้ลงมือ** เป้าหมาย: งานจบในรอบน้อยที่สุด มีหลักฐานตรวจได้ เพราะผู้ใช้มีโควตาจำกัดทุกฝั่ง

> **กฎของผู้ใช้: งานสร้างภาพส่งให้ Codex เสมอ ห้ามส่งให้ agy**
> agy ไม่มีเครื่องมือสร้างหรือแก้ภาพ และไม่มีโมเดลภาพใน `agy models` (ตรวจกับเวอร์ชัน 1.5.13) ถ้าส่งไปก็เสียโควตาเปล่า
> - "งานสร้างภาพ" คือ รูปสินค้า, ภาพประกอบ, รูปถ่ายหรือภาพเรนเดอร์, ไอคอนหรือโลโก้แบบ raster (PNG/JPG/WebP), และการแก้หรือย่อขยายภาพด้วย AI → ใช้ skill **codex-delegate** แทน (Codex มีฟีเจอร์ `image_generation`)
> - ถ้างานเดียวมีทั้งโค้ดและภาพ: ส่งใบงานภาพให้ Codex ก่อน โดยกำหนดชื่อไฟล์ ขนาด และสไตล์ไว้ในสเปกกลาง แล้วใบงานโค้ดของ agy ให้อ้างชื่อไฟล์ภาพเหล่านั้น ห้ามให้ agy ใช้ placeholder แทนภาพจริง เว้นแต่ใบงานจะสั่งไว้
> - ข้อยกเว้นเดียว: agy เขียนภาพเป็นโค้ด (SVG/CSS) ได้ ก็ต่อเมื่อใบงานบอกชัดว่าต้องการ "เขียนเป็นโค้ด" ไม่ใช่ภาพจริง
> - เครื่องมือที่ agy มี (ตรวจเมื่อ พ.ย. 2026): run_command, read/write/edit_file, **search_web** (ค้นเว็บได้ เหมาะกับงานค้นคว้าหรือหาแรงบันดาลใจ), ask_question, subagent (define/invoke/manage), swarm, schedule, run_workflow, manage_task, send_message

- สคริปต์: `scripts/agy-run.sh` (`preflight` / `smoke` / `run`) — ใส่ flag ถูกลำดับ ตั้งสิทธิ์เฉพาะ session, timeout, เก็บ log JSON + สรุป token ให้อัตโนมัติ ใช้ได้ macOS/Linux/WSL
- `references/agy-cli-guide.md` — flags, subcommands, slash commands, settings.json, ตารางโมเดลเต็ม, กลยุทธ์ (อ่านเมื่อเลือกโมเดลยาก ตั้งค่า หรือใช้ interactive)
- `references/task-sheet.md` — เทมเพลตใบงาน + ตัวอย่าง (อ่านก่อนเขียนใบงานแรกของ session)
- `references/model-roles.md` — โมเดลตามบทบาท dev (Architect/Tech Lead/Senior/Frontend-Reviewer/Escalation/QA/DevOps/Peer reviewer), ตาราง SDLC 9 ขั้น, สูตรทีม A/B/C, anti-patterns (อ่านเมื่อแบ่งงานหลายบทบาทหรือเลือกโมเดลไม่ลง)

## 1. Preflight ครั้งเดียวต่อ session

```bash
bash <skill-dir>/scripts/agy-run.sh preflight
```
ตรวจว่ามี `agy`, เวอร์ชัน, ล็อกอินแล้ว (ดึง `agy models` ได้ = ล็อกอินแล้ว) และรายชื่อ model slug ของบัญชีนี้ — **เชื่อผลนี้มากกว่าตารางใด ๆ** เพราะแต่ละบัญชี/เวลาต่างกัน
- ไม่มี agy → ให้ผู้ใช้ติดตั้งตามเอกสาร Antigravity (ถามก่อน) · ยังไม่ล็อกอิน → ผู้ใช้รัน `agy` เองครั้งแรกเพื่อล็อกอิน Google (Claude ไม่กรอกรหัสแทน)

## 2. เลือกโมเดล (effort อยู่ในชื่อ slug แล้ว เช่น `-low/-medium/-high/-xhigh`)

| งาน | slug เริ่มต้น |
|---|---|
| ถาม/สรุป/แก้คำผิด/สคริปต์สั้น/commit message/อ่านอย่างเดียว | `gemini-4-hydrogen-low` |
| เขียนเทสต์, boilerplate, UI component, บั๊กตรงไปตรงมา | `gemini-4-hydrogen-medium` |
| **coding จริงจังประจำวัน (ค่าเริ่มต้น)**, refactor หลายไฟล์, backend/API | `gemini-4-neon-medium` |
| ฟีเจอร์กลาง–ใหญ่หลายไฟล์ ไม่อยากสลับโมเดลเอง | `gemini-pro-orchestrator-neon` (Neon วางแผน → Hydrogen ลงมือ) |
| ฟีเจอร์ซับซ้อน/ดีบักยาก | `gemini-4-neon-high` |
| สถาปัตยกรรม, บั๊กข้ามระบบ, security audit (ใช้กับ `--mode plan`) | `gemini-4-argon-high` / `gemini-pro-orchestrator-g1-pro` |
| ติดหล่มจริง ต้องการมุมมองท็อป | `gemini-4-neon-xhigh` หรือ `claude-opus-5-5-high` — **ถามผู้ใช้ก่อน** (แพงมาก) |
| สไตล์โค้ดฝั่ง Claude, code review ประณีต, Frontend/TS | `claude-sonnet-5-5-medium` |
| second opinion ข้ามค่าย (คนละตระกูลโมเดล ลดจุดบอดร่วม) | `gpt-oss-120b-medium` (`--mode plan`) |
| CI/CD, commit message, changelog, YAML, shell/regex/SQL สั้น | `gemini-3.8-flash-low` (ถูกสุด) |

Opus/Neon-xhigh = **ปรึกษาเฉพาะจุด** (`--mode plan`) พอได้ root cause แล้วสลับกลับไปให้ Hydrogen/Neon-medium ลงมือแก้ · บั๊กเดิมแก้ 2–3 รอบไม่หลุด → เปลี่ยนค่าย/ระดับ (Neon → Sonnet/Opus หรือ Argon) พร้อมส่งสมมติฐานที่ตัดทิ้งแล้ว อย่าวนโมเดลเดิม

หลัก: เริ่มต่ำ ขยับขึ้นเมื่อมีหลักฐานว่าต้องการ · อย่าค้าง xhigh/Argon/Opus ทั้งวัน · งานใหญ่ใช้สูตร **Explore (Hydrogen/Neon-medium) → Plan (`--mode plan` ด้วย Neon-high/Argon) → Implement (Hydrogen/Neon-medium)** แยกเป็นรอบ ๆ แทนการโยนทั้งก้อน

## 3. เขียนใบงาน

โครง: เป้าหมาย / หลักฐาน (path, error) / ขอบเขต (ไฟล์ที่แก้ได้ + สิ่งที่ต้องรักษา) / เกณฑ์ผ่าน (อินพุต→ผล, กรณีขอบ) / การตรวจ (คำสั่งเทสต์) / ส่งมอบ (ไฟล์ที่แก้, คำสั่งที่รัน, ผลจริง, ไม่ commit) — รายละเอียดใน `references/task-sheet.md`
- ชี้ไฟล์ด้วย path (ใน interactive ใช้ `@path`) แทนแปะโค้ด
- สั่งให้ "เขียนไฟล์ด้วยเครื่องมือแก้ไฟล์ ไม่ใช้ shell" และบอกคำสั่งตรวจ (typecheck/test) ให้ครบ — โหมดปกติรันคำสั่งใดก็ได้ภายใน sandbox จึง**ไม่ต้องไล่ `--allow` ทีละโปรแกรม** แต่ไม่มีเครือข่าย: ใบงานต้องไม่พึ่ง `npm install`, `curl`, `git fetch/push` (หัวหน้าทำส่วนนั้นเองก่อนหรือหลัง)
- ถ้าใช้ `--strict` หรือ `--no-sandbox`: ระบุโปรแกรมที่อนุญาตในใบงานให้ตรงกับ `--allow` **รวมทุกโปรแกรมหลัง `|` `&&` `;`** (เช่น `tail`, `head`, `wc`) เพราะคำสั่งที่ถูกปฏิเสธครั้งเดียวจบทั้งรอบแบบว่างเปล่า
- agy เรียกแต่ละครั้งมี overhead ~10–13k tokens (system prompt) → **รวมงานที่เกี่ยวกันเป็นรอบเดียว** ดีกว่าเรียกถี่ ๆ แต่ยังคง 1 ผลลัพธ์/ชุดไฟล์ต่อรอบ

## 4. รัน

```bash
bash <skill-dir>/scripts/agy-run.sh run \
  --dir /path/to/repo \
  --model gemini-4-neon-medium \
  --mode accept-edits \                # plan = อ่าน/วางแผนอย่างเดียว
  --add-dir /path/outside/repo \       # โฟลเดอร์นอก repo ที่ต้องอ่าน/เขียน (ใบงาน, node_modules ที่ symlink ไป, .git หลักของ worktree)
  --timeout 600 \
  --task-file tasks/03-feature.md       # หรือ --prompt "..."
```

**สิทธิ์รันคำสั่ง 3 แบบ (ตรวจแล้วกับ agy 1.5.14):**

| แบบ | คำสั่ง shell | ใช้เมื่อ |
|---|---|---|
| ปกติ (ไม่ใส่ flag) | รันได้ทุกคำสั่ง **ภายใน sandbox**: ไม่มีเครือข่าย, เขียนนอก `--dir`/`--add-dir` ไม่ได้, อ่าน `~/.ssh` ไม่ได้ | งานแก้โค้ดที่ต้องวน typecheck/test เอง — ใช้แบบนี้เป็นหลัก |
| `--strict` | เฉพาะโปรแกรมใน `--allow` (ยังอยู่ใน sandbox) | งานอ่านอย่างเดียวที่อยากจำกัดให้แคบสุด |
| `--no-sandbox` | เฉพาะโปรแกรมใน `--allow` ไม่มี sandbox | ขั้นที่ต้องใช้เครือข่ายจริง ๆ — ปกติให้หัวหน้าทำเองดีกว่า |

ใน sandbox สคริปต์ตั้ง `DEVELOPER_DIR` และ `GIT_CONFIG_GLOBAL=/dev/null` ให้ ไม่งั้น `git` ทุกคำสั่งตายบน macOS (อ่าน xcode-select link และ config ที่ include จาก `~/.gitconfig` ไม่ได้) ผลข้างเคียงที่ตั้งใจ: agy ไม่มี identity จึง commit ไม่ได้ — commit เป็นหน้าที่หัวหน้า

สคริปต์จัดการให้: `-p` อยู่ท้ายสุดพร้อม prompt (agy ต้องการ `-p "<prompt>"` — แบบ `agy -p --model X "..."` จะ error), `--output-format stream-json`, `--print-timeout`, `--sandbox`, `< /dev/null`, สิทธิ์ผ่าน `--settings` เฉพาะ session (ไม่แตะ settings.json ของผู้ใช้), log NDJSON ใน `.agy-runs/` (ซ่อนจาก git status ผ่าน `.git/info/exclude`) แล้วพิมพ์ status, tokens, denied_actions, คำตอบ และ `git status/diff --stat`
- `denied_actions` ไม่ว่าง = มีคำสั่งถูกปฏิเสธและ**รอบนั้นจบทันที งานไม่ครบ** สคริปต์พิมพ์บรรทัดคำสั่งที่ถูกปฏิเสธให้ → โหมดปกติ: คำสั่งนั้นต้องออกนอก sandbox ให้เพิ่ม `--add-dir` หรือทำขั้นนั้นเอง · `--strict`/`--no-sandbox`: เพิ่ม `--allow` ให้ครบทุกโปรแกรมในคำสั่ง อย่ากระโดดไปใช้ `--dangerously-skip-permissions` (สคริปต์ไม่เปิดให้ใช้โดยตั้งใจ)
- งานยาว: รันแบบ background แล้วรอแจ้งเตือน · งานที่แตะไฟล์ต่างกันรันขนานได้ ไฟล์เดียวกันต้องรันต่อกัน

## 5. ตรวจงาน — Claude ตัดสิน

`response` ของ agy คือคำกล่าวอ้าง: ดู `git status --short` (รวมไฟล์ untracked) → `git diff --check` + อ่าน diff ที่เกี่ยว → **รันเทสต์เอง** → UI ให้ตรวจในเบราว์เซอร์จริง → รวมจุดที่ต้องแก้เป็นใบงานแก้รอบเดียว · commit เฉพาะเมื่อผู้ใช้สั่ง

รีวิว diff แบบถูก (second opinion):
```bash
git diff main...HEAD | agy --model gemini-4-neon-medium --mode plan --print-timeout 300s \
  -p "รีวิว diff นี้ เน้น bug, edge cases, security ตอบเป็นข้อ ๆ สั้น"
```

## 6. คุมโควตา

- preflight + `smoke` ก่อนงานใหญ่เมื่อเปลี่ยนโมเดล/เครื่อง
- เริ่ม Hydrogen/Neon-medium; Argon/Opus/xhigh เฉพาะจุดและบอกผู้ใช้ก่อน
- จด `usage.total_tokens` ของทุกรอบ (สคริปต์พิมพ์ให้) เทียบความคุ้มต่อประเภทงาน
- รอบที่สองยังไม่ผ่าน → หยุดวิเคราะห์สาเหตุก่อนสั่งรอบสาม
- ข้อมูลอ้างอิงจริง (พ.ย. 2026, แก้บั๊ก 2 ไฟล์ + เทสต์ งานเดียวกัน): agy Hydrogen-medium ≈29k tokens/36s vs Codex Sol-low ≈12k/24s — งานเล็กมากที่ Codex ว่างอยู่อาจคุ้มกว่า; agy เหมาะกับงานที่ต้องใช้โมเดลเฉพาะ (Orchestrator, Argon, Claude 5.5) หรือเมื่อโควตา Codex ตึง
- interactive: `/btw` ถามแทรกไม่บวม context, `/compact` จบเฟส, `/clear` งานใหม่, `/context` ดูขนาด

## 7. กับดักที่เจอจริง (agy 1.5.13–1.5.14)

| อาการ | สาเหตุ | ทางแก้ |
|---|---|---|
| `-p took "--model" as its prompt` | `-p` รับค่าเป็น prompt ทันที | ใส่ `-p "<prompt>"` ท้ายสุด (สคริปต์ทำให้) |
| `response` ว่าง + `denied_actions:[{"action":"command"}]` | headless ถามสิทธิ์ไม่ได้ → ปฏิเสธอัตโนมัติและจบรอบ มักเกิดจาก `npx … \| tail` ที่ `tail` ไม่อยู่ใน allow | ใช้โหมดปกติ (sandbox) แทน `--strict`; ดูบรรทัด "refused command(s)" ที่สคริปต์พิมพ์ |
| `git` ทุกคำสั่ง error `xcode-select … Operation not permitted` | sandbox กันการอ่าน xcode-select link และ config ที่ include | สคริปต์ตั้ง `DEVELOPER_DIR` + `GIT_CONFIG_GLOBAL` ให้แล้ว (ถ้าเรียก agy เองต้องตั้งเอง) |
| `--mode plan` ตอบว่า "สร้าง implementation_plan.md แล้ว" แทนคำตอบ | plan mode เขียนแผนลงโฟลเดอร์ของ agy | ใน prompt สั่งให้ "ตอบในข้อความ ไม่ต้องเขียนแผน" หรือใช้ `accept-edits` กับใบงานที่ระบุว่าห้ามแก้ไฟล์ |
| เทสต์เขียน cache ไม่ได้ / `git` เขียน index ไม่ได้ใน worktree | `node_modules` เป็น symlink ออกนอก repo หรือ `.git` จริงอยู่ที่ repo หลัก | เพิ่ม `--add-dir` ของโฟลเดอร์ปลายทาง |
| ค้างนาน | ไม่มี timeout | `--print-timeout` (สคริปต์ตั้งให้) |
| เขียนไฟล์ไม่ได้บน macOS | ~/Downloads, ~/Desktop, ~/Documents ถูก OS ปกป้อง | ทำงานใน ~/Projects หรือให้ผู้ใช้เปิดสิทธิ์เอง |
