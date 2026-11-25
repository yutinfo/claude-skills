# claude-skills

skill ส่วนตัวสำหรับ Claude Code ใช้ตอนให้ Claude เป็น **หัวหน้าทีม** สั่งงาน AI CLI ตัวอื่น: Claude แตกงาน เขียนใบงาน สั่งรัน แล้วตรวจผลเองด้วย diff และเทสต์จริง ส่วน CLI อีกตัวเป็นคนลงมือ เป้าหมายคืองานจบในรอบน้อยที่สุดและใช้โควตาน้อยที่สุด

| skill | สั่งงานให้ | เหมาะกับ |
|---|---|---|
| [`codex-delegate`](skills/codex-delegate/) | OpenAI Codex CLI (`codex exec` / `codex review`) | งานเขียนโค้ดทั่วไป, รีวิว PR, ตรวจ UI จากภาพหน้าจอ และ **งานสร้างภาพทุกชนิด** |
| [`agy-delegate`](skills/agy-delegate/) | Google Antigravity CLI (`agy`) แบบ headless | งานที่ต้องใช้โมเดลเฉพาะ (Gemini 4, Orchestrator, Claude 5.5), ความเห็นที่สองข้ามค่าย, ค้นเว็บ, หรือเมื่อโควตา Codex ตึง |

> งานสร้างภาพ (รูปสินค้า ภาพประกอบ ไอคอนหรือโลโก้แบบ raster) ส่งให้ Codex เสมอ เพราะ agy สร้างภาพไม่ได้ agy ทำได้แค่เปิดอ่านภาพ และเขียนภาพเป็นโค้ด (SVG/CSS) เมื่อใบงานสั่งไว้ชัด

## ติดตั้ง (macOS / Linux / WSL)

```bash
git clone https://github.com/yutinfo/claude-skills.git ~/Projects/claude-skills
```

```bash
cd ~/Projects/claude-skills && ./install.sh --check
```

จากนั้นเปิด session ใหม่ของ Claude Code เพื่อให้โหลด skill

`install.sh` สร้าง symlink จาก `~/.claude/skills/<ชื่อ>` มาที่ repo นี้ ครั้งหน้าที่ skill มีการแก้ไข แค่ `git pull` ก็อัปเดตแล้ว

| คำสั่ง | ผล |
|---|---|
| `./install.sh` | ลิงก์ทุก skill ใน `skills/` |
| `./install.sh --check` | ลิงก์ แล้วรัน preflight ของแต่ละ skill ว่าเครื่องนี้มี `codex` / `agy` ที่ login แล้วหรือยัง |
| `./install.sh --copy` | คัดลอกแทนการลิงก์ สำหรับเครื่องที่สร้าง symlink ไม่ได้ (ต้องรันซ้ำทุกครั้งหลัง `git pull`) |
| `CLAUDE_SKILLS_DIR=<โฟลเดอร์> ./install.sh` | ติดตั้งไปที่อื่นแทน `~/.claude/skills` เช่น `<repo>/.claude/skills` เพื่อใช้เฉพาะโปรเจกต์เดียว |

ถ้าปลายทางมีโฟลเดอร์ชื่อเดียวกันอยู่แล้ว สคริปต์จะย้ายของเดิมไปไว้ที่ `skills-backup/` ข้างโฟลเดอร์ปลายทางก่อน (ปกติคือ `~/.claude/skills-backup/`)

### สิ่งที่ต้องมีในแต่ละเครื่อง

| เครื่องมือ | ใช้กับ | หมายเหตุ |
|---|---|---|
| Claude Code, bash 3.2+, git | ทั้งสอง skill | |
| Codex CLI | `codex-delegate` | `npm install -g @openai/codex` แล้ว `codex login` |
| agy | `agy-delegate` | ติดตั้งตาม https://antigravity.google/docs/getting-started แล้วรัน `agy` หนึ่งครั้งเพื่อ login |
| python3 | ทั้งสอง skill | ใช้อ่านรายชื่อโมเดลและสรุปผล JSON ไม่มีก็ยังรันได้ ยกเว้น `agy-run.sh stats` ที่ต้องมี |
| Node 22+ และ Chrome | `web-shots.mjs` | ไม่ต้อง `npm install` อะไรเพิ่ม ถ้าหา Chrome ไม่เจอให้ตั้ง `CHROME=/path/to/chrome` |

การ login ต้องทำเองทุกเครื่อง Claude ไม่กรอกรหัสผ่านหรือ API key แทน

## วิธีใช้งาน

### สั่งผ่าน Claude Code (ทางหลัก)

พิมพ์สั่งเป็นภาษาปกติ skill จะทำงานเองเมื่อพูดถึง Codex, agy หรือการแบ่งงานให้ AI ตัวอื่น หรือจะเรียกตรง ๆ ด้วย `/codex-delegate` และ `/agy-delegate` ก็ได้

| อยากได้ | ตัวอย่างคำสั่ง |
|---|---|
| ให้ Codex เขียนโค้ด | "ให้ codex แก้บั๊กราคาเป็นศูนย์ในตะกร้า" · "แบ่งงานนี้ให้ chat ทำ" |
| ให้ Codex สร้างภาพ | "gen รูปสินค้า 12 ภาพสไตล์เดียวกัน ขนาด 1024x1024" |
| ให้ Codex รีวิว | "ให้ codex review งานที่ยังไม่ commit" |
| ให้ agy เขียนโค้ด | "ให้ agy เขียนเทสต์ให้โมดูล X" · "ให้ gem ทำ refactor นี้" |
| ให้ agy รีวิวเป็นความเห็นที่สอง | "ให้ฝั่ง Google รีวิว diff ของ branch นี้" |
| ดูโควตาและต้นทุน | "agy เหลือโควตาเท่าไร" · "งานนี้ใช้ token ไปเท่าไร" |
| ใช้ทั้งสองฝั่ง | "ให้ codex ทำภาพ แล้วให้ agy ทำหน้าเว็บที่ใช้ภาพชุดนั้น" |

### สิ่งที่ Claude ทำในแต่ละงาน

1. **Preflight** ครั้งเดียวต่อ session: ตรวจว่า CLI ติดตั้งและ login แล้ว และบัญชีนี้ใช้โมเดลไหนได้
2. **เลือกโมเดล** ให้พอดีงาน เริ่มจากระดับต่ำแล้วขยับขึ้นเมื่อมีหลักฐานว่าจำเป็น โมเดลแพงจะถามผู้ใช้ก่อน
3. **เขียนใบงาน** เป็นไฟล์ `tasks/NN-ชื่อ.md` ใน repo ของงาน: เป้าหมาย, หลักฐาน, ขอบเขตไฟล์, เกณฑ์ผ่าน, คำสั่งตรวจ, สิ่งที่ต้องส่งมอบ งานที่มีหน้าจอใช้เทมเพลต UI ที่มีกรอบตัวเลขวัดได้
4. **รัน** ผ่านสคริปต์ของ skill ซึ่งใส่ flag ให้ถูก ตั้ง sandbox และ timeout แล้วเก็บ log
5. **ตรวจเอง**: `git status`, อ่าน diff, รันเทสต์เอง และดูหน้าจอจริงถ้าเป็นงาน UI รายงานของลูกทีมถือเป็นคำกล่าวอ้าง ยังไม่ใช่หลักฐาน
6. **รวมจุดที่ต้องแก้เป็นใบแก้ใบเดียว** ถ้ารอบที่สองยังไม่ผ่าน จะหยุดวิเคราะห์สาเหตุก่อนสั่งรอบที่สาม
7. **commit เฉพาะเมื่อผู้ใช้สั่ง**

### เรียกสคริปต์เอง

ใช้ได้โดยไม่ต้องผ่าน Claude เช่นตอนตรวจเครื่องใหม่หรือดูโควตา ตัวอย่างข้างล่างใช้ path หลังติดตั้งแล้ว

**Codex** — `~/.claude/skills/codex-delegate/scripts/codex-run.sh`

```bash
~/.claude/skills/codex-delegate/scripts/codex-run.sh preflight
```

```bash
~/.claude/skills/codex-delegate/scripts/codex-run.sh smoke
```

```bash
~/.claude/skills/codex-delegate/scripts/codex-run.sh run \
  --dir ~/Projects/my-app \
  --model gpt-6.2-sol --effort medium \
  --sandbox workspace-write \
  --task-file tasks/03-fix-zero-price.md
```

| คำสั่ง / ตัวเลือก | ความหมาย |
|---|---|
| `preflight [--model <slug>]` | เวอร์ชัน, สถานะ login, โมเดลที่บัญชีใช้ได้, โมเดลใน `~/.codex/config.toml` ยังใช้ได้ไหม |
| `smoke [--model <slug>]` | ส่ง prompt บรรทัดเดียวเพื่อพิสูจน์ว่า login และโมเดลใช้ได้จริง |
| `run --dir <repo>` | ต้องมี `--task-file <ไฟล์>` หรือ `--prompt "<ข้อความ>"` |
| `--model` / `--effort` | ค่าเริ่มต้น `gpt-6.2-sol` / `medium` (`minimal`, `low`, `medium`, `high`, `xhigh`) |
| `--sandbox` | `workspace-write` (ค่าเริ่มต้น) หรือ `read-only` สำหรับสำรวจ รีวิว วางแผน |
| `--image <ไฟล์>` | แนบภาพหน้าจอ ใส่ซ้ำได้หลายภาพ |
| `--worktree` | รันใน worktree แยก ใช้เมื่อหลายงานแตะไฟล์เดียวกัน |
| `--json` | ให้ Codex บันทึก event เป็น JSON ลง log |
| `--log-dir <โฟลเดอร์>` | เปลี่ยนที่เก็บ log (ค่าเริ่มต้น `<repo>/.codex-runs/`) |

**agy** — `~/.claude/skills/agy-delegate/scripts/agy-run.sh`

```bash
~/.claude/skills/agy-delegate/scripts/agy-run.sh preflight
```

```bash
~/.claude/skills/agy-delegate/scripts/agy-run.sh quota
```

```bash
~/.claude/skills/agy-delegate/scripts/agy-run.sh run \
  --dir ~/Projects/my-app \
  --model gemini-4-neon-medium \
  --mode accept-edits \
  --timeout 1500 \
  --task-file tasks/03-feature.md
```

```bash
~/.claude/skills/agy-delegate/scripts/agy-run.sh stats --dir ~/Projects/my-app
```

| คำสั่ง / ตัวเลือก | ความหมาย |
|---|---|
| `preflight [--model <slug>]` | เวอร์ชัน, สถานะ login, รายชื่อ model slug ของบัญชีนี้ |
| `smoke [--model <slug>]` | ทดสอบจริงหนึ่งบรรทัด ใช้ราว 10k tokens |
| `quota` | เปอร์เซ็นต์โควตาที่เหลือและเวลารีเซ็ตของแต่ละกลุ่มโมเดล (Gemini / Claude+GPT / Argon) |
| `stats --dir <repo>` | สรุป token และเวลาแยกรอบและแยกโมเดล จาก log ใน `.agy-runs/` |
| `run --dir <repo>` | ต้องมี `--task-file <ไฟล์>` หรือ `--prompt "<ข้อความ>"` |
| `--model` / `--mode` | ค่าเริ่มต้น `gemini-4-neon-medium` / `accept-edits` (`plan` = อ่านและวางแผนอย่างเดียว, `auto`) |
| `--timeout <วินาที>` | เพดานเวลา ค่าเริ่มต้น 1500 ใบงานใหญ่ใช้จริง 7–18 นาที ไม่ควรตั้งต่ำกว่านี้ |
| `--add-dir <โฟลเดอร์>` | โฟลเดอร์นอก repo ที่ต้องอ่านหรือเขียน ใส่ซ้ำได้ |
| `--strict` / `--no-sandbox` / `--allow <โปรแกรม>` | เปลี่ยนสิทธิ์รันคำสั่ง ดูตารางถัดไป |
| `--log-dir <โฟลเดอร์>` | เปลี่ยนที่เก็บ log (ค่าเริ่มต้น `<repo>/.agy-runs/`) |

สิทธิ์รันคำสั่ง shell ของ agy มี 3 แบบ:

| แบบ | คำสั่งที่รันได้ | ใช้เมื่อ |
|---|---|---|
| ปกติ (ไม่ใส่ flag) | ทุกคำสั่ง แต่อยู่ใน sandbox: ไม่มีเครือข่าย และเขียนนอก `--dir` / `--add-dir` ไม่ได้ | งานแก้โค้ดที่ต้องวน typecheck และเทสต์เอง ใช้แบบนี้เป็นหลัก |
| `--strict` | เฉพาะโปรแกรมใน `--allow` (ยังอยู่ใน sandbox) | งานอ่านอย่างเดียวที่อยากจำกัดให้แคบที่สุด |
| `--no-sandbox` | เฉพาะโปรแกรมใน `--allow` ไม่มี sandbox | ขั้นที่ต้องใช้เครือข่ายจริง ๆ ปกติให้หัวหน้าทำเองดีกว่า |

ใน sandbox ไม่มีเครือข่าย ใบงานจึงต้องไม่พึ่ง `npm install`, `curl`, `git fetch` หรือ `git push` ขั้นพวกนี้ทำเองก่อนหรือหลังรัน

**ถ่ายภาพหน้าเว็บ** — `~/.claude/skills/agy-delegate/scripts/web-shots.mjs`

ใช้ตรวจงานที่มีหน้าจอ เพราะเทสต์ผ่านไม่ได้แปลว่าภาพถูก สคริปต์ถ่ายภาพตลอดการเลื่อนหน้าในหลายขนาดจอ ทำภาพรวม (contact sheet) และรายงานหน้าล้นแนวนอนกับ error ใน console

```bash
node ~/.claude/skills/agy-delegate/scripts/web-shots.mjs \
  --url http://localhost:5173/ --out tasks/shots-01 \
  --sizes 1440x900,1024x768,844x390,390x844 --stops 12
```

| ตัวเลือก | ความหมาย |
|---|---|
| `--url` / `--out` | หน้าที่จะถ่าย และโฟลเดอร์เก็บภาพ (บังคับทั้งคู่) |
| `--sizes` | ขนาดจอคั่นด้วยจุลภาค ค่าเริ่มต้น `1440x900,390x844` |
| `--stops <N>` | จำนวนจุดหยุดจากบนสุดถึงล่างสุด ค่าเริ่มต้น 12 (0 = ถ่ายเฉพาะ `--at`) |
| `--at '<selector>@0.5'` | จุดหยุดเพิ่มตามตำแหน่งของ element (0–1 ตามความสูง หรือ `@end` = ท้ายหน้า) คั่นหลายจุดด้วยจุลภาค |
| `--wait` / `--settle` | มิลลิวินาทีที่รอหลังโหลดหน้า (4000) และหลังเลื่อนแต่ละจุด (1500) |
| `--reduced-motion` / `--no-webgl` | ถ่ายซ้ำในโหมดลดการเคลื่อนไหว หรือปิด WebGL |

ได้ไฟล์ `<กว้าง>x<สูง>-<จุด>.jpg` ต่อจุดหยุด และ `sheet-<กว้าง>x<สูง>.jpg` ต่อขนาดจอ ดู contact sheet ก่อน แล้วค่อยเปิดภาพเต็มเฉพาะจุดที่สงสัย

### log และไฟล์ที่เกิดใน repo ของงาน

- ใบงานอยู่ที่ `tasks/` ของ repo นั้น เก็บไว้ตรวจย้อนหลังและใช้ซ้ำได้
- log ของแต่ละรอบอยู่ที่ `.codex-runs/` และ `.agy-runs/` สคริปต์ซ่อนสองโฟลเดอร์นี้จาก `git status` ผ่าน `.git/info/exclude` โดยไม่แตะ `.gitignore` ของโปรเจกต์
- ภาพจาก `web-shots.mjs` ควรใส่ `.gitignore` เอง และแยกโฟลเดอร์ต่อรอบ (เช่น `tasks/shots-01`, `tasks/shots-02`)

### ปัญหาที่เจอบ่อย

| อาการ | ทางแก้ |
|---|---|
| Claude ไม่เรียก skill | เปิด session ใหม่หลังติดตั้ง แล้วตรวจว่า `~/.claude/skills/` มีลิงก์ของทั้งสอง skill |
| `codex not found` / `agy not found` | ติดตั้ง CLI ตามตารางข้างบน (`agy` อยู่ที่ `~/.local/bin` สคริปต์เพิ่ม PATH ให้เอง) |
| preflight บอกว่ายังไม่ login | รัน `codex login` หรือ `agy` เองหนึ่งครั้ง |
| โมเดลไม่อยู่ในรายการของบัญชี | ใช้ slug ที่ preflight แสดง รายชื่อโมเดลต่างกันตามบัญชีและเวลา ให้เชื่อ preflight มากกว่าตารางในเอกสาร |
| agy จบรอบด้วยคำตอบว่างและมี `denied_actions` | มีคำสั่งถูกปฏิเสธ รอบนั้นจบทันทีและงานไม่ครบ ดูบรรทัด "refused command(s)" ที่สคริปต์พิมพ์ แล้วเพิ่ม `--add-dir` หรือทำขั้นนั้นเอง |
| เขียนไฟล์ไม่ได้บน macOS | `~/Downloads`, `~/Desktop`, `~/Documents` ถูก OS ปกป้อง ให้ทำงานใน `~/Projects` |

กับดักอื่น ๆ ที่เจอจริงอยู่ท้ายไฟล์ `SKILL.md` ของแต่ละ skill

## โครงสร้าง repo

```text
install.sh                      ลิงก์หรือคัดลอก skill เข้า ~/.claude/skills
skills/
  codex-delegate/
    SKILL.md                    ขั้นตอนหลักที่ Claude อ่าน
    references/
      codex-cli-guide.md        คู่มือ Codex CLI ฉบับย่อ
      task-sheet.md             เทมเพลตใบงาน พร้อมตัวอย่างที่ดีและไม่ดี
      model-roles.md            เลือกโมเดลตามบทบาทในทีม
    scripts/codex-run.sh        preflight / smoke / run
  agy-delegate/
    SKILL.md
    references/
      agy-cli-guide.md          คู่มือ agy ฉบับย่อ
      task-sheet.md             เทมเพลตใบงาน และช่องบังคับของงานที่มีหน้าจอ
      model-roles.md            เลือกโมเดลตามบทบาท dev
    scripts/
      agy-run.sh                preflight / smoke / quota / stats / run
      web-shots.mjs             ถ่ายภาพหน้าเว็บตลอดการเลื่อน
```

## แก้ skill

แก้ไฟล์ใน `skills/<ชื่อ>/` ได้เลย เครื่องที่ติดตั้งแบบ symlink จะเห็นผลทันที จากนั้น `git commit` / `git push` แล้วเครื่องอื่นแค่ `git pull` (เครื่องที่ติดตั้งด้วย `--copy` ต้องรัน `./install.sh --copy` ซ้ำ)

## ถอนการติดตั้ง

ลบลิงก์ใน `~/.claude/skills/` ออก ตัว repo ไม่ถูกแตะ (ถ้าติดตั้งด้วย `--copy` ปลายทางเป็นโฟลเดอร์จริง ให้ลบโฟลเดอร์นั้นแทน)

```bash
rm ~/.claude/skills/codex-delegate ~/.claude/skills/agy-delegate
```
