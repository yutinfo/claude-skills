# codex-delegate — skill ส่วนตัวสำหรับ Claude Code

ช่วยให้ Claude สั่งงานเขียนโค้ดให้ OpenAI Codex CLI ได้เร็ว ตรวจสอบได้ และคุมโควตา รวมถึงงานสร้างภาพทุกชนิด เพราะในทีม Codex เป็นคนเดียวที่สร้างภาพได้

## ติดตั้ง

ติดตั้งทั้ง repo ด้วย `install.sh` ตาม [README หลัก](../../README.md#ติดตั้ง-macos--linux--wsl) แล้วตรวจเครื่อง:

```bash
~/.claude/skills/codex-delegate/scripts/codex-run.sh preflight
```

```bash
~/.claude/skills/codex-delegate/scripts/codex-run.sh smoke
```

ต้องมี: Claude Code, bash, git และ Codex CLI (`npm install -g @openai/codex` แล้วรัน `codex login`) · python3 ใช้อ่านรายชื่อโมเดล ไม่มีก็ยังใช้งานได้

ถ้าอยากให้ใช้เฉพาะโปรเจกต์เดียว ให้ติดตั้งด้วย `CLAUDE_SKILLS_DIR=<repo>/.claude/skills ./install.sh`

## ใช้งาน

เปิด Claude Code แล้วสั่งงานได้เลย เช่น "ให้ codex แก้บั๊ก X", "แบ่งงานนี้ให้ chat ทำ" หรือ "gen รูปสินค้า 12 ภาพ" skill จะทำงานเอง หรือจะเรียกตรง ๆ ด้วย `/codex-delegate` ก็ได้

ตัวเลือกของสคริปต์อยู่ใน [README หลัก](../../README.md#เรียกสคริปต์เอง)

## ไฟล์

- `SKILL.md` — ขั้นตอนหลัก: preflight → เลือกโมเดล → เขียนใบงาน → รัน → ตรวจ → คุมโควตา
- `references/codex-cli-guide.md` — คู่มือ Codex CLI ฉบับย่อ (ตรวจกับเวอร์ชัน 0.171.0)
- `references/task-sheet.md` — เทมเพลตใบงานพร้อมตัวอย่างที่ดีและไม่ดี
- `references/model-roles.md` — เลือกโมเดล Codex ตามบทบาทในทีม (Sol/Astra/Terra/Luna) การแบ่ง ticket และการส่งต่องาน
- `scripts/codex-run.sh` — ตัวช่วยที่ใช้ได้ทุกเครื่อง มี 3 คำสั่ง: `preflight`, `smoke`, `run`
