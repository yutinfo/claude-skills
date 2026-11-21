# codex-delegate — skill ส่วนตัวสำหรับ Claude Code

ช่วยให้ Claude สั่งงานเขียนโค้ดให้ OpenAI Codex CLI ได้เร็ว ตรวจสอบได้ และคุมโควตา

## ติดตั้งบนเครื่องอื่น

ต้องมี: Claude Code, bash, git, python3 (ใช้อ่านรายชื่อโมเดล ถ้าไม่มีก็ยังใช้งานได้) และ Codex CLI (`npm install -g @openai/codex` แล้วรัน `codex login`)

**macOS / Linux / WSL**
```bash
mkdir -p ~/.claude/skills
unzip codex-delegate.zip -d ~/.claude/skills/
chmod +x ~/.claude/skills/codex-delegate/scripts/codex-run.sh
bash ~/.claude/skills/codex-delegate/scripts/codex-run.sh preflight
```

ถ้าอยากให้ใช้เฉพาะโปรเจกต์เดียว ให้แตกไฟล์ไว้ที่ `<repo>/.claude/skills/` แทน

## ใช้งาน
เปิด Claude Code แล้วสั่งงานได้เลย เช่น "ให้ codex แก้บั๊ก X" หรือ "แบ่งงานนี้ให้ chat ทำ" skill จะทำงานเอง หรือจะเรียกตรงๆ ด้วย `/codex-delegate` ก็ได้

## ไฟล์
- `SKILL.md` — ขั้นตอนหลัก: preflight → เลือกโมเดล → เขียนใบงาน → รัน → ตรวจ → คุมโควตา
- `references/codex-cli-guide.md` — คู่มือ Codex CLI ฉบับย่อ (ตรวจกับเวอร์ชัน 0.171.0)
- `references/task-sheet.md` — เทมเพลตใบงานพร้อมตัวอย่างที่ดีและไม่ดี
- `references/model-roles.md` — เลือกโมเดล Codex ตามบทบาทในทีม (Sol/Astra/Terra/Luna) การแบ่ง ticket และการส่งต่องาน
- `scripts/codex-run.sh` — ตัวช่วยที่ใช้ได้ทุกเครื่อง มี 3 คำสั่ง: `preflight`, `smoke`, `run`
