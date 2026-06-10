# Security Policy

## Supported Versions

We actively maintain and provide security updates for the following
versions of MaxSpeed VPN:

| Version | Supported          |
| ------- | ------------------ |
| 2.x     | ✅ Active support  |
| 1.x     | ⚠️ Maintenance only |
| < 1.0   | ❌ End of life     |

## Reporting a Vulnerability

If you discover a security vulnerability in MaxSpeed VPN, please report
it responsibly. **Do not open public GitHub issues for security bugs.**

### How to Report

- **Email**: security@maxspeedvpn.com (PGP key available on request)
- **Response time**: We acknowledge reports within 48 hours
- **Resolution time**: We target patches within 14 days for critical
  issues, 30 days for high-severity issues
- **Disclosure**: We follow coordinated disclosure. Once a fix is
  published, we credit the reporter (with permission) in our advisory.

### What to Include

1. Description of the vulnerability
2. Steps to reproduce
3. Affected versions
4. Potential impact assessment
5. Suggested mitigation (if any)

## Security Architecture

MaxSpeed VPN is designed with privacy and security as core principles:

- **WireGuard protocol**: Modern, audited cryptography (Noise protocol
  framework, Curve25519, ChaCha20, Poly1305, BLAKE2s)
- **No-logging policy**: We do not collect, store, or transmit user
  activity logs. Our servers run in RAM-only mode
- **Open source**: Full source code is available for independent audit
  at https://github.com/maxspeedvpn/maxspeed-vpn
- **Certificate pinning**: Prevents MITM attacks on our API endpoints
- **Kill switch**: OS-level VPN kill switch prevents traffic leaks
  when the tunnel drops
- **DNS leak protection**: All DNS queries are routed through the VPN
  tunnel with DNS-over-HTTPS (DoH) encryption

## Secure Development Practices

- All code changes require peer review before merging
- Automated SAST scanning on every pull request
- Dependency vulnerability scanning on every build
- Reproducible builds for release verification
- Signed release artifacts with published checksums
- Memory-safe practices in native libraries (bounds checking,
  null-safety enforcement)

## Incident History

| Date       | Severity | Description              | Status   |
| ---------- | -------- | ------------------------ | -------- |
| No incidents reported to date. This table | will be | updated | accordingly. |

## Security Audits

MaxSpeed VPN undergoes independent security audits:

- **2025 Q2**: Network architecture audit by [Audit Firm TBD]
- **2025 Q4**: Full application penetration test by [Audit Firm TBD]

Audit reports will be published upon completion at
https://maxspeedvpn.com/security/audits

## Responsible Disclosure Safe Harbor

We will not pursue legal action against researchers who:
- Make good-faith efforts to avoid privacy violations and service
  interruptions
- Only interact with accounts you own or have explicit permission to
- Report vulnerabilities promptly and allow reasonable time for
  remediation before public disclosure
