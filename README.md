# claude-skills

skill ส่วนตัวสำหรับ Claude Code ใช้ตอนให้ Claude เป็นหัวหน้าทีมสั่งงาน AI CLI ตัวอื่น

| skill | ใช้ทำอะไร |
|---|---|
| `codex-delegate` | สั่งงานให้ OpenAI Codex CLI (`codex exec` / `codex review`) |
| `agy-delegate` | สั่งงานให้ Google Antigravity CLI (`agy`) แบบ headless |

## ติดตั้งบนเครื่องใหม่ (macOS / Linux / WSL)

```bash
git clone <URL ของ repo นี้> ~/Projects/claude-skills
cd ~/Projects/claude-skills && ./install.sh --check
```

`install.sh` จะสร้าง symlink จาก `~/.claude/skills/<ชื่อ>` มาที่ repo นี้ ครั้งหน้าที่ skill มีการแก้ไข แค่รัน `git pull` ก็อัปเดตแล้ว ส่วน `--check` จะรัน preflight ให้ด้วยว่าเครื่องนี้มี `codex` / `agy` ที่ login แล้วหรือยัง ถ้าเป็นเครื่องที่สร้าง symlink ไม่ได้ ให้ใช้ `--copy` แทน

สิ่งที่ต้องทำเองในแต่ละเครื่อง เพราะ skill ทำแทนไม่ได้:
- Codex: `npm install -g @openai/codex` แล้ว `codex login`
- agy: ติดตั้งตามขั้นตอนใน https://antigravity.google/docs/getting-started แล้วรัน `agy` เพื่อ login
- python3: ใช้อ่านรายชื่อโมเดลและผล JSON ถ้าไม่มีก็ยังรันได้

## แก้ skill
แก้ไฟล์ใน `skills/<ชื่อ>/` ได้เลย (เครื่องที่ติดตั้งแบบ symlink จะเห็นผลทันที) แล้ว `git commit` / `git push` จากนั้นเครื่องอื่นแค่ `git pull`
