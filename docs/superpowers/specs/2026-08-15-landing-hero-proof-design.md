# Landing Hero + Proof — Design Specification

**Date:** 2026-08-15  
**Status:** approved

## Goal

Make the first half of the Sendoff landing page prove the product before explaining its boundaries. The hero should lead with the user's outcome, the demo should be the primary evidence, and the gallery should show four details that the demo moves past.

This is a focused refinement of the existing editorial visual system. It is not a redesign of the whole landing page.

## Product constraints

- Preserve Sendoff's positioning as a prompt-first editor for terminal coding agents.
- Do not turn the page into a feature catalogue or repeat the README.
- Keep the existing Newsreader + Commit Mono typography and the violet/ember palette.
- UI copy remains English; source comments remain Russian.
- All fonts and media are served from the Sendoff domain. No external media or font requests.
- The landing remains a static Astro page without application state or a backend.

## In scope

- Hero hierarchy and copy.
- Primary and secondary CTA wording.
- Demo frame, playback behavior, fallback behavior, and accessibility.
- Gallery introduction, four existing subjects, captions, and image behavior.
- Reuse of the approved demo poster for Open Graph and Twitter preview metadata.
- Contrast of small secondary text and reduced-motion coverage in the touched surface.

## Out of scope

- `CoreLoop`, `Boundary`, `Scope`, and `Footer` content or composition.
- A separate trigger-phrases gallery item.
- A gallery lightbox or other screenshot interaction.
- Navigation, routes, analytics, remote assets, or new dependencies.
- Reworking the final conversion arc; that remains a separate follow-up identified by the critique.

## Hero hierarchy

The existing upper metadata line, icon, wordmark, editorial typography, background grid, glow, and caret remain. The copy changes from a category-first statement to an outcome-first statement.

### Headline

> Write prompts with *room to think.*  
> Send them where your agents already run.

The Newsreader italic moves from the technical category to `room to think`, emphasizing the human benefit rather than an integration label.

### Supporting copy

> Sendoff is a local Linux editor for long prompts. Bind a tab once, then `Ctrl+Enter` sends to Herdr, Orca, or tmux.

The first sentence defines the product in plain language. Integration names remain present but subordinate to the outcome.

### Actions

- Primary: `Get the latest AppImage`
- Secondary: `View source`

The primary action continues to point to the latest GitHub release page. Its label no longer implies that clicking it directly downloads an asset.

### Compatibility line

> x86_64 · glibc 2.35+ · no auto-update

This line remains next to the download decision and uses a text colour that meets WCAG AA contrast for its rendered size.

### First viewport

On a 1440 × 900 desktop viewport, the top edge of the demo must be visible without scrolling. On mobile, the demo follows immediately after the actions and compatibility line. The existing visual atmosphere stays restrained; no new decorative layer or animation is introduced.

## Demo as primary proof

The demo occupies the full content-shell width below the hero copy.

### Visual treatment

- Remove the decorative three-dot window chrome. It suggests a generic macOS window on a Linux-only product.
- Keep a thin border, restrained radius, and soft shadow consistent with the existing page.
- Remove the visible `figcaption`. The duration and production method do not help the visitor understand the product.
- Provide a screen-reader description of the demonstrated sequence.

### Content

The recording shows one continuous real workflow using the seeded fictional project:

1. Draft a multi-line prompt in Sendoff.
2. Press `Ctrl+Enter`.
3. Show the same prompt arrive in the bound terminal agent as one submitted block.
4. Show the agent begin its reply.

The demo has no narration and no cuts. Those facts do not appear as visible marketing copy.

### Local assets

Final filenames:

- `landing/src/assets/demo/sendoff-demo.webm`
- `landing/src/assets/demo/sendoff-demo.mp4`
- `landing/src/assets/demo/sendoff-demo-poster.webp`

The poster uses an informative frame in which the editor and terminal target are both recognizable. It must not be a black or empty opening frame.

The final implementation resolves all three files through build-time imports. A missing final video source or poster therefore fails the build rather than producing an empty public frame.

The same poster supplies same-origin `og:image` and `twitter:image` metadata with an English alternative description. No separate social-preview composition is introduced.

### Playback and failure behavior

The `<video>` retains native controls and uses `muted`, `loop`, `playsinline`, and `preload="metadata"`.

Autoplay is progressive enhancement rather than a required attribute:

- A small local script starts playback only when `prefers-reduced-motion: no-preference` matches and the video intersects the viewport.
- The script pauses playback when the video leaves the viewport.
- If reduced motion is requested, JavaScript is unavailable, `play()` is rejected, or the preferred source cannot load, the poster and native manual controls remain usable.
- WebM is preferred; MP4 is the fallback source.

No custom player UI or playback dependency is introduced.

## Gallery as secondary proof

The gallery remains after `CoreLoop`. It does not repeat the Draft → Send → reply sequence. It shows four details that the demo moves past.

### Introduction

**Heading:** `A closer look`

**Lede:**

> Four details the demo moves past.

### Subjects and copy

1. **Send to the right agent**  
   Herdr, Orca, and tmux share one picker. Sources that are not running stay out of the way.

2. **Keep projects apart**  
   Workspaces, colour-coded groups, and pins keep a long tab strip navigable.

3. **Shape the prompt in place**  
   Type `/` for saved phrases and Markdown scaffolding, inserted right at the caret.

4. **Keep the answer in view**  
   Pin the reply beside the editor while you write the follow-up.

Trigger phrases do not receive a fifth frame. They are already represented within the slash-menu subject and a separate frame would repeat the same visual pattern.

### Image composition

- Target picker and reference panel remain wide frames.
- Workspaces and slash menu use deliberate focused crops rather than scaled-down full-window screenshots.
- All four images use the same seeded fictional project as the demo.
- The asymmetric two-wide/two-narrow desktop composition remains.
- At the existing mobile breakpoint, all frames form one column.
- Remove hover lift and any other cue that suggests the non-interactive screenshots open a lightbox.

### Local assets

Final filenames:

- `landing/src/assets/gallery/target-picker.webp`
- `landing/src/assets/gallery/workspaces.webp`
- `landing/src/assets/gallery/slash-menu.webp`
- `landing/src/assets/gallery/reference.webp`

The final implementation imports these assets at build time so a missing image fails the build instead of producing a public empty frame. Astro handles responsive image output. Each image has content-specific alternative text; the visible caption describes the benefit rather than repeating the alternative text.

## Placeholder and publication policy

The current striped placeholders may remain only while media production is incomplete. The final media-integration change replaces the placeholders and their visible Russian shooting notes atomically with the build-time asset imports.

The landing must not be published while any visible placeholder, Russian shooting note, or missing-media placeholder remains. This is a release gate, not a best-effort check.

## Accessibility and quality constraints

- Small compatibility, metadata, and caption text must meet WCAG AA contrast at its rendered size.
- The blinking caret stops under `prefers-reduced-motion: reduce` in addition to the existing entrance animations and smooth scrolling.
- Native video controls remain keyboard accessible.
- The video has an accessible description of the meaningful visual sequence.
- Gallery alternative text identifies what the screenshot shows; captions state why it matters.
- No hover styling implies interaction on static images.

## Performance targets

These are optimization targets, not reasons to ship visibly degraded media:

- Combined WebM/MP4 delivery should prefer the browser-supported source rather than download both.
- Target WebM size: no more than approximately 4 MB.
- Target combined poster and gallery image transfer: no more than approximately 1 MB after Astro optimization.
- Video preload remains `metadata`; the full video must not block initial page rendering.

## Verification

Run and record:

1. `cd landing && bun run build`
2. Inspect at 1440 × 900 and 390 × 844.
3. Confirm the demo edge is visible in the first desktop viewport.
4. Confirm autoplay only while visible under normal motion preferences.
5. Confirm manual playback works with reduced motion and with JavaScript disabled.
6. Confirm poster and MP4 fallback behavior.
7. Confirm native controls are keyboard reachable.
8. Confirm small text contrast and that the caret does not blink under reduced motion.
9. Confirm no horizontal overflow, page-console errors, visible Russian text, or external font/media requests.
10. Confirm all four gallery subjects show the seeded fictional project and that no real prompts or workspaces appear.
11. Confirm generated Open Graph and Twitter image URLs are absolute, same-origin, and use the demo poster.

## Success criteria

- The first screen communicates the outcome before naming integrations.
- A visitor can see real product behavior without scrolling past a feature list.
- The demo and gallery form one coherent fictional workflow but do not duplicate each other.
- The touched surface remains visually recognisable as the existing Sendoff landing.
- The page fails at build time when any required final media asset is missing.
- Publication cannot accidentally include production notes or visible placeholders.
