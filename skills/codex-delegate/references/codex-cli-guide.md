# Codex CLI — คู่มืออ้างอิง

ตรวจรูปแบบคำสั่งกับ Codex CLI 0.171.0 (พ.ย. 2026) ถ้าเวอร์ชันบนเครื่องต่างออกไป ให้เชื่อ `codex <cmd> --help` มากกว่าไฟล์นี้

## สารบัญ
1. ติดตั้งและลงชื่อเข้าใช้
2. โมเดล ความเร็ว และเครดิต
3. Workflow ตั้งแต่ prompt ถึง commit
4. Config และ AGENTS.md
5. คำสั่งประจำวัน
6. Automation / CI
7. ความต่างระหว่าง interactive กับ exec (ตรวจแล้ว)

## 1. ติดตั้งและลงชื่อเข้าใช้

```bash
npm install -g @openai/codex      # ต้องมี Node.js + npm
codex --version
codex login                       # เปิดเบราว์เซอร์ ลงชื่อด้วย ChatGPT
codex login --device-auth         # เครื่องที่เข้าผ่าน SSH (ถ้าบัญชีรองรับ)
codex login status                # ยืนยันว่าใช้วิธีที่ตั้งใจ
codex doctor --summary            # ตรวจติดตั้ง/config/auth/runtime
```

ChatGPT login ใช้สิทธิ์และโควตาของแพ็กเกจ; API key (`codex login --with-api-key` อ่านจาก stdin) คิดตามอัตรา OpenAI Platform

เปิดแบบ interactive ใน repo:

```bash
cd /path/to/repo && git status --short --branch
codex -m gpt-6.2-sol -c 'model_reasoning_effort="medium"' -s workspace-write -a on-request
```

`-s read-only` สำหรับสำรวจ/อธิบายอย่างเดียว; พิมพ์ `/status` เพื่อดู working dir, โมเดล, สิทธิ์

## 2. โมเดล ความเร็ว และเครดิต

| ลักษณะงาน | จุดเริ่มต้น |
|---|---|
| เล็ก กติกาชัด ตรวจง่าย | GPT‑6 Luna หรือ GPT‑6.2 Sol ที่ Light/Low |
| พัฒนาทั่วไป | GPT‑6.2 Sol ที่ Medium |
| หลายไฟล์ ไล่เหตุผลต่อเนื่อง | GPT‑6.2 Sol ที่ High |
| หลายสมมติฐาน/ผลกระทบสูง | GPT‑6.2 Astra เริ่ม Medium |

- reasoning effort = ความพยายามคิด; Standard / Fast / Ultrafast = ความเร็ว (เน้นโควตา → Standard)
- `/model` เลือกรุ่น+ระดับ, `/fast` สลับ fast (ตรวจสถานะก่อน)
- อัตรา Standard: **Sol 50 เครดิต/1M input, 250/1M output**; **Astra 200 / 1,000** (แพงกว่า ~4×); Sol แบบ Fast ใช้โควตา ~2× ของ Standard
- ต้นทุนต่องานขึ้นกับบริบท reasoning และผลจากเครื่องมือ ดูจริงจาก usage dashboard หรือ `/statusline`
- วัดความคุ้ม: จด "เวลาจนเทสต์ผ่านและพร้อมรีวิว" + จำนวนรอบแก้เพิ่ม ต่อประเภทงาน ถ้า Luna จบในรอบเดียวซ้ำ ๆ ใช้กับงานกลุ่มนั้น ถ้า Sol วนหลายรอบเพราะไม่เข้าใจ dependency ข้ามโมดูล ลอง Astra ตั้งแต่ขั้นวิเคราะห์ครั้งหน้า
- slug โมเดลจริงของบัญชีดูได้จาก `~/.codex/models_cache.json` (สคริปต์ preflight อ่านให้)

ประหยัดโควตา:
- ส่งหลักฐานตรงจุด (path, ฟังก์ชัน, คำสั่งที่พัง, error สำคัญ) ให้ Codex อ่านโค้ดเอง; ตัดข้อมูลลับออกจาก log
- แบ่งงานตามผลลัพธ์ แต่ละรอบมี diff และผลทดสอบที่ตรวจง่าย
- รันเทสต์เจาะจุดก่อน ค่อยขยาย
- interactive: `/compact` เมื่อทำงานเดิมต่อหลังแชตยาว, `/new` เมื่อเปลี่ยนเรื่อง
- ติดแล้วค่อยขยับระดับ พร้อมสรุปอาการ + สมมติฐานที่ตัดทิ้ง + คำสั่งที่ลอง

## 3. Workflow ตั้งแต่ prompt ถึง commit

1. เช็กจุดเริ่ม `git status --short --branch`; มีงานเดิมปน → ระบุไฟล์ที่ต้องรักษา หรือใช้ `codex --worktree` (งานที่ยังไม่ commit อาจต้องนำเข้า worktree เอง)
2. กำหนดเกณฑ์ผ่าน; งานหลายทางเลือกใช้ `/plan` (หรือ exec แบบ read-only ให้เสนอแผน) ก่อนลงมือ
3. ทดสอบก่อนและหลัง: บั๊ก → เทสต์ใหม่ล้มก่อน ผ่านหลัง; ฟีเจอร์ → กรณีปกติ + กรณีขอบในสัญญาของฟังก์ชัน/API
4. รีวิว diff และผลเทสต์ รวมไฟล์ใหม่จาก `git status`
5. Stage รายไฟล์ แล้ว `git diff --cached` ก่อน commit

```bash
git status --short
git diff --stat
git diff --check
git diff
git diff --cached
codex review --uncommitted        # หรือ --base main / --commit <sha>
```

## 4. Config และ AGENTS.md

`~/.codex/config.toml` (คีย์ระดับบนต้องอยู่ก่อนหัวตาราง เช่น `[projects]`; แก้คีย์เดิมแทนการเพิ่มซ้ำ):

```toml
model = "gpt-6.2-sol"
model_reasoning_effort = "medium"
sandbox_mode = "workspace-write"
approval_policy = "on-request"
```

ลำดับความสำคัญ: flag/`-c` > `.codex/config.toml` ของโปรเจกต์ (เฉพาะโปรเจกต์ที่ trusted) > config ผู้ใช้; นโยบาย workspace อาจจำกัดตัวเลือก — **Claude ไม่แก้ config ของผู้ใช้เองโดยไม่ถาม**

`AGENTS.md` ที่ราก repo (หรือ `/init` สร้างร่าง) — เก็บเฉพาะสิ่งที่ต้องอธิบายซ้ำ: setup, วิธีทดสอบ, ตำแหน่งโมดูล, สัญญาที่ต้องรักษา Codex ประกอบคำแนะนำจากระดับผู้ใช้ → รากโปรเจกต์ → ลงมาถึง working dir; ถ้าต้องใช้กติกาของ `packages/web/AGENTS.md` เริ่มด้วย `codex -C packages/web`

```markdown
# AGENTS.md
## Project
- Use Node.js 22 and native ES modules.
## Verification
- Run `node --test <file>` when editing <module>; run `node --test` before completing.
- Report the test commands and results.
## Working agreements
- Preserve existing user edits. Add a regression test for user-visible bugs.
```

## 5. คำสั่งประจำวัน

| ที่ไหน | คำสั่ง | ใช้เมื่อ |
|---|---|---|
| ใน Codex | `/model`, `/status` | เปลี่ยนโมเดล / ตรวจสถานะ |
| ใน Codex | `/plan`, `/review`, `/diff` | วางแผน / รีวิว / ดู diff |
| ใน Codex | `/mention` | ชี้ไฟล์ให้อ่าน |
| ใน Codex | `/compact`, `/new` | ย่อบริบท / เริ่มแชตใหม่ |
| Terminal | `codex resume`, `codex resume --last` | ทำต่อจากแชตเก่า |
| Terminal | `codex --worktree`, `git worktree list` | งานแยก checkout |
| Terminal | `codex doctor --summary` | วินิจฉัยการติดตั้ง |
| Terminal | `codex apply` | apply diff ล่าสุดของ agent เป็น `git apply` |

แก้ปัญหา: หาโมเดล/คำสั่งไม่เจอ → `codex --version`, พิมพ์ `/`, ตรวจสิทธิ์บัญชี · ไฟล์ที่แก้ไม่โผล่ → ดู working dir จาก `/status` · เทสต์ติด dependency/network → ดู error จริง อนุมัติเฉพาะที่จำเป็น ถ้ายังไม่ได้ให้บันทึกคำสั่ง+error · แชตยาวหลุดขอบเขต → ย้ำสิ่งที่ต้องรักษาและเกณฑ์ผ่าน

## 6. Automation / CI

```bash
codex exec -s read-only -m gpt-6.2-sol -c 'model_reasoning_effort="medium"' \
  "อ่าน git status และ diff ทั้ง staged และ unstaged แล้วสรุปสิ่งที่เปลี่ยน จุดที่ควรทดสอบ และคำถามก่อน merge ตอบเป็น Markdown" < /dev/null
```

- `--json` → event แบบ JSONL ให้สคริปต์อ่าน
- `--output-schema <file>` → บังคับโครงคำตอบสุดท้าย
- `-o, --output-last-message <file>` → บันทึกเฉพาะคำตอบสุดท้าย
- ให้ exit code ของ lint/test/build ตัดสินผล CI; รายงาน Codex เป็นข้อมูลประกอบ
- GitHub Actions: ใช้ Codex GitHub Action ตามคู่มือ จำกัดสิทธิ์ job และแยก API key จากขั้นที่รันโค้ดที่ยังไม่ตรวจ

## 7. ความต่าง interactive vs exec (ตรวจกับ 0.171.0)

- `codex exec` **ไม่มี `-a`** — ไม่มีการถามอนุมัติ; คำสั่งที่ sandbox ปฏิเสธจะ fail กลับไปให้โมเดล
- `--search` (web search) มีใน interactive เท่านั้น ไม่มีใน exec
- `codex exec` มี: `-m`, `-c`, `-s`, `-C/--cd`, `--worktree`, `--add-dir`, `-i/--image` (รับหลายค่า → ใส่ `--` ก่อน prompt), `--skip-git-repo-check`, `--ephemeral`, `--json`, `--output-schema`, `-o`
- `codex review` มี `--uncommitted`, `--base`, `--commit`, `--title`, `-c` แต่ **ไม่มี `-m`** → `-c model="..."`
- exec อ่าน stdin ถ้าไม่ได้ปิด → ใส่ `< /dev/null` เสมอเมื่อส่ง prompt เป็นอาร์กิวเมนต์
