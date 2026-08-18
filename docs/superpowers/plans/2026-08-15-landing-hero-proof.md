# Landing Hero + Proof Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the landing's storyboard placeholders with an outcome-first Hero, a real autoplay demo, and four complementary product screenshots.

**Architecture:** Keep the existing single-page Astro composition and editorial visual system. Media lives under `landing/src/assets/` and is resolved at build time; `Hero.astro` owns the video and its small progressive-enhancement script, `Gallery.astro` owns static screenshot data and rendering, and `Base.astro` reuses the demo poster for social metadata. No dependency, route, backend, or application-state change is introduced.

**Tech Stack:** Astro 5.18, TypeScript in `.astro` files, local WebM/MP4/WebP assets, CSS, browser-native `<video>`, IntersectionObserver.

## Global Constraints

- Preserve Sendoff's prompt-first positioning; do not add a feature catalogue or repeat the README.
- Keep Newsreader + Commit Mono, the violet/ember palette, and the current one-page section order.
- UI copy is English; source comments and commit messages are Russian.
- No external media/font requests, analytics, routes, dependencies, custom video player, or gallery lightbox.
- `CoreLoop.astro`, `Boundary.astro`, `Scope.astro`, and `Footer.astro` remain unchanged.
- Use the seeded fictional demo profile only. Close the working Sendoff instance before capture; no real tabs, prompts, paths, or workspaces may appear.
- Keep native video controls. Normal motion autoplays only while visible; reduced motion and no-JavaScript modes remain manually playable.
- Missing final media must fail the Astro build. Visible placeholders and Russian shooting notes block publication.
- Relevant project gate: `cd landing && bun run build`.
- Landing has no component-test harness. Do not add snapshot tests for static copy; use build-time imports, deterministic source checks, and bounded desktop/mobile browser verification.
- Codex execution stops before commits. The architect owns the commit checkpoints below.
- Task 1 Step 2 writes outside the repository workspace and requires explicit filesystem approval before execution.

---

## File Map

### External media workspace

- Modify: `/home/ex1te/Videos/rewrite-demo-assets/record.sh` — recognize the renamed Sendoff window and point to the real encoding script.
- Reuse: `/home/ex1te/Videos/rewrite-demo-assets/build.sh` — encode the new raw take into WebM, MP4, and GIF while preserving the measured range correction.
- Reuse: `/home/ex1te/Videos/rewrite-demo-assets/demo-seed.json` — populate the isolated demo profile.

### Repository files

- Create: `landing/src/assets/demo/sendoff-demo.webm` — preferred landing video.
- Create: `landing/src/assets/demo/sendoff-demo.mp4` — browser fallback video.
- Create: `landing/src/assets/demo/sendoff-demo-poster.webp` — informative poster and social image.
- Create: `landing/src/assets/gallery/target-picker.webp` — wide target picker shot.
- Create: `landing/src/assets/gallery/workspaces.webp` — focused workspace/tab crop.
- Create: `landing/src/assets/gallery/slash-menu.webp` — focused slash-menu crop.
- Create: `landing/src/assets/gallery/reference.webp` — wide reference-panel shot.
- Modify: `landing/src/components/Hero.astro` — outcome-first copy, real video, playback behavior, accessible description.
- Modify: `landing/src/components/Gallery.astro` — real images and approved detail copy.
- Modify: `landing/src/layouts/Base.astro` — Open Graph and Twitter image metadata from the poster.
- Modify: `landing/src/styles/global.css` — WCAG-AA faint text and reduced-motion caret behavior.
- Modify: `HANDOFF.md` — restore current session state, verification, and remaining publication work; remains ignored.
- Review only: `docs/superpowers/specs/2026-08-15-landing-hero-proof-design.md` — approved design source of truth.

---

### Task 1: Produce the isolated demo and gallery assets

**Files:**

- Modify outside repo: `/home/ex1te/Videos/rewrite-demo-assets/record.sh:5,22-24,67`
- Create: `landing/src/assets/demo/sendoff-demo.webm`
- Create: `landing/src/assets/demo/sendoff-demo.mp4`
- Create: `landing/src/assets/demo/sendoff-demo-poster.webp`
- Create: `landing/src/assets/gallery/target-picker.webp`
- Create: `landing/src/assets/gallery/workspaces.webp`
- Create: `landing/src/assets/gallery/slash-menu.webp`
- Create: `landing/src/assets/gallery/reference.webp`

**Interfaces:**

- Consumes: `demo-seed.json`, a closed working Sendoff instance, the renamed window app id containing `sendoff`, and live demo targets for Herdr, Orca, and tmux.
- Produces: two silent 1280×720 video sources, one 1280×720 poster, two 1600×900 wide shots, and two 1200×900 focused crops at the exact paths above.

- [ ] **Step 1: Prove the recorder still contains the stale name**

Run:

```bash
rg -n "rewrite|Rewrite|encode\.sh" /home/ex1te/Videos/rewrite-demo-assets/record.sh
```

Expected: matches for the window predicate, error/output copy, and stale `encode.sh` instruction. This is the known precondition; do not start recording while these matches remain.

- [ ] **Step 2: Repair the external recording helper**

Apply this exact logical change to `/home/ex1te/Videos/rewrite-demo-assets/record.sh`:

```diff
-# и это переключение попало бы в кадр. Пишем с запасом, лишнее срежет encode.sh.
+# и это переключение попало бы в кадр. Пишем с запасом, лишнее срежет build.sh.
@@
-    if 'rewrite' in (w.get('app_id') or '').lower(): print(w['id']); break
+    if 'sendoff' in (w.get('app_id') or '').lower(): print(w['id']); break
@@
-[ -n "${WID:-}" ] || { echo "Окно Rewrite не найдено — запусти демо-профиль." >&2; exit 1; }
+[ -n "${WID:-}" ] || { echo "Окно Sendoff не найдено — запусти демо-профиль." >&2; exit 1; }
@@
-echo "окно Rewrite id=$WID, выход $OUTPUT, длительность ${DUR}с"
+echo "окно Sendoff id=$WID, выход $OUTPUT, длительность ${DUR}с"
@@
-echo "Дальше: ./encode.sh [начало] [длительность] [x:y:w:h]"
+echo "Дальше: измерь секунды Ctrl+Enter и ответа, затем запусти build.sh с SEND и ANSWER"
```

This file is outside the repository and is not staged or committed.

- [ ] **Step 3: Verify the helper syntax and stale-name removal**

Run:

```bash
bash -n /home/ex1te/Videos/rewrite-demo-assets/record.sh
if rg -n "rewrite|Rewrite|encode\.sh" /home/ex1te/Videos/rewrite-demo-assets/record.sh; then
  echo "stale recorder marker remains" >&2
  exit 1
fi
```

Expected: `bash -n` exits 0 and the stale-marker check prints nothing.

- [ ] **Step 4: Start an isolated demo profile**

Close the working Sendoff instance first. From the repository root, create an isolated XDG root and start the app:

```bash
sendoff_demo_xdg="$(mktemp -d /tmp/sendoff-landing-demo.XXXXXX)"
printf '%s\n' "$sendoff_demo_xdg" > /tmp/sendoff-demo-root-path
mkdir -p "$sendoff_demo_xdg/data" "$sendoff_demo_xdg/config"
XDG_DATA_HOME="$sendoff_demo_xdg/data" \
XDG_CONFIG_HOME="$sendoff_demo_xdg/config" \
bun dev
```

In the isolated app, import `/home/ex1te/Videos/rewrite-demo-assets/demo-seed.json`. Confirm the visible tab titles, workspace names, group names, and prompt bodies are fictional. Prepare live Herdr, Orca, and tmux demo targets so the target picker can show all three sections.

- [ ] **Step 5: Record a fresh manual take**

Keep `showmethekey` outside the Sendoff frame. In a second terminal, prove the repaired predicate sees the live window, then record:

```bash
niri msg --json windows | python3 -c "
import json,sys
for w in json.load(sys.stdin):
    if 'sendoff' in (w.get('app_id') or '').lower():
        print(w['id'])
        break
"
cd /home/ex1te/Videos/rewrite-demo-assets
./record.sh 60
```

Type the structured multi-line prompt manually, let list continuation appear naturally, press `Ctrl+Enter`, and wait until the agent begins its reply. Do not automate the typing: the existing Wayland setup does not carry modifier chords through `wtype`.

Expected: the predicate prints exactly one window id; `raw.mkv` points to a new numbered take; the final `ffprobe` output reports 1920×1080 and a duration near 60 seconds.

- [ ] **Step 6: Measure send and answer timestamps, then encode**

Review the raw take with visible playback time:

```bash
cd /home/ex1te/Videos/rewrite-demo-assets
ffplay -stats raw.mkv
```

Record the exact second when `Ctrl+Enter` is pressed and the exact second when the answer is fully visible. Capture the measured values and pass them to the existing encoder:

```bash
read -r -p "Ctrl+Enter second: " sendoff_send_second
read -r -p "Answer-visible second: " sendoff_answer_second
printf '%s %s\n' "$sendoff_send_second" "$sendoff_answer_second" > /tmp/sendoff-demo-timings
SEND="$sendoff_send_second" ANSWER="$sendoff_answer_second" SPEED=3 LAND=2.3 WAITSPEED=1 TAIL=4 ./build.sh
```

Expected: `build.sh` produces `rewrite-demo.webm`, `rewrite-demo.mp4`, and `rewrite-demo.gif`; WebM/MP4 show corrected blacks, accelerate only typing, and keep prompt landing plus agent response at real speed.

- [ ] **Step 7: Copy the final videos and derive an informative poster**

Create the asset directories, copy the two browser sources, and derive the poster timestamp from the middle of the real-speed prompt-landing segment:

```bash
mkdir -p landing/src/assets/demo landing/src/assets/gallery
cp /home/ex1te/Videos/rewrite-demo-assets/rewrite-demo.webm landing/src/assets/demo/sendoff-demo.webm
cp /home/ex1te/Videos/rewrite-demo-assets/rewrite-demo.mp4 landing/src/assets/demo/sendoff-demo.mp4
read -r sendoff_send_second sendoff_answer_second < /tmp/sendoff-demo-timings
sendoff_poster_second="$(python3 -c "print(float('$sendoff_send_second') / 3 + 1.0)")"
ffmpeg -hide_banner -loglevel error -y \
  -ss "$sendoff_poster_second" \
  -i landing/src/assets/demo/sendoff-demo.mp4 \
  -frames:v 1 -vf "scale=1280:720:flags=lanczos" \
  -c:v libwebp -quality 84 \
  landing/src/assets/demo/sendoff-demo-poster.webp
```

Inspect the extracted poster. It must show the editor and the receiving terminal together during prompt landing. If the derived frame catches a transition, choose another frame inside the same 2.3-second real-speed landing segment; do not use an empty editor or a completed-answer frame.

- [ ] **Step 8: Capture the four approved gallery states**

With the isolated demo profile still open, arrange and capture these exact states:

1. `Ctrl+Shift+Enter`: target picker showing Herdr, Orca, and tmux sections.
2. Tab strip with a colour-coded group and pin visible, plus workspace picker open.
3. `/` menu open at the caret inside a fictional prompt.
4. Editor on the left and a fictional agent reply in the reference panel on the right.

For each state, select a tight region around the relevant UI:

```bash
grim -g "$(slurp)" /tmp/sendoff-target-picker.png
grim -g "$(slurp)" /tmp/sendoff-workspaces.png
grim -g "$(slurp)" /tmp/sendoff-slash-menu.png
grim -g "$(slurp)" /tmp/sendoff-reference.png
```

Normalize the wide shots to 16:9 and the focused shots to 4:3 without stretching:

```bash
magick /tmp/sendoff-target-picker.png -resize '1600x900^' -gravity center -extent 1600x900 -quality 84 landing/src/assets/gallery/target-picker.webp
magick /tmp/sendoff-workspaces.png -resize '1200x900^' -gravity center -extent 1200x900 -quality 84 landing/src/assets/gallery/workspaces.webp
magick /tmp/sendoff-slash-menu.png -resize '1200x900^' -gravity center -extent 1200x900 -quality 84 landing/src/assets/gallery/slash-menu.webp
magick /tmp/sendoff-reference.png -resize '1600x900^' -gravity center -extent 1600x900 -quality 84 landing/src/assets/gallery/reference.webp
```

If centered cropping cuts the named UI state, recapture a tighter centered region rather than changing the final aspect ratio.

- [ ] **Step 9: Stop the isolated app and remove temporary capture files**

Stop `bun dev` with `Ctrl+C`. Then validate the recorded temporary root before removing it:

```bash
read -r sendoff_demo_xdg < /tmp/sendoff-demo-root-path
case "$sendoff_demo_xdg" in
  /tmp/sendoff-landing-demo.*) rm -rf -- "$sendoff_demo_xdg" ;;
  *) echo "refusing unexpected demo root: $sendoff_demo_xdg" >&2; exit 1 ;;
esac
rm -f /tmp/sendoff-demo-root-path /tmp/sendoff-demo-timings \
  /tmp/sendoff-target-picker.png /tmp/sendoff-workspaces.png \
  /tmp/sendoff-slash-menu.png /tmp/sendoff-reference.png
```

The numbered raw take and encoded files in `/home/ex1te/Videos/rewrite-demo-assets/` remain as the recoverable media source.

- [ ] **Step 10: Verify media truth, dimensions, and size**

Run:

```bash
file landing/src/assets/demo/* landing/src/assets/gallery/*
magick identify landing/src/assets/demo/sendoff-demo-poster.webp landing/src/assets/gallery/*.webp
du -ch landing/src/assets/demo/* landing/src/assets/gallery/*
```

Expected:

- WebM and MP4 are 1280×720, silent, and show no `rewrite-desktop` path.
- Poster is 1280×720.
- `target-picker.webp` and `reference.webp` are 1600×900.
- `workspaces.webp` and `slash-menu.webp` are 1200×900.
- WebM is below approximately 4 MB.
- Poster plus four gallery images total approximately 1 MB or less without visible text degradation.
- Every visible path, tab, workspace, group, prompt, and reply is fictional.

- [ ] **Step 11: Architect commit checkpoint**

Codex stops before this step. The architect reviews the binary assets visually, then may commit:

```bash
git add landing/src/assets
git commit -m "chore(landing): подготовлены демонстрационные медиа"
```

---

### Task 2: Make Hero outcome-first and integrate the real demo

**Files:**

- Modify: `landing/src/components/Hero.astro`
- Read: `landing/src/assets/demo/sendoff-demo.webm`
- Read: `landing/src/assets/demo/sendoff-demo.mp4`
- Read: `landing/src/assets/demo/sendoff-demo-poster.webp`

**Interfaces:**

- Consumes: the three exact demo asset paths produced by Task 1.
- Produces: `[data-demo-video]`, the `#demo-description` accessible description, and viewport/reduced-motion playback behavior used by final browser verification.

- [ ] **Step 1: Record the pre-change source assertions**

Run:

```bash
rg -n "A real editor|Download the AppImage|demo-slot|27 seconds|class=\"chrome\"" landing/src/components/Hero.astro
```

Expected: all five legacy markers match before the edit. The final version must match none of them.

- [ ] **Step 2: Import the three build-time media assets**

Add to the frontmatter in `Hero.astro`:

```astro
import demoWebm from "../assets/demo/sendoff-demo.webm";
import demoMp4 from "../assets/demo/sendoff-demo.mp4";
import demoPoster from "../assets/demo/sendoff-demo-poster.webp";
```

Keep the existing `RELEASES` and `REPO` constants unchanged.

- [ ] **Step 3: Replace Hero copy with the approved outcome-first copy**

Use this exact content:

```astro
<h1 class="rise" style="animation-delay: 0.2s">
  Write prompts with <em>room to think.</em><br />
  Send them where your agents already run.<span class="caret" aria-hidden="true"></span>
</h1>

<p class="sub rise" style="animation-delay: 0.3s">
  Sendoff is a local Linux editor for long prompts. Bind a tab once, then
  <kbd>Ctrl</kbd>&thinsp;+&thinsp;<kbd>Enter</kbd> sends to Herdr, Orca, or tmux.
</p>

<div class="actions rise" style="animation-delay: 0.4s">
  <a class="btn primary" href={RELEASES}>
    Get the latest AppImage
    <span class="arrow" aria-hidden="true">→</span>
  </a>
  <a class="btn ghost" href={REPO}>View source</a>
</div>

<p class="fineprint rise" style="animation-delay: 0.48s">
  x86_64 &middot; glibc 2.35+ &middot; no auto-update
</p>
```

Do not add another sentence naming features.

- [ ] **Step 4: Replace the placeholder figure with the real video**

Use this markup:

```astro
<figure class="demo rise" style="animation-delay: 0.56s">
  <div class="demo-frame">
    <video
      class="demo-video"
      data-demo-video
      aria-describedby="demo-description"
      poster={demoPoster.src}
      muted
      loop
      playsinline
      controls
      preload="metadata"
    >
      <source src={demoWebm} type="video/webm" />
      <source src={demoMp4} type="video/mp4" />
    </video>
  </div>
  <p id="demo-description" class="sr-only">
    A multi-line prompt is drafted in Sendoff and sent with Ctrl+Enter. The same prompt arrives
    in the bound terminal agent as one submitted block, and the agent begins its reply.
  </p>
</figure>
```

There is no visible caption and no decorative window chrome.

- [ ] **Step 5: Add progressive viewport playback**

Add this local script after the Hero markup:

```astro
<script>
  const video = document.querySelector<HTMLVideoElement>("[data-demo-video]");

  if (video) {
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
    let visible = false;

    const syncPlayback = () => {
      if (!visible || reducedMotion.matches) {
        video.pause();
        return;
      }

      void video.play().catch(() => {
        // При запрете autoplay остаются нативные controls и poster.
      });
    };

    const observer = new IntersectionObserver(
      ([entry]) => {
        visible = entry?.isIntersecting ?? false;
        syncPlayback();
      },
      { threshold: 0.35 },
    );

    observer.observe(video);
    reducedMotion.addEventListener("change", syncPlayback);
  }
</script>
```

Do not add the `autoplay` attribute: reduced-motion and no-JavaScript behavior depend on JavaScript opting into playback.

- [ ] **Step 6: Replace placeholder CSS with real-video CSS**

Remove `.chrome`, `.chrome span`, `.demo-slot`, `.slot-note`, and the Hero `figcaption` rule. Keep `.demo-frame` and replace the placeholder-specific styling with:

```css
.demo-video {
  width: 100%;
  aspect-ratio: 16 / 9;
  object-fit: cover;
  background: var(--panel-solid);
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

Set the headline measure to a value that keeps the two approved sentences as two lines at 1440px while allowing natural wrapping on mobile. Start with:

```css
h1 {
  max-width: 17em;
}
```

The browser checkpoint in Task 5 decides whether only this measure or Hero vertical spacing needs adjustment to reveal the demo edge at 1440×900. Do not change copy or global type scale to satisfy the viewport target.

- [ ] **Step 7: Build and verify legacy markers are gone**

Run:

```bash
cd landing
bun run build
cd ..
if rg -n "A real editor|Download the AppImage|demo-slot|27 seconds|class=\"chrome\"" landing/src/components/Hero.astro; then
  echo "legacy Hero marker remains" >&2
  exit 1
fi
```

Expected: Astro build exits 0 and the marker check exits 0 without printing matches.

- [ ] **Step 8: Architect commit checkpoint**

Codex stops before this step. The architect may commit:

```bash
git add landing/src/components/Hero.astro
git commit -m "feat(landing): hero доказывает основной сценарий демо-роликом"
```

---

### Task 3: Replace the gallery storyboard with four real detail shots

**Files:**

- Modify: `landing/src/components/Gallery.astro`
- Read: `landing/src/assets/gallery/target-picker.webp`
- Read: `landing/src/assets/gallery/workspaces.webp`
- Read: `landing/src/assets/gallery/slash-menu.webp`
- Read: `landing/src/assets/gallery/reference.webp`

**Interfaces:**

- Consumes: the four exact WebP paths produced by Task 1.
- Produces: four non-interactive figures with build-time image resolution, meaningful alternative text, approved benefit copy, and the existing asymmetric grid.

- [ ] **Step 1: Record the pre-change placeholder assertions**

Run:

```bash
rg -n "shot:|placeholder|shot-note|A look at it|Four things worth seeing" landing/src/components/Gallery.astro
```

Expected: each legacy placeholder marker matches before editing and none remains afterward.

- [ ] **Step 2: Import Astro Image and all four screenshots**

Replace the start of the frontmatter with:

```astro
---
import { Image } from "astro:assets";
import targetPicker from "../assets/gallery/target-picker.webp";
import workspaces from "../assets/gallery/workspaces.webp";
import slashMenu from "../assets/gallery/slash-menu.webp";
import reference from "../assets/gallery/reference.webp";

const shots = [
  {
    id: "target-picker",
    title: "Send to the right agent",
    caption:
      "Herdr, Orca, and tmux share one picker. Sources that are not running stay out of the way.",
    alt: "Target picker listing Herdr, Orca, and tmux agents in separate sections",
    image: targetPicker,
    span: 2,
  },
  {
    id: "workspaces",
    title: "Keep projects apart",
    caption: "Workspaces, colour-coded groups, and pins keep a long tab strip navigable.",
    alt: "Sendoff tab bar with grouped and pinned tabs and the workspace picker open",
    image: workspaces,
    span: 1,
  },
  {
    id: "slash-menu",
    title: "Shape the prompt in place",
    caption: "Type / for saved phrases and Markdown scaffolding, inserted right at the caret.",
    alt: "Slash menu open at the prompt caret with saved phrases and Markdown actions",
    image: slashMenu,
    span: 1,
  },
  {
    id: "reference",
    title: "Keep the answer in view",
    caption: "Pin the reply beside the editor while you write the follow-up.",
    alt: "Sendoff editor with an agent reply pinned in the reference panel",
    image: reference,
    span: 2,
  },
];
---
```

Do not add a fifth trigger-phrases item.

- [ ] **Step 3: Replace the gallery introduction and frames**

Use this introduction:

```astro
<div class="section-head">
  <span class="num">02</span>
  <h2>A closer look</h2>
</div>

<p class="lede">Four details the demo moves past.</p>
```

Replace the placeholder inside each `.frame` with:

```astro
<Image src={s.image} alt={s.alt} loading="lazy" decoding="async" />
```

Keep the existing `<figure>`, heading, caption, `data-span`, and grid order.

- [ ] **Step 4: Remove false interactivity and placeholder-only CSS**

Delete:

- `.shot:hover .frame`
- the `transition` declarations from `.frame`
- `.placeholder`
- `.shot[data-span="2"] .placeholder`
- `.shot-note`

Use:

```css
.frame {
  border: 1px solid var(--line);
  border-radius: 5px;
  background: var(--panel-solid);
  overflow: hidden;
}

.frame :global(img) {
  width: 100%;
  height: auto;
}
```

Keep the existing asymmetric grid, bottom-aligned captions, and single-column mobile breakpoint.

- [ ] **Step 5: Build and verify no storyboard text remains**

Run:

```bash
cd landing
bun run build
cd ..
if rg -n "shot:|placeholder|shot-note|A look at it|Four things worth seeing|секции Herdr|полоса табов|reference-панель" landing/src/components/Gallery.astro; then
  echo "gallery storyboard marker remains" >&2
  exit 1
fi
```

Expected: Astro build exits 0; the marker check prints nothing and exits 0.

- [ ] **Step 6: Architect commit checkpoint**

Codex stops before this step. The architect may commit:

```bash
git add landing/src/components/Gallery.astro
git commit -m "feat(landing): галерея заполнена реальными кадрами продукта"
```

---

### Task 4: Complete social proof metadata and accessibility polish

**Files:**

- Modify: `landing/src/layouts/Base.astro`
- Modify: `landing/src/styles/global.css`
- Modify: `landing/src/components/Hero.astro`
- Read: `landing/src/assets/demo/sendoff-demo-poster.webp`

**Interfaces:**

- Consumes: `demoPoster.src`, `.caret`, and the global `--ink-faint` token.
- Produces: absolute Open Graph/Twitter image metadata, AA-compliant faint text, and a non-blinking reduced-motion caret.

- [ ] **Step 1: Record the pre-change metadata and contrast state**

Run:

```bash
rg -n "og:image|twitter:image|--ink-faint|prefers-reduced-motion" landing/src/layouts/Base.astro landing/src/styles/global.css landing/src/components/Hero.astro
```

Expected: no `og:image` or `twitter:image`; `--ink-faint` is `#6f688c`; Hero has no reduced-motion caret override.

- [ ] **Step 2: Reuse the poster as the social image**

In `Base.astro`, import the poster and construct an absolute URL:

```astro
import demoPoster from "../assets/demo/sendoff-demo-poster.webp";

const socialImage = new URL(demoPoster.src, Astro.site).toString();
```

After the existing `og:url`, add:

```astro
<meta property="og:image" content={socialImage} />
<meta
  property="og:image:alt"
  content="Sendoff editor beside a terminal agent during a prompt handoff"
/>
```

After `twitter:card`, add:

```astro
<meta name="twitter:image" content={socialImage} />
<meta
  name="twitter:image:alt"
  content="Sendoff editor beside a terminal agent during a prompt handoff"
/>
```

Delete the obsolete `TODO(демо)` comment about adding `og:image` after reshooting.

- [ ] **Step 3: Raise faint text contrast with one global token change**

In `global.css`, change:

```css
--ink-faint: #8077a3;
```

Verify the contrast numerically:

```bash
node -e 'const lum=s=>{const a=[1,3,5].map(i=>parseInt(s.slice(i,i+2),16)/255).map(x=>x<=.04045?x/12.92:((x+.055)/1.055)**2.4);return .2126*a[0]+.7152*a[1]+.0722*a[2]};console.log(((lum("#8077a3")+.05)/(lum("#0a0912")+.05)).toFixed(2))'
```

Expected: `4.79`, above the WCAG-AA 4.5:1 threshold for normal text.

- [ ] **Step 4: Stop the Hero caret for reduced motion**

Add a new reduced-motion block at the end of the scoped styles in `Hero.astro`:

```css
.caret {
  animation: none;
}
```

Do not remove the caret itself; it remains a static ember mark.

- [ ] **Step 5: Build and inspect generated metadata**

Run:

```bash
cd landing
bun run build
rg -n "og:image|twitter:image|Sendoff editor beside a terminal agent" dist/index.html
cd ..
```

Expected: build exits 0; generated HTML contains absolute same-origin Open Graph and Twitter image URLs plus both English alt strings.

- [ ] **Step 6: Architect commit checkpoint**

Codex stops before this step. The architect may commit:

```bash
git add landing/src/layouts/Base.astro landing/src/styles/global.css landing/src/components/Hero.astro
git commit -m "fix(landing): усилены social preview и доступность"
```

---

### Task 5: Run the bounded publication-gate verification and restore HANDOFF

**Files:**

- Verify: `landing/src/**`
- Verify: `landing/dist/**`
- Modify: `HANDOFF.md`
- Review: `docs/superpowers/specs/2026-08-15-landing-hero-proof-design.md`
- Review: `docs/superpowers/plans/2026-08-15-landing-hero-proof.md`

**Interfaces:**

- Consumes: the complete Hero, Gallery, metadata, global CSS, and all media assets.
- Produces: one final verification record and an accurate ignored session handoff. It does not deploy the page.

- [ ] **Step 1: Run the repository gates**

Run:

```bash
cd landing
bun run build
cd ..
git diff --check
```

Expected: all commands exit 0.

- [ ] **Step 2: Run deterministic release-marker checks**

Run:

```bash
if rg -n "TODO\((демо|кадры)\)|demo-slot|shot-note|class=\"placeholder\"|rewrite-desktop" landing/src; then
  echo "publication blocker remains" >&2
  exit 1
fi
rg -n "Get the latest AppImage|View source|A closer look|Four details the demo moves past" landing/dist/index.html
```

Expected: blocker check prints nothing; generated HTML contains all four approved copy markers.

- [ ] **Step 3: Verify build output media and external-host boundary**

Run:

```bash
find landing/dist -type f \( -name '*.webm' -o -name '*.mp4' -o -name '*.webp' \) -printf '%s %p\n' | sort -n
rg -n "https?://" landing/dist -g '*.html' -g '*.css'
```

Expected: the build contains both video sources, the poster, and all four gallery images. URL matches are limited to Sendoff's canonical URL and intentional GitHub links; fonts and media resolve to same-origin paths.

- [ ] **Step 4: Run the one allowed mechanical design scan**

Run exactly once after all UI edits:

```bash
node /home/ex1te/.agents/skills/impeccable/scripts/detect.mjs --json landing/src
```

Expected: inspect every finding. Fix only concrete violations of the approved spec or accessibility floor; do not broaden into unrelated redesign. If a fix is required, apply one batched correction and rerun only the project build, not the detector.

- [ ] **Step 5: Inspect desktop and mobile in one bounded browser pass**

Start the preview:

```bash
cd landing
bun run preview -- --host 127.0.0.1 --port 4321
```

In fresh browser tabs, inspect 1440×900 and 390×844 together. Confirm:

- the demo's top edge is visible at 1440×900 without scrolling;
- no horizontal overflow at 390px;
- the video poster is informative before playback;
- normal motion starts playback while at least 35% visible and pauses after leaving the viewport;
- native pause/play controls work by mouse and keyboard;
- reduced motion does not autoplay and leaves manual playback available;
- the caret is static under reduced motion;
- disabling JavaScript leaves poster plus native controls;
- all four gallery images and captions align; mobile uses one column;
- gallery frames do not move or imply a lightbox on hover;
- console contains no page errors or warnings.

Stop the preview after this pass. Apply at most one batched correction for defects observed at both viewports, rebuild once, and perform one confirmation pass.

- [ ] **Step 6: Update the ignored session handoff**

Replace the top current-state section in `HANDOFF.md` with an accurate 2026-08-15 entry containing:

- desktop `master` at `8724a75` plus the architect's new commit hashes, and whether each is pushed;
- the approved Hero outcome copy and CTA wording;
- demo and gallery asset paths, measured sizes, and seeded-profile provenance;
- commands and results from Steps 1–5;
- confirmation that visible Russian placeholders and the stale `rewrite-desktop` path are absent;
- the uncommitted/committed status of the design spec, plan, and critique snapshot;
- remaining work: the separately scoped final conversion-arc refinement, Cloudflare Pages deployment, and Stage C posting;
- any browser fallback or media-production limitation actually observed.

Do not commit `HANDOFF.md`.

- [ ] **Step 7: Architect documentation and final commit checkpoint**

Codex stops before this step. The architect reviews the spec, plan, verification evidence, and prior atomic commits, then may commit the two design documents:

```bash
git add docs/superpowers/specs/2026-08-15-landing-hero-proof-design.md docs/superpowers/plans/2026-08-15-landing-hero-proof.md
git commit -m "docs(landing): зафиксирована переработка Hero и proof-слоя"
```

Before any later merge or deployment, rerun:

```bash
cd landing && bun run build
```

Expected: exit 0. Deployment and pushing remain explicit separate actions.
