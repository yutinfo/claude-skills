# agy-delegate — skill ส่วนตัวสำหรับ Claude Code

ช่วยให้ Claude สั่งงานให้ Google Antigravity CLI (`agy`) ในโหมด headless ได้ถูกต้อง ประหยัดโควตา และตรวจสอบได้ ใช้คู่กับ skill `codex-delegate` ได้ (งานสร้างภาพต้องใช้ `codex-delegate` เพราะ agy สร้างภาพไม่ได้)

## ติดตั้ง

ติดตั้งทั้ง repo ด้วย `install.sh` ตาม [README หลัก](../../README.md#ติดตั้ง-macos--linux--wsl) แล้วตรวจเครื่อง:

```bash
~/.claude/skills/agy-delegate/scripts/agy-run.sh preflight
```

```bash
~/.claude/skills/agy-delegate/scripts/agy-run.sh smoke
```

ต้องมี: Claude Code, bash, git และ agy ที่ login แล้ว (รัน `agy` ครั้งแรกเพื่อ login บัญชี Google) · python3 ใช้อ่านผล JSON ไม่มีก็ยังรันได้ ยกเว้น `stats` · Node 22+ กับ Chrome สำหรับ `web-shots.mjs` · `smoke` ทดสอบจริงหนึ่งบรรทัด ใช้ราว 10k tokens

## ใช้งาน

สั่งใน Claude Code ได้เลย เช่น "ให้ agy เขียนเทสต์ให้โมดูล X", "ให้ฝั่ง Google รีวิว diff" หรือ "agy เหลือโควตาเท่าไร" หรือเรียกตรง ๆ ด้วย `/agy-delegate`

ตัวเลือกของสคริปต์ สิทธิ์รันคำสั่ง 3 แบบ และวิธีใช้ `web-shots.mjs` อยู่ใน [README หลัก](../../README.md#เรียกสคริปต์เอง)

## ไฟล์

- `SKILL.md` — ขั้นตอนหลัก, ตารางเลือกโมเดล, การรัน, การตรวจ, งานที่มีหน้าจอ, การคุมโควตา, ปัญหาที่เคยเจอ
- `references/agy-cli-guide.md` — คู่มือ agy ฉบับย่อ (flags, subcommands, slash commands, settings, โมเดล, กลยุทธ์) แก้ส่วนที่คู่มือต้นฉบับผิดแล้ว
- `references/task-sheet.md` — เทมเพลตใบงานแบบที่เหมาะกับข้อจำกัดเรื่องสิทธิ์ของ agy และช่องบังคับของงานที่มีหน้าจอ
- `references/model-roles.md` — เลือกโมเดล agy ตามบทบาท dev, ตาราง SDLC, สูตรทีม และ anti-patterns
- `scripts/agy-run.sh` — ตัวช่วยที่ใช้ได้ทุกเครื่อง มี 5 คำสั่ง: `preflight`, `smoke`, `quota`, `stats`, `run`
- `scripts/web-shots.mjs` — ถ่ายภาพหน้าเว็บตลอดการเลื่อนหลายขนาดจอ ทำ contact sheet และจับหน้าล้นแนวนอนกับ console error
