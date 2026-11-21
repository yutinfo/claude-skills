# agy-delegate — skill ส่วนตัวสำหรับ Claude Code

ช่วยให้ Claude สั่งงานให้ Google Antigravity CLI (`agy`) ในโหมด headless ได้ถูกต้อง ประหยัดโควตา และตรวจสอบได้ ใช้คู่กับ skill `codex-delegate` ได้

## ติดตั้งบนเครื่องอื่น
ต้องมี: Claude Code, bash, git, python3 (ใช้อ่านผล JSON ถ้าไม่มีก็ยังรันได้) และ agy ที่ login แล้ว (รัน `agy` ครั้งแรกเพื่อ login บัญชี Google)

```bash
mkdir -p ~/.claude/skills
unzip agy-delegate.zip -d ~/.claude/skills/
chmod +x ~/.claude/skills/agy-delegate/scripts/agy-run.sh
bash ~/.claude/skills/agy-delegate/scripts/agy-run.sh preflight
bash ~/.claude/skills/agy-delegate/scripts/agy-run.sh smoke     # ทดสอบจริง 1 บรรทัด (~10k tokens)
```

## ใช้งาน
สั่งใน Claude Code ได้เลย เช่น "ให้ agy เขียนเทสต์ให้โมดูล X" หรือ "ให้ฝั่ง Google รีวิว diff" หรือเรียกตรงๆ ด้วย `/agy-delegate`

## ไฟล์
- `SKILL.md` — ขั้นตอนหลัก, ตารางเลือกโมเดล, การรัน, การตรวจ, การคุมโควตา, ปัญหาที่เคยเจอ
- `references/agy-cli-guide.md` — คู่มือ agy ฉบับย่อ (flags, subcommands, slash commands, settings, โมเดล, กลยุทธ์) แก้ส่วนที่คู่มือต้นฉบับผิดแล้ว
- `references/task-sheet.md` — เทมเพลตใบงานแบบที่เหมาะกับข้อจำกัดเรื่องสิทธิ์ของ agy
- `scripts/agy-run.sh` — ตัวช่วยที่ใช้ได้ทุกเครื่อง มี 3 คำสั่ง: `preflight`, `smoke`, `run`
