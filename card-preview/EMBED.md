# Globe preview for the project card

A seamless 10-second looping globe render for the **Global View — Flight Track Live**
portfolio card. Pure visual — no UI, no data; the real app is what "live demo" opens.

## Files

| File | Size | Use |
|---|---|---|
| `globe-card@2x.mp4` | ~695 KB | **Recommended.** 930×640 = 2× the card's 465×320 content box — crisp on Retina |
| `globe-card.mp4` | ~236 KB | 466×320 (1×) — ultra-light fallback if you want minimum weight |
| `globe-card-poster.jpg` | ~37 KB | First frame — paints instantly while the video loads |

Both videos: H.264 · 30 fps · 10.0 s · exactly one revolution → the loop point is invisible.

## Drop into the card

```html
<video
  class="card-globe"
  src="globe-card@2x.mp4"
  poster="globe-card-poster.jpg"
  autoplay loop muted playsinline
  width="466" height="320"
></video>
```

```css
.card-globe {
  display: block;
  width: 100%;
  height: auto;            /* or a fixed height + object-fit: cover */
  border-radius: 12px;     /* match your card corners */
  background: #0a1120;     /* same tone as the video edges — no flash on load */
}
```

Notes
- `muted` + `playsinline` are required for autoplay on Safari/iOS — keep all three attributes.
- The background gradient is baked in, so the video also works edge-to-edge with `object-fit: cover`.
- To pause off-screen (battery-friendly), add a tiny IntersectionObserver that calls `.play()` / `.pause()` — optional.

## Re-render

`mini-globe-render.html` is the self-contained scene (same shaders/textures as the app).
Serve this folder, then the capture script drives it frame-by-frame:

```bash
python3 -m http.server 5799   # in this folder
node capture.mjs              # scratch script: puppeteer-core + Chrome headless
ffmpeg -framerate 30 -i frames/frame_%04d.png -c:v libx264 -preset slow -crf 22 \
  -pix_fmt yuv420p -movflags +faststart -an globe-card@2x.mp4
```

Loop rule: everything animated must complete an **integer** number of cycles over the
10 s duration (earth = 1 rev, arc pulses = 2–3 cycles, clouds locked to the surface).
