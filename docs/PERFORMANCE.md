# Performance Guide — MaxSpeed VPN

This document covers the runtime performance characteristics of the
MaxSpeed VPN Flutter app, including startup time, memory footprint,
battery consumption, and actionable optimisation tips.

---

## 1. Startup Time

| Phase                    | Target   | Notes                                   |
|--------------------------|----------|-----------------------------------------|
| Cold start (splash shown) | < 1.2 s | Includes Dart VM init + first frame     |
| VPN connect handshake     | < 3.0 s | Server TLS + key exchange               |
| Server list render        | < 0.5 s  | Cached list with skeleton placeholders  |

We profile startup with `flutter run --profile` and track the
`AppStartMetrics` class, which records timestamps at key lifecycle
boundaries.

### Reducing startup time
• Defer non-critical initialisation (analytics, remote config)
  until after the first frame.
• Use `compute()` or isolates for JSON decoding of server lists.
• Bundle a short pre-warmed server list inside the asset bundle
  so the UI can render before the network response arrives.

---

## 2. Memory Usage

| Component            | Approx. Resident Size |
|----------------------|-----------------------|
| Flutter engine       | ~30 MB                |
| Dart VM (idle)       | ~15 MB                |
| Server list cache    | ~2 MB (200 servers)   |
| VPN tunnel buffer    | ~5 MB                 |
| **Total typical**    | **~52 MB**            |

Heap snapshots are taken via DevTools. Memory grows linearly with
the number of rendered server list items; use `ListView.builder`
with a fixed `itemExtent` to keep the widget tree lean.

### Memory watch-outs
• Avoid retaining disposed `AnimationController` instances.
• Clear periodic timers in `State.dispose()`.
• Do not cache raw banner images — downscale to thumbnail size.

---

## 3. Battery Impact

VPN apps run continuously in the background, so battery efficiency
is critical. MaxSpeed VPN targets ≤ 3 % battery drain per hour
during active tunnelling on a mid-range Android device.

### What draws power
1. **TLS keep-alive heartbeat** — 30-second ping interval.
2. **Packet encryption** — ChaCha20-Poly1305 on the platform's
   hardware-accelerated crypto.
3. **Foreground service (Android)** — required to prevent the OS
   from killing the tunnel; uses a low-priority notification.

### Battery-saving tips for users
• Enable "Battery Saver" mode in Settings — this increases the
  keep-alive interval from 30 s to 60 s and disables non-essential
  background checks.
• Prefer nearby servers to reduce retransmissions.
• Disconnect when on trusted Wi-Fi if split-tunnelling is
  enabled.

---

## 4. Optimisation Tips (For Developers)

1. **Tree-shaking** — Run `flutter build apk --obfuscate --split-debug-info`
   to strip unused code.
2. **SVG icons** — Prefer vector icons over raster assets.
3. **Connection pooling** — Reuse platform channel calls instead
   of creating new method-channel invocations per packet.
4. **Debounce rapid UI events** — E.g., server-search input should
   debounce at 300 ms.
5. **Lazy-load premium features** — Gate heavy behind feature flags
   and load their modules on demand with deferred imports.
6. **Profile regularly** — Use DevTools' flame chart to catch
   jank frames (> 16 ms) before release.

---

## 5. Benchmarking

Run benchmarks with:

```bash
flutter drive --target=test_driver/benchmark.dart --profile
```

Results are written to `benchmarks/results.json` and compared
against a baseline in CI. Any regression > 10 % triggers a
warning; > 25 % fails the build.

---

*Last updated: June 2026*
