# Emergency Procedures — MaxSpeed VPN

This document defines the incident response plan for security events,
data breaches, and critical vulnerabilities affecting MaxSpeed VPN.

---

## Incident Severity Levels

| Level | Description                              | Response Time |
| ----- | ---------------------------------------- | ------------- |
| **P0** | Active data breach, service compromise | Immediate     |
| **P1** | Critical vulnerability, user data risk  | 1 hour        |
| **P2** | Service degradation, partial outage     | 4 hours       |
| **P3** | Minor issue, no user data at risk        | 24 hours      |

---

## Data Breach Response

### Phase 1: Detection (Minutes 0–30)

1. Confirm the breach — validate alerts, rule out false positives
2. Classify severity using the levels above
3. Notify the Incident Response Team (IRT) via emergency channel
4. Begin incident log — record all actions with timestamps

### Phase 2: Containment (Minutes 30–120)

1. Isolate affected servers and services
2. Revoke compromised credentials and API keys
3. Enable emergency firewall rules to block attack vectors
4. Preserve forensic evidence — disk images, logs, network captures
5. Do NOT reboot or modify affected systems yet

### Phase 3: Eradication (Hours 2–24)

1. Identify root cause through log analysis and forensics
2. Patch the exploited vulnerability
3. Rotate all service credentials (API keys, certificates, tokens)
4. Scan all systems for persistence mechanisms (backdoors, etc.)

### Phase 4: Recovery (Hours 24–72)

1. Restore services from known-good backups
2. Verify integrity of all restored systems
3. Monitor for signs of re-compromise
4. Gradually re-enable user traffic

### Phase 5: Post-Incident (Days 3–14)

1. Write full incident report
2. Conduct blameless post-mortem meeting
3. Implement preventive measures
4. Notify affected users per legal requirements
5. Update this document with lessons learned

---

## Vulnerability Reporting & Escalation

### Internal Reports

1. Reporter files issue with `security` label in GitHub
2. Security lead triages within 4 hours
3. Critical: patch target is 72 hours
4. High: patch target is 7 days
5. Medium: patch target is next release cycle
6. Low: backlog for next sprint

### External Reports

All external vulnerability reports go to security@maxspeedvpn.com.
See SECURITY.md for the full responsible disclosure process.

---

## Emergency Contacts

| Role              | Contact                        | Escalation |
| ----------------- | ------------------------------ | ---------- |
| Security Lead     | security@maxspeedvpn.com       | Primary    |
| Project Lead      | lead@maxspeedvpn.com           | Secondary  |
| Infrastructure    | infra@maxspeedvpn.com          | On-demand  |
| Legal             | legal@maxspeedvpn.com          | On-demand  |
| PGP Key           | https://maxspeedvpn.com/pgp    | Always     |

---

## Emergency Communication Channels

- **IRT Slack/Discord**: #security-incidents (restricted access)
- **Status Page**: https://status.maxspeedvpn.com
- **Public Updates**: https://maxspeedvpn.com/blog/security
- **User Notification**: In-app notification + email to affected users

---

## Rollback Procedures

```bash
# Emergency rollback to last known-good release
git revert HEAD
git push origin main
# CI/CD will automatically build and deploy the revert

# Server-side rollback
ssh deploy@infra.maxspeedvpn.com
sudo maxspeedctl rollback --to=last-stable
```

---

## Regulatory Notification

- **GDPR**: Notify supervisory authority within 72 hours if EU user
  data is affected
- **State Laws**: Comply with applicable state breach notification laws
- Notify affected users without undue delay when required
