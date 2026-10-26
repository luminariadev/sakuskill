# Security & Ethical Compliance Policy

## 🛡️ Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

---

## 🔒 Security Architecture Overview

SakuSkill adheres to modern DevSecOps and **Strix Dynamic Security Audit** guidelines:

1. **Role-Based Access Control (RBAC)**:
   - Client and Provider roles are segregated.
   - Campus Admin actions (dispute mediation, escrow force-settlement) are strictly guarded behind cryptographic role checks (`RBACMatrix.hasAccess`).

2. **Input Sanitization & Injection Prevention**:
   - Deliverable proofs (Google Drive, GitHub, PDF links) are strictly validated via `UrlSanitizer.isValidDeliverableUrl`.
   - Disallowed protocols (`javascript:`, `data:`, `file:`, `vbscript:`) are rejected.

3. **Escrow Ledger Immutability**:
   - Funds cannot be released unilaterally without submission of verifiable deliverables.
   - Negative wallet balances are prohibited by domain business invariant checks.

4. **Academic Integrity & Anti-Joki Guardrails**:
   - Academic dishonesty ("joki skripsi", "joki ujian", "buatkan makalah kuliah") is strictly prohibited by domain filter algorithms (`UrlSanitizer.containsAcademicCheatingKeywords`).
   - The platform is strictly reserved for legitimate technical, creative, multimedia, and campus organizational services.

---

## 🚨 Reporting a Vulnerability

If you discover a security vulnerability within SakuSkill Mobile:
1. Please do **NOT** open a public issue.
2. Email the maintainer directly at: `rizkianuari83@gmail.com`.
3. Provide a detailed proof of concept (PoC) and remediation suggestion.
4. Vulnerabilities will be addressed and patched within 48 hours.
