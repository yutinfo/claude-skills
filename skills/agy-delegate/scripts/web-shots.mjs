#!/usr/bin/env node
// web-shots.mjs — screenshot a page down its whole scroll at several sizes, in real headless Chrome. No npm deps (Node 22+).
//
//   node web-shots.mjs --url http://localhost:5180/ --out shots [--sizes 1440x900,390x844] [--stops 12]
//                      [--at "#c4@0.5,#specs@end"] [--wait 4000] [--settle 1500] [--reduced-motion] [--no-webgl]
//
// --stops N  N evenly spaced stops from top to bottom (default 12; 0 = only --at).
// --at       extra stops: selector@fraction of that element's height (or @end = bottom of the page).
// Writes one JPEG per stop, plus sheet-<size>.jpg (contact sheet). Prints horizontal overflow and console errors.
// Set CHROME=/path/to/chrome if it is not found.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path';

const argv = process.argv.slice(2), opt = { sizes: '1440x900,390x844', stops: '12', wait: '4000', settle: '1500', at: '' };
for (let i = 0; i < argv.length; i++) {
  const k = argv[i].replace(/^--/, '');
  if (k === 'reduced-motion' || k === 'no-webgl') opt[k] = true;
  else if (['url', 'out', 'sizes', 'stops', 'at', 'wait', 'settle'].includes(k) && argv[i + 1] !== undefined) opt[k] = argv[++i];
  else { console.error(`error: bad argument ${argv[i]}`); process.exit(2); }
}
if (!opt.url || !opt.out) { console.error('error: --url and --out are required'); process.exit(2); }
const sizes = opt.sizes.split(',').map(s => s.split('x').map(Number));
if (sizes.some(([w, h]) => !(w > 0 && h > 0))) { console.error('error: --sizes must look like 1440x900,390x844'); process.exit(2); }

const onPath = n => { try { return execFileSync('which', [n], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim(); } catch { return ''; } };
const chrome = [process.env.CHROME, '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', '/Applications/Chromium.app/Contents/MacOS/Chromium',
  onPath('google-chrome'), onPath('chromium'), onPath('chromium-browser')].find(p => p && fs.existsSync(p));
if (!chrome) { console.error('error: Chrome not found; set CHROME=/path/to/chrome'); process.exit(2); }

fs.mkdirSync(opt.out, { recursive: true });
const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'web-shots-')), sleep = ms => new Promise(r => setTimeout(r, ms));
const flags = ['--headless=new', '--remote-debugging-port=0', `--user-data-dir=${profile}`, '--no-first-run', '--hide-scrollbars'];
if (opt['no-webgl']) flags.push('--disable-gpu', '--disable-3d-apis'); else if (process.platform === 'darwin') flags.push('--use-angle=metal');
const proc = spawn(chrome, [...flags, 'about:blank'], { stdio: 'ignore' });
let failed = false;
try {
  let port, page;
  for (let i = 0; i < 80 && !page; i++) {
    try {
      port ??= fs.readFileSync(path.join(profile, 'DevToolsActivePort'), 'utf8').split('\n')[0];
      page = (await (await fetch(`http://127.0.0.1:${port}/json`)).json()).find(t => t.type === 'page');
    } catch { await sleep(250); }
  }
  if (!page) throw new Error('Chrome did not start');
  const ws = new WebSocket(page.webSocketDebuggerUrl); await new Promise((ok, no) => { ws.onopen = ok; ws.onerror = no; });
  let id = 0; const pending = new Map(), errors = new Set();
  ws.onmessage = ev => {
    const m = JSON.parse(ev.data);
    if (m.id) { const p = pending.get(m.id); pending.delete(m.id); m.error ? p.no(new Error(m.error.message)) : p.ok(m.result); return; }
    if (m.method === 'Runtime.exceptionThrown') errors.add('exception: ' + (m.params.exceptionDetails.exception?.description ?? m.params.exceptionDetails.text).slice(0, 300));
    if (m.method === 'Runtime.consoleAPICalled' && ['error', 'warning'].includes(m.params.type))
      errors.add(`${m.params.type}: ` + m.params.args.map(a => a.value ?? a.description ?? '').join(' ').slice(0, 300));
    if (m.method === 'Network.responseReceived' && m.params.response.status >= 400) errors.add(`HTTP ${m.params.response.status}: ${m.params.response.url}`);
  };
  const send = (method, params = {}) => new Promise((ok, no) => { pending.set(++id, { ok, no }); ws.send(JSON.stringify({ id, method, params })); });
  const run = async expression => {
    const r = await send('Runtime.evaluate', { expression, returnByValue: true });
    if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description ?? r.exceptionDetails.text);
    return r.result.value;
  };
  const shoot = async file => fs.writeFileSync(file, Buffer.from((await send('Page.captureScreenshot', { format: 'jpeg', quality: 82 })).data, 'base64'));
  await send('Page.enable'); await send('Runtime.enable'); await send('Network.enable');
  if (opt['reduced-motion']) await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });

  for (const [w, h] of sizes) {
    await send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: w < 700 });
    const nav = await send('Page.navigate', { url: opt.url });
    if (nav.errorText) throw new Error(`${opt.url}: ${nav.errorText}`);
    await sleep(+opt.wait);
    const stops = [], n = +opt.stops;
    for (let i = 0; i < n; i++) stops.push({ name: String(i).padStart(2, '0'), js: `(document.documentElement.scrollHeight-innerHeight)*${n > 1 ? i / (n - 1) : 0}` });
    for (const a of opt.at.split(',').filter(Boolean)) {
      const cut = a.lastIndexOf('@'), sel = cut < 0 ? a : a.slice(0, cut), f = cut < 0 ? '0' : a.slice(cut + 1);
      stops.push({ name: `${sel}-${f}`.replace(/[^\w.-]+/g, ''), js: f === 'end' ? '1e7'
        : `(e=>{if(!e)throw new Error('no element '+${JSON.stringify(sel)});const r=e.getBoundingClientRect();return r.top+scrollY+r.height*${Number(f)}})(document.querySelector(${JSON.stringify(sel)}))` });
    }
    const shots = []; let overflow = 0; // against the device width: mobile innerWidth grows with the content and would hide it
    for (const s of stops) {
      try { await run(`scrollTo({top:${s.js},behavior:'instant'})`); }
      catch (e) { failed = true; console.error(`  skipped stop ${s.name}: ${e.message.split('\n')[0]}`); continue; }
      await sleep(+opt.settle);
      overflow = Math.max(overflow, await run('document.documentElement.scrollWidth') - w);
      const file = path.join(opt.out, `${w}x${h}-${s.name}.jpg`); await shoot(file); shots.push(file);
    }
    console.log(`${w}x${h}: ${shots.length} shots, horizontal overflow ${overflow > 0 ? overflow + 'px  <-- FIX' : 'none'}`);
    if (shots.length) {
      const cols = w > h ? 3 : 6, tw = w > h ? 480 : 240, th = Math.round(tw * h / w), rows = Math.ceil(shots.length / cols);
      const imgs = shots.map(f => `<figure><img src="data:image/jpeg;base64,${fs.readFileSync(f).toString('base64')}"><figcaption>${path.basename(f, '.jpg')}</figcaption></figure>`).join('');
      const html = `<style>body{margin:0;background:#222;color:#fff;font:12px sans-serif;display:grid;grid-template-columns:repeat(${cols},${tw}px)}figure{margin:0}img{width:${tw}px;height:${th}px;display:block}figcaption{height:20px;padding:2px 6px;box-sizing:border-box}</style>${imgs}`;
      await send('Page.navigate', { url: 'about:blank' });
      await send('Emulation.setDeviceMetricsOverride', { width: cols * tw, height: rows * (th + 20), deviceScaleFactor: 1, mobile: false });
      const { frameTree } = await send('Page.getFrameTree');
      await send('Page.setDocumentContent', { frameId: frameTree.frame.id, html }); await sleep(800);
      const sheet = path.join(opt.out, `sheet-${w}x${h}.jpg`); await shoot(sheet); console.log(`  contact sheet: ${sheet}`);
    }
  }
  console.log(errors.size ? `console/network problems (${errors.size}):\n  ` + [...errors].slice(0, 12).join('\n  ') : 'console/network problems: none');
  ws.close();
} catch (e) { failed = true; console.error('error: ' + e.message); }
finally {
  const gone = new Promise(r => proc.once('exit', r)); proc.kill(); await Promise.race([gone, sleep(3000)]);
  try { fs.rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 }); } catch {}
}
process.exit(failed ? 1 : 0);
