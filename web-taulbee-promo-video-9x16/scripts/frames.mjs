// Grabs still frames of the film through the export mode, for layout review.
// Usage: node scripts/frames.mjs <url> <outDir> <width> <height> <seconds...>
import { mkdir } from "node:fs/promises";

const [url, outDir, w, h, ...times] = process.argv.slice(2);
const { chromium } = await import(process.env.RORK_PLAYWRIGHT_MODULE ?? "/usr/local/lib/node_modules/playwright/index.mjs");
await mkdir(outDir, { recursive: true });
const browser = await chromium.launch();
const context = await browser.newContext({ viewport: { width: Number(w), height: Number(h) } });
// Hides the dev preview banner.
await context.addInitScript(() => { try { sessionStorage.setItem("rorkQA", "1"); } catch {} });
const page = await context.newPage();
const logs = [];
page.on("console", (m) => { if (/Motion|error/i.test(m.text())) logs.push(`${m.type()}: ${m.text().slice(0, 300)}`); });
page.on("pageerror", (e) => logs.push(`pageerror: ${e.message.slice(0, 300)}`));
await page.goto(`${url}${url.includes("?") ? "&" : "?"}render-video`, { waitUntil: "domcontentloaded" });
await page.waitForFunction(() => window.__rorkMotionRender, null, { timeout: 30000 });
const info = await page.evaluate(async () => {
  const i = await window.__rorkMotionRender.ready;
  return { duration: i.duration, chapters: i.chapters };
});
console.log(JSON.stringify(info));
for (const t of times) {
  await page.evaluate((f) => window.__rorkMotionRender.renderFrame(f), Math.round(Number(t) * 30));
  await page.screenshot({ path: `${outDir}/t${Number(t).toFixed(1).padStart(4, "0")}.png` });
}
console.log(logs.join("\n"));
await browser.close();
