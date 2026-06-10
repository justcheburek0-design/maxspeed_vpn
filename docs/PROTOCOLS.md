# VPN Protocols — Reference

MaxSpeed VPN supports the protocols listed below. Each entry notes the
transport, default port(s), and encryption in use.

| Protocol      | Transport | Default Port(s)       | Encryption / Security               |
|---------------|-----------|-----------------------|-------------------------------------|
| Naive         | HTTP/2    | 443 (or any HTTPS)    | TLS 1.3 (relies on HTTPS transport) |
| VLESS         | TCP / UDP | 443, 8443             | None (protocol-level); TLS optional |
| VMess         | TCP / UDP | 443, 10086            | AES-128/256, ChaCha20-Poly1305      |
| Trojan        | TCP       | 443                   | TLS 1.2/1.3 + password auth         |
| ShadowSocks   | TCP / UDP | 8388, 8389            | AES-128/256-GCM, ChaCha20-Poly1305 |
| Hysteria      | UDP       | 443, 8443             | TLS 1.3 + QUIC-based obfuscation    |
| WireGuard     | UDP       | 51820                 | ChaCha20, Curve25519, BLAKE2s      |
| TUIC          | UDP       | 443                   | TLS 1.3 + UDP-based multiplexing    |

---

## Per-protocol notes

### Naive
Naive proxies traffic through standard HTTPS connections, disguising VPN
traffic as normal web traffic. The underlying security depends entirely on the
server-side TLS configuration. No additional encryption is applied at the proxy
layer itself. It is designed to look indistinguishable from regular browser
traffic, making it resistant to active probing that does not possess the
pre-shared authentication cookie.

### VLESS
VLESS is a lightweight protocol that strips authentication from the protocol
header. It relies on a UUID for client identification and optionally wraps in
TLS (XTLS/XUDP) for traffic obfuscation. Because it carries no encryption at
the protocol layer, pairing with TLS transport is recommended. The X-ray
implementation also supports XUDP for reduced overhead on supported clients.

### VMess
VMess provides built-in encryption at the protocol level. Each message body is
encrypted and authenticated using a shared UUID-derived key. Configurable
encryption algorithms include AES (128/256), ChaCha20-Poly1305, and auto-select
mode that negotiates between client and server. A random salt in each request
header prevents replay attacks and traffic pattern analysis.

### Trojan
Trojan disguises proxy traffic inside a genuine TLS session. The client
authenticates with a pre-shared password (hashed via SHA-224). Once the TLS
handshake completes, proxied data flows through the tunnel with no additional
proxy-level encryption—all confidentiality comes from TLS itself. Since it runs
on standard port 443, middlebox traffic typically classifies it as ordinary HTTPS.

### ShadowSocks (SS)
ShadowSocks uses a pre-shared key with a stream or AEAD cipher. Modern
recommended ciphers are AEAD-based (AES-128/256-GCM, ChaCha20-Poly1305) which
provide both confidentiality and integrity. Older stream ciphers (RC4-MD5,
AES-CFB) are deprecated and should be avoided. The 2022 edition of the protocol
adds stronger key derivation (HKDF) to resist replay and probing attacks.

### Hysteria
Hysteria is a high-throughput protocol built on top of QUIC (HTTP/3 over UDP).
It uses a modified congestion-control algorithm (Brutal) to maximise bandwidth
on lossy networks. Authentication is done via a pre-shared password, and all
traffic is encrypted through the QUIC/TLS 1.3 layer. Hysteria excels in high
packet-loss environments where TCP-based protocols stall significantly.

### WireGuard
WireGuard is a modern, kernel-level VPN protocol with a minimal attack surface.
It uses Curve25519 for key exchange, ChaCha20 for symmetric encryption, and
BLAKE2s for hashing. Configuration is handled via public-key peer definitions
rather than certificates. Port forwarding and roaming are first-class features.
Its small codebase (~4,000 LOC) makes it easy to audit and formally verify.

### TUIC
TUIC (TUIC Is a UDP-based Connection protocol) combines TLS 1.3 session
negociation with UDP multiplexing. Like Hysteria it avoids TCP head-of-line
blocking, but focuses on low-latency UDP relay. Each stream within a TUIC
connection is independently congestion-controlled, and authentication relies on
a UUID + password pair. TUIC v5 also supports QUIC command channels for
multiplexed control messages inside the same UDP session.

---

## Versioning

* Naive — v1 (naiveproxy)
* VLESS — Xray-core v25+
* VMess — Xray-core v25+
* Trojan — Trojan-GFW / Xray Trojan inbound
* ShadowSocks — shadowsocks-rust (AEAD 2022 preferred)
* Hysteria — v2
* WireGuard — kernel module / wireguard-go
* TUIC — v5 (GETECLOUD reference implementation)
