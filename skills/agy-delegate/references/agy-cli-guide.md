# Antigravity CLI (`agy`) — คู่มืออ้างอิง

ตรวจกับ agy 1.5.13 (พ.ย. 2026) — ถ้าเวอร์ชันบนเครื่องต่างไป ให้เชื่อ `agy --help` มากกว่าไฟล์นี้ ส่วนที่ระบุว่า **[ตรวจแล้ว]** ทดสอบจริงในโหมด headless

## สารบัญ
1. เริ่มต้น · 2. Flags · 3. Subcommands · 4. Slash commands · 5. settings.json · 6. โมเดลและ effort · 7. กลยุทธ์ประหยัด · 8. Cheat sheet · 9. แหล่งข้อมูล

## 1. เริ่มต้น
```bash
cd /path/to/project && agy          # ครั้งแรกจะเปิดเบราว์เซอร์ล็อกอิน Google (SSH จะแสดงลิงก์)
agy update                          # ปกติอัปเดตอัตโนมัติ
```
`@path` ในแชตชี้ไฟล์/โฟลเดอร์ให้อ่านตรงจุด · ออก: `/exit`, `/quit`, Ctrl+D สองครั้ง

agy ต่างจาก `gemini` CLI: รองรับหลายตระกูลโมเดล (Gemini 4, Orchestrator, Claude 5.5, GPT-OSS) และมี Orchestrator, Swarm, Plugins, Skills, Rules, Hooks, Remote Agent, Checkpoints (`/rewind`, `/fork`)

## 2. Flags (จาก `agy --help` 1.5.13)

| Flag | ความหมาย |
|---|---|
| `--model <slug>` | โมเดลเฉพาะ session (slug มี effort อยู่แล้ว เช่น `gemini-4-neon-medium`) |
| `--effort <low\|medium\|high\|xhigh\|max>` | ระดับการคิดของ session |
| `--mode <plan\|accept-edits\|auto>` | plan = วางแผน/อ่านอย่างเดียว, accept-edits = อนุมัติแก้ไฟล์อัตโนมัติ, auto = ทำงานอัตโนมัติ |
| `-c`, `--continue` / `--conversation <id>` | ต่อแชตล่าสุด / แชตตาม ID |
| `--add-dir <path>` | เพิ่มโฟลเดอร์เข้า workspace (ซ้ำได้) |
| `-i`, `--prompt-interactive <prompt>` | ส่ง prompt แรกแล้วเข้า TUI ต่อ |
| `-p`, `--print <prompt>` (`--prompt`) | headless: รันหนึ่ง prompt พิมพ์ผลแล้วจบ — **[ตรวจแล้ว] prompt ต้องเป็นค่าของ `-p` ทันที** |
| `--print-timeout <dur>` | เวลาสูงสุดของ print mode (เช่น `300s`; 0 = รอจนจบ) |
| `--output-format <text\|json\|stream-json>` | รูปแบบผล print mode — json มี `status`, `response`, `usage`, `denied_actions` **[ตรวจแล้ว]** |
| `--input-format <text\|stream-json>` | stream-json อ่าน NDJSON ทีละบรรทัดจาก stdin (ต้องคู่กับ output stream-json) |
| `--json-schema <schema\|path>` | บังคับโครงผลลัพธ์สุดท้าย |
| `--sandbox` | จำกัดสิทธิ์ terminal |
| `--settings <json\|path>` | settings เฉพาะ session ไม่บันทึกทับ — ใช้ใส่ `permissions.allow` ชั่วคราว **[ตรวจแล้ว]** |
| `--dangerously-skip-permissions` | อนุมัติทุกเครื่องมือ — เฉพาะสภาพแวดล้อมทดสอบ/CI ที่ไว้ใจได้ |
| `--disable-slash-commands` | ปิด slash command/skill expansion ใน print mode |
| `--agent`, `--project`, `--new-project`, `--remote-agent`, `--remote-control`, `--log-file` | เลือก agent/project, remote, log |

## 3. Subcommands
`agy models` (รายชื่อ slug ที่บัญชีใช้ได้) · `agy mcp add|remove|list|enable|disable` · `agy plugin list|install|uninstall|enable|disable` · `agy plugin import [gemini|claude]` (นำเข้าการตั้งค่าจาก Gemini CLI/Claude Code) · `agy agents` · `agy remote-control start|status|stop` · `agy changelog` · `agy update` · `agy acp` (ACP stdio server) · `agy install` (ตั้ง PATH/shell)

## 4. Slash commands (TUI)
- วางแผน/ควบคุม: `/plan`, `/fast`, `/goal` (ทำต่อจนสำเร็จ), `/swarm` (แตกงานให้หลาย agent)
- โมเดล/context: `/model`, `/effort [..]`, `/compact [คำสั่งต่อยอด]`, `/context`, `/btw <คำถาม>` (ถามแทรกไม่บวมประวัติหลัก)
- session/checkpoint: `/rewind` (`/undo`), `/fork` (`/branch`), `/resume`, `/clear` (`/new`)
- ตั้งค่า: `/config` (`/settings`), `/mcp`, `/skills`, `/hooks`, `/antigravity-guide`, `/help`

## 5. settings.json
ไฟล์หลัก: `~/.gemini/antigravity-cli/settings.json` (หรือ `/config`) — **Claude ไม่แก้ไฟล์นี้เองโดยไม่ถาม** ใช้ `--settings` เฉพาะ session แทน
```json
{
  "model": "gemini-4-neon-medium",
  "agentMode": "plan",
  "toolPermission": "proceed-in-sandbox",
  "historySize": 2000,
  "permissions": { "allow": ["command(git status)", "command(git diff)", "command(npm test)"] }
}
```
รูปแบบ allow: `command(<prefix>)` — **[ตรวจแล้ว]** `command(node)` อนุญาต `node --test`; ส่วน `command(node --test)` อย่างเดียวไม่พอเมื่อโมเดลพยายามใช้ shell เขียนไฟล์ก่อน → สั่งให้ใช้ file tool

## 6. โมเดลและ effort
| ตระกูล | slug | จุดเด่น / เหมาะกับ |
|---|---|---|
| Orchestrator (Neon) ⭐ | `gemini-pro-orchestrator-neon` | Neon วางแผน + Hydrogen ลงมือ ในเซสชันเดียว คุ้มมากสำหรับฟีเจอร์กลาง–ใหญ่หลายไฟล์ |
| Orchestrator (Argon) | `gemini-pro-orchestrator-g1-pro` | Argon วางแผน + Hydrogen ลงมือ งานสถาปัตยกรรมซับซ้อนที่ต้องแก้มาก |
| Gemini 4 Hydrogen | `-low/-medium/-high/-xhigh` | เร็วและประหยัดที่สุดในตระกูล Gemini 4: boilerplate, unit test, บั๊กตรงไปตรงมา, UI component |
| Gemini 4 Neon ⭐ | `-low/-medium/-high/-xhigh` | sweet spot สำหรับ coding จริงจัง, refactor ข้ามไฟล์, debug ซับซ้อน, backend/API |
| Gemini 4 Argon | `-low/-medium/-high` | flagship คิดลึก: architecture, race condition, security audit (ใช้โควตาสูง) |
| Gemini 3.8 Flash | `-low/-medium/-high` | เร็ว ถูก: สคริปต์อัตโนมัติ `-p`, งานซ้ำ |
| Claude Sonnet 5.5 | `claude-sonnet-5-5-low/-medium/-high` | โค้ดสะอาด แม่น: refactor ประณีต, code review, Frontend/TS |
| Claude Opus 5.5 | `claude-opus-5-5-low/-medium/-high` | ท็อปฝั่ง Claude แต่โควตาสูงมาก: งานยากที่ตัวอื่นแก้ไม่หลุด |
| GPT-OSS 120B | `gpt-oss-120b-medium` | ทางเลือก/second opinion |

Effort: `low` = งานง่าย/ถามตอบ · **`medium` = ค่าเริ่มต้น 70–80% ของงาน** · `high` = ฟีเจอร์ซับซ้อน/refactor/ดีบักยาก · `xhigh` = เฉพาะจุด (สถาปัตยกรรมใหญ่, บั๊กระดับระบบ, security) · เปิด xhigh/Argon/Opus ค้างไว้คือสาเหตุอันดับหนึ่งที่ช้าและโควตาหมด

การตัดสินใจเร็ว: งานเล็ก/1–2 ไฟล์/เทสต์ → Hydrogen low–medium · ฟีเจอร์กลาง–ใหญ่ → Orchestrator-neon (หรือ Neon medium–high/Sonnet medium ถ้าอยากคุมเอง) · สถาปัตยกรรม/บั๊กยาก → Argon high หรือ Neon xhigh/Opus (plan) แล้วสลับกลับ Hydrogen/Neon medium ตอนลงมือ

## 7. กลยุทธ์ประหยัด
1. Orchestrator-neon เป็น default สำหรับงานฟีเจอร์ (ไม่ต้องสลับโมเดลเอง)
2. Explore → Plan → Implement แยกรอบ แทนโยนโจทย์ใหญ่ให้แก้เลย (การวนแก้ผิดทางเปลือง 3–5 เท่า)
3. วินัย context: ชี้ด้วย `@`/path, `/btw` คำถามนอกเรื่อง, `/compact` จบเฟส, `/clear` งานใหม่, บอกคำสั่งเทสต์ใน prompt เสมอ
4. headless: overhead ~10–13k tokens/ครั้ง **[ตรวจแล้ว]** → รวมงานที่เกี่ยวกันเป็นรอบเดียว

## 8. Cheat sheet (แก้ลำดับ `-p` ให้ถูกแล้ว)
| สถานการณ์ | คำสั่ง |
|---|---|
| coding ประจำวัน | `agy --model gemini-4-neon-medium` |
| ฟีเจอร์กลาง–ใหญ่ | `agy --model gemini-pro-orchestrator-neon` |
| เทสต์/boilerplate | `agy --model gemini-4-hydrogen-medium` |
| ถามไว/สคริปต์สั้น | `agy --model gemini-4-hydrogen-low` |
| refactor ประณีต | `agy --model claude-sonnet-5-5-medium` |
| architecture/บั๊กยาก | `agy --model gemini-4-argon-high --mode plan` |
| ติดหล่มหนัก | `agy --model claude-opus-5-5-high --mode plan` |
| commit message จาก diff | `git diff --staged \| agy --model gemini-4-hydrogen-low --print-timeout 120s -p "สรุปเป็น conventional commit message ภาษาอังกฤษ 1 บรรทัด"` |
| รีวิว diff | `git diff main...HEAD \| agy --model gemini-4-neon-medium --mode plan --print-timeout 300s -p "รีวิว diff เน้น bug, edge cases, security"` |

ตัวอย่าง interactive: เปิด `--mode plan` ด้วย Neon-high → `วิเคราะห์ @src/routes/orders.ts และ @src/services/orderService.ts แล้ววางแผน...` → ตรวจแผน → `/model` สลับ Hydrogen/Neon medium ให้ลงมือ+รันเทสต์ → `/clear` ก่อนงานถัดไป · ทดลองสองแนวทาง: `/fork` → ลองแนวทาง 1 → ไม่เวิร์ก `/rewind` หรือ `/resume` กลับกิ่งเดิม

## 9. แหล่งข้อมูล
https://antigravity.google/docs/getting-started · https://antigravity.google/docs/cli/reference · https://antigravity.google/docs/cli/best-practices · https://antigravity.google/llms.txt
