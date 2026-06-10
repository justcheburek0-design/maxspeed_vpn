# MaxSpeed VPN — Troubleshooting Guide

## Table of Contents
1. [Common Issues](#common-issues)
2. [Log Interpretation](#log-interpretation)
3. [Connection Failures](#connection-failures)
4. [Subscription Errors](#subscription-errors)
5. [Performance Problems](#performance-problems)
6. [Getting Further Help](#getting-further-help)

---

## Common Issues

### App Won't Start
- Ensure your device runs Android 7.0 (API 24) or higher.
- Clear the app cache: **Settings → Apps → MaxSpeed VPN → Storage → Clear Cache**.
- Reboot the device and try launching again.
- If the crash persists, uninstall and reinstall from the Google Play Store.

### VPN Permission Dialog Not Appearing
- Go to **Settings → Apps → MaxSpeed VPN → Permissions** and ensure no VPN-related permissions are blocked.
- On some OEM skins (Xiaomi, Huawei), disable battery optimization for the app.
- Check that no other VPN app is already active — Android allows only one VPN tunnel at a time.

### App Connects but No Internet
- Try switching to a different server location.
- Toggle between protocols (OpenVPN ↔ WireGuard ↔ IKEv2) in **Settings → Protocol**.
- Disable IPv6 on your device if your ISP has broken IPv6 routing.
- Verify that local network access is enabled in settings if you need LAN connectivity.

### Frequent Disconnections
- Enable **Kill Switch** in settings to prevent traffic leaks during reconnects.
- Switch to a protocol with better NAT traversal (WireGuard is recommended).
- Disable battery saver / doze mode for the app.
- Check your Wi-Fi router's UDP timeout — some routers drop idle UDP sessions aggressively.

---

## Log Interpretation

Access logs via **Settings → Diagnostics → View Logs** or export them with **Share Logs**.

### Log Levels
- **INFO** — Normal operational messages (connection start, server selected).
- **WARN** — Non-fatal issues (certificate near expiry, slow handshake).
- **ERROR** — Operation failures (auth rejected, TLS error, timeout).
- **DEBUG** — Verbose packet-level detail (enable in Diagnostics settings).

### Key Log Patterns

| Pattern | Meaning | Action |
|---|---|---|
| `TLS handshake failed` | Server certificate or cipher mismatch | Update app or switch protocol |
| `AUTH_FAILED` | Invalid credentials or expired token | Re-login or refresh subscription |
| `Connection timed out` | Server unreachable or port blocked | Try a different port or server |
| `DNS resolution failed` | Cannot resolve server hostname | Check DNS settings; try custom DNS |
| `TUN/TAP device error` | VPN interface could not be created | Restart device; check for conflicting VPN |
| `Inactivity timeout` | Server closed idle connection | Enable "Keep Alive" in settings |
| `RECONNECTING` | Transient network loss; auto-retry in progress | Usually self-resolves; check network |

### Exporting Logs
1. Open **Settings → Diagnostics**.
2. Tap **Export Logs** — a `.zip` is generated with timestamped entries.
3. Attach the zip when contacting support.

---

## Connection Failures

### Symptom: "Connecting…" Spins Indefinitely
1. Verify internet access without VPN (disconnect and browse normally).
2. Try a different network (switch from Wi-Fi to mobile data or vice versa).
3. Change the connection port (default 1194 → 443 or 53).
4. Disable any firewall or security app that may block VPN traffic.

### Symptom: Immediate Disconnect After Connecting
- **Cause 1:** Server is at capacity. Try a less-popular location.
- **Cause 2:** Protocol blocked by network (common on corporate/school Wi-Fi). Switch to TCP 443 or use obfuscation.
- **Cause 3:** Outdated app version. Update via Play Store.

### Symptom: "Server Not Found" Error
- The selected server may be under maintenance. Choose an alternative.
- Flush DNS: toggle airplane mode on and off.
- Manually set DNS to `1.1.1.1` or `8.8.8.8` in Android network settings.

### Symptom: Slow Speeds After Connecting
- Connect to a geographically closer server.
- Switch from OpenVPN (UDP) to WireGuard for lower latency.
- Test with a speed test app to establish a baseline without VPN.
- Avoid peak hours on free-tier servers.

---

## Subscription Errors

### "Subscription Not Found" on Login
- Ensure you are signed in with the same Google account used for purchase.
- Open the Play Store → **Payments & Subscriptions** to verify the subscription is active.
- Tap **Restore Purchases** inside the app (Settings → Account → Restore).

### "Payment Failed" or Billing Error
- Update your payment method in the Google Play Store.
- Check for sufficient funds or card expiry.
- Contact your bank if the transaction is being declined.

### Subscription Active but Features Locked
- Force-stop the app and relaunch.
- Clear app data (**Settings → Apps → MaxSpeed VPN → Clear Data**) and log in again.
- Wait up to 5 minutes — Play Store receipt propagation can be delayed.

### Refund Requests
- Refunds are handled by Google Play. Visit [play.google.com/store/account](https://play.google.com/store-account) → **Order History** → **Request a refund**.
- MaxSpeed VPN support cannot process refunds directly.

---

## Performance Problems

### High Battery Drain
- Use WireGuard protocol (lower CPU overhead than OpenVPN).
- Disable "Always-on VPN" if not required.
- Reduce the frequency of background keep-alive pings in settings.

### DNS Leaks
- Enable **DNS Leak Protection** in settings.
- Verify at [dnsleaktest.com](https://dnsleaktest.com) after connecting.
- Use MaxSpeed VPN's private DNS servers (selected by default).

### Split Tunneling Not Working
- Ensure the feature is toggled on in **Settings → Split Tunneling**.
- Add apps to the exclusion list manually.
- Note: split tunneling is unavailable on Android 6.x and below.

---

## Getting Further Help

- **In-App Support:** Settings → Help → Contact Us (attaches logs automatically).
- **Email:** support@maxspeedvpn.com
- **Community:** [community.maxspeedvpn.com](https://community.maxspeedvpn.com)
- **Response Time:** Within 24 hours on business days.

When contacting support, always include:
1. Device model and Android version.
2. MaxSpeed VPN app version (Settings → About).
3. Exported diagnostic logs.
4. A description of the issue and steps to reproduce.
