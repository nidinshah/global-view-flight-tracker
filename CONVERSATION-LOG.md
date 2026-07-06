# Global View — Session Log

A record of how this project was built, in case you want to pick it back up in a
new chat without re-explaining context. Copy/paste the relevant part into your
next message if you need Claude to catch up fast.

## What this project is

A single-file, browser-only **live flight tracker** built on a Three.js globe:
search a flight code, watch the real aircraft move in real time, browse "famous
flights," see every aircraft near you on a live radar, and drill into full
telemetry for any tracked flight. No backend — everything is fetched by the
visitor's own browser from free, keyless APIs.

**Main file:** `index.html` (run via `Start Flight Tracker.command`, or serve the
folder with any static server, or just double-click the HTML file).

## Build history (chronological)

1. **v1 — Static dashboard clone.** Recreated a reference screenshot/video
   ("Global View" logistics dashboard) as a Three.js + React + Tailwind single
   page: rotating Earth, sidebar, stats, collapsible bottom panel.

2. **v2 — Geo + country detail.** Added country border overlays and name labels
   (fade in on zoom), geolocation-based start position (falls back to timezone
   guess — e.g. opens on Malaysia), and pushed texture/render quality to the max
   (4K day/night/cloud maps, high pixel ratio, anisotropic filtering).

3. **v3 — Pivoted to a real flight tracker.** Replaced the fake logistics data
   with **live ADS-B flight tracking**: search any flight code (IATA like
   `MH370` or ICAO callsign like `MAS370`), see it move in real time via
   `airplanes.live`, with route lookup via `hexdb.io`. Added an AWS deploy kit
   (`deploy-aws.sh` + `AWS-DEPLOY.md` — S3 + CloudFront, near-$0 cost).

4. **v4 — "Show me the best."** Major upgrade pass:
   - Fixed a real bug: country lookup used nearest-centroid, which mislabeled
     Penang as Thailand — replaced with exact point-in-polygon containment.
   - Added terrain-relief shading (elevation bump-mapping) for a visibly more
     detailed globe.
   - Switched route/aircraft data to **adsbdb.com** (richer: airline identity +
     aircraft registry) with hexdb as fallback, added **planespotters.net**
     photos of the exact tracked airframe.
   - Built out full side-drawer navigation: Famous Flights (16 legendary
     routes with live status), full Flight Details (every broadcast field —
     Mach, wind aloft, autopilot settings, squawk alerts), History, Settings
     (clouds/labels/units/quality, persisted), About.
   - Added working notifications (bell) and a session info popover (avatar).
   - Expanded the airline recognition table to ~140 airlines worldwide
     (AirAsia group, Gulf/Middle East majors, every Japanese carrier, etc.)
     and started showing the airline's real name on tracked flights.

5. **v5 — Radar + quick-look + polish.**
   - Clicking a lingering traffic-radar aircraft now opens a **quick-look
     popup** ("where's this plane going?") instead of instantly tracking it —
     shows route/aircraft/speed with a "Track this flight" button.
   - Added a **Live Radar** side drawer: real-time sortable list of every
     aircraft near your view, sky stats (highest/fastest/top airlines),
     emergency squawk (7500/7600/7700) watch with notifications.
   - Added keyboard shortcuts: `/` search, `T` traffic, `R` radar, `D` details,
     `F` follow, `Esc` closes everything.
   - Redesigned the traffic-radar aircraft icon (was an ugly oversized dart —
     now a proper airliner silhouette that scales to a constant screen size
     regardless of zoom).
   - Fixed the initial camera zoom (was too close on load — now opens one
     step further out, matching the intended "whole globe in frame" view).

6. **v7 — Globe realism + weather + feature expansion (from
   `globe-view-improvements-brief.md`).**
   - **Progressive textures:** fast 2K tier paints first (~1.7 MB), true-4K
     set (4096×2048 day/night/elevation/water) streams in behind it and swaps
     per-texture. Clouds no longer block first paint (they fade in when
     loaded). Settings quality tier now controls textures too: Balanced stays
     2K, High/Ultra upgrade to 4K. Elevation/water sources upgraded to
     genuinely-4K `turban/webgl-earth` maps (old topo was 2048×1024, water
     1600×800 — day/night were already 4K despite what the brief assumed).
   - **Terrain normal mapping:** a tangent-space normal map is generated
     in-browser from the elevation texture (chunked Sobel with cos-lat
     correction, no frame hitch) and replaces the old finite-difference bump
     trick; a tiled procedural detail normal blends in at close zoom.
   - **Ocean sun-glint:** two-lobe Blinn-Phong specular masked by the water
     map, warm-tinted near the terminator.
   - **Sun-lit clouds:** cloud layer now uses a custom shader driven by the
     same sunDir as the terrain (bright day / dark night / warm twilight rim).
   - **Rayleigh-ish atmosphere:** limb glow shifts blue → orange at the
     terminator and dims on the night side.
   - **Live weather radar (RainViewer, keyless):** z=2 mercator tiles
     composed + reprojected to equirect on canvas, drawn as an overlay sphere
     (and 2D plane), animating through the last 5 frames, auto-refresh every
     10 min. Settings → "Live weather radar" (default off).
   - **New features:** dotted great-circle prediction line to destination ·
     `?flight=CODE` deep links + copy-link button · data-source health pill
     (passive latency/failure tracking per API) · global incidents ticker +
     drawer (worldwide 7500/7600/7700 sweep via `/v2/squawk/`) · airport mode
     (click DEP/ARR pill or airport card → live inbound/outbound within
     60 nm) · ⌘K command palette · multi-flight watch (up to 2 chips beside
     the tracked flight) · session replay with scrubber (records tracked
     positions client-side) · first-visit 4-step tour.
   - **Gotcha rediscovered:** anything animated must NOT rely solely on
     requestAnimationFrame (hidden tabs starve it) — the replay driver uses a
     33 ms setInterval like the engine's fallback ticker.
   - **v7.1 UX fixes (user feedback):** 2D map panning is now clamped
     dynamically from zoom + aspect so the map always fills the viewport
     (was: static ±1.7 clamp → dead space beside the map when focused on
     Asia); the bottom Flight Details panel shows a live sky snapshot
     (count/highest/fastest/top airline) when the radar is on but nothing is
     tracked; tracking from a clicked dart/radar row/incident now falls back
     to an airplanes.live **hex lookup**, then to the clicked position
     itself, when the callsign search returns empty (was: "No live aircraft
     found" on a plane you could literally see) — and live polling now uses
     `/v2/hex/` whenever the hex is known; idle auto-rotate resumes 2 s
     after the user stops interacting (was 6 s).
   - **v7.2 — country search.** The search box (and ⌘K) now accepts country
     names: "Malaysia" opens a Country drawer sweeping every transponder over
     that country, grouped **In transit → Departing → Arriving → On standby**
     and refreshed every 25 s. States are inferred from live ADS-B (no
     schedules exist keyless): climb/descent > ±500 fpm below 15,000 ft
     splits departures/arrivals, `alt_baro === 'ground'` is standby
     (taxiing vs parked by ground speed), ground-vehicle categories (C*)
     filtered out. Country matching reuses the border polygons already
     loaded for the border layer (`countryInfo()` resolver with aliases like
     USA/UK/Korea + exact point-in-polygon `countryContains()`); wide
     countries are sampled with up to four 250 nm circles across the bbox,
     merged by hex. Rows open the quick-look → Track (hex-seeded).
   - **v7.3 — creator credit.** About drawer now leads with a clickable
     "Designed & built by Nidin Shah" card (amber "N" avatar matching the
     header) linking to nidinshah.com, plus a follow-up line pointing there
     for the full project write-up.
   - **v7.4 — search reliability + not-airborne info (user bug report:
     "TGW51 airborne but search says not found").** Root causes: (a) search
     hit ONLY `/v2/callsign/`, so a single transient miss (receiver gap,
     index refresh, rate-limit burst from the old parallel candidate fan-out)
     hard-failed even for a live flight; (b) a flight not broadcasting a live
     position (parked / between flights / pre-departure) dead-ended at "No
     live aircraft found" even though adsbdb still has its route. Fixes:
     `searchCandidates` now also emits zero-padded number variants (carriers
     broadcast "TGW51" and "TGW051" inconsistently); `findAircraft` is
     sequential-with-early-exit (no rate-limit bursts) and a typed search
     that misses retries once after 800 ms; and when a flight genuinely
     isn't live, the search resolves its route/airline from adsbdb/hexdb and
     shows a "Not airborne right now" card (route drawn on the globe, DEP→ARR,
     Check-again button) instead of an error. New `grounded` state +
     `clearGrounded`; cleared on successful track / stop / new search.

7. **Card preview video (`card-preview/` folder — separate, doesn't touch the
   app).** Nidin wanted a small looping globe animation for a portfolio
   project card (measured ~465×320px content box). Built a standalone
   render scene (`mini-globe-render.html`, reuses the app's shaders/textures
   but with zero UI/data — pure aesthetic), captured it deterministically
   frame-by-frame with Puppeteer + headless Chrome (300 frames, exactly one
   Earth revolution for a seamless 10-second loop), encoded with ffmpeg.
   Deliverables: `globe-card@2x.mp4` (930×640, ~695 KB), `globe-card.mp4`
   (466×320, ~236 KB), `globe-card-poster.jpg`, and `EMBED.md` with the
   drop-in `<video>` snippet. **The original app was never modified for this.**

## Key technical facts worth remembering

- **Data sources (all free, no API key, verified CORS-safe from a browser):**
  - `api.airplanes.live` — live aircraft positions (poll every 8s); also
    `/v2/squawk/{code}` for the global emergency sweep
  - `api.adsbdb.com` — flight routes + airline identity + aircraft registry
  - `hexdb.io` — route/airport fallback
  - `api.planespotters.net` — real photo of the tracked airframe
  - `api.rainviewer.com` + `tilecache.rainviewer.com` — live precipitation
    radar tiles (weather-maps.json → frame paths, new frame every ~10 min)
  - ⚠️ **adsb.lol, adsb.fi, and OpenSky are CORS-blocked from browsers** —
    already tried, don't reuse them.
- **Globe rotation order is `XYZ` on purpose** — this makes `rotation.x` exactly
  the front-facing latitude and `rotation.y` map linearly to longitude. Using
  `YXZ` breaks the latitude mapping once the globe has spun ~180°.
- **Country lookup must use point-in-polygon (`countryAt()`)**, not
  nearest-centroid — the centroid approach mislabels places like Penang.
- **Hidden/backgrounded browser tabs never fire `requestAnimationFrame`** — the
  main app has a 33ms `setInterval` fallback ticker for this reason. The
  card-preview render script sidesteps the whole issue by calling
  `renderer.getContext().finish()` instead of waiting on rAF.
- **Elevation/water-mask textures must stay in linear color space** (no sRGB
  decode) — applying sRGB to those data textures corrupts the terrain-relief
  lighting math and makes the globe render mostly black.
- **Loop-video rule:** any animated property in a seamless loop must complete
  an *integer* number of cycles across the clip duration, or it jumps at the
  seam. (Caught and fixed a cloud-drift bug for exactly this reason.)

## Where things stand / open threads

- **Publishing:** discussed and recommended **GitHub Pages** — Nidin already
  has `nidinshah.github.io` and is authenticated via `gh` CLI, so publishing
  is basically free and a `git push` away. Offered to do it immediately
  (create repo, push, enable Pages) but this was not yet actioned — pick up
  here if you still want it deployed.
- The AWS deploy kit (`deploy-aws.sh`) is built and ready if AWS is preferred
  instead/also, but GitHub Pages is the recommended default for this project.
- Local-only launcher: double-click `Start Flight Tracker.command` any time
  to run the app without going through Claude's session-bound preview server
  (that server dies whenever the Claude session isn't active — this launcher
  doesn't have that problem).

## File map

```
Earth/
├── index.html                    ← the actual flight tracker app
├── Start Flight Tracker.command  ← double-click to run locally, opens browser
├── deploy-aws.sh                 ← optional AWS (S3+CloudFront) deploy script
├── AWS-DEPLOY.md                 ← AWS deploy instructions + cost breakdown
├── CONVERSATION-LOG.md           ← this file
└── card-preview/                 ← portfolio card video assets (separate, cosmetic-only)
    ├── globe-card@2x.mp4         ← main deliverable, 930×640, ~695 KB
    ├── globe-card.mp4            ← lightweight 1x, 466×320, ~236 KB
    ├── globe-card-poster.jpg     ← instant-paint poster frame
    ├── EMBED.md                  ← drop-in <video> snippet + re-render instructions
    └── mini-globe-render.html    ← the render source (reusable/tweakable)
```
