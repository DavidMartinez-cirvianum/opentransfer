# OpenTransfer MVP

## Goal
Deliver one dependable, self-hosted workflow for an organization to send files to external recipients without creating recipient accounts. The MVP is a secure file-transfer appliance, not a general cloud drive.

## The first complete user journey
1. An administrator installs OpenTransfer on a supported Linux server.
2. The installer creates a dedicated service account, configures the service and guides the operator through first-admin creation.
3. The administrator signs in with MFA and configures the public URL, one storage destination, SMTP (optional for the first local test), and transfer defaults.
4. An authenticated employee uploads a file, chooses an expiration and download limit, and optionally adds a password.
5. OpenTransfer returns a high-entropy download link. The recipient can download without an account, subject to the configured policy.
6. The employee or administrator can revoke the link. Administrators can inspect the transfer's metadata and audit events.
7. Expired or revoked transfer data is removed by a background cleanup job according to retention settings.

## MVP feature boundary

### P0 — required for a usable MVP
- Single organization / single instance.
- One local filesystem storage destination. The storage interface must allow NAS and S3 adapters later.
- PostgreSQL for users, sessions, transfer metadata, policy and audit metadata.
- Go modular monolith; React + TypeScript + Tailwind admin and employee web UI.
- First-admin bootstrap with a one-time setup token or interactive local CLI. Never ship a default password.
- Password hashing with Argon2id; MFA using TOTP; session revocation and secure cookie settings.
- RBAC with at least admin and member roles.
- Upload with streaming and configurable maximum file size.
- Server-managed authenticated encryption at rest using maintained cryptographic packages. Per-file data keys; key-encryption key supplied separately from PostgreSQL and file storage.
- Download links generated from cryptographically secure random tokens; persist only token hashes.
- Optional link password, expiration, maximum download count, manual revocation.
- Atomic download-count enforcement to prevent concurrent requests exceeding the limit.
- Basic per-user quotas, rate limits and login throttling.
- Audit events for sign-in, failed sign-in, upload, download, revocation, policy and admin changes.
- HTTPS deployment guidance, health checks, structured logs and tested backup/restore procedure.
- Docker Compose deployment first. Native systemd installation follows once the same configuration and lifecycle are stable.

### P1 — after the first end-to-end release
- NAS storage destination via a host-mounted path, with mount/permission/health validation.
- S3-compatible storage adapter.
- Multiple storage destinations and per-transfer destination selection.
- SMTP notifications and branded email templates.
- IP allow/deny policies and trusted-proxy configuration.
- Configurable retention, backup schedules and restore wizard.
- WebAuthn/passkeys, stronger role granularity and group management.
- Caddy-assisted domain and TLS setup.

### P2 — advanced / business roadmap
- E2EE transfer mode, only after a separately reviewed protocol and browser threat model.
- OIDC / SAML SSO, LDAP / Active Directory.
- Malware scanning, DLP integrations and advanced compliance exports.
- Desktop and mobile clients.
- Multi-tenant hosting, clustering, high availability and enterprise support.

## Explicit non-goals for MVP
- Not a replacement for Nextcloud or a team file-sync drive.
- No public anonymous upload portal in the first release.
- No claim that the system is unhackable or automatically GDPR-compliant.
- No custom cryptography.
- No E2EE and server-readable encryption on the same transfer. They are distinct modes with different security and operational properties.
- No multi-node clustering or automatic replication between storage providers.
- No installer that silently changes firewall, SSH, DNS or existing reverse-proxy configuration.

## Admin panel navigation
1. Overview: setup checklist, service health, storage health and recent security events.
2. Transfers: search, inspect, revoke and view expiration / download counts.
3. Users: create, disable and assign roles; reset access safely.
4. Security: password policy, MFA requirement, session lifetime, link defaults, rate limits and IP policy.
5. Storage: configure and test local path; later NAS and S3.
6. Domain & TLS: public URL and reverse-proxy / certificate status.
7. Backups: destination, last successful backup, restore guidance and key-material warning.
8. Audit: filter security and administrative events.
9. System: version, health, logs, configuration validation and maintenance.

A control must not be presented as active until the backend enforces it. The UI must distinguish saved server settings from local draft values and must never display secrets after they are saved.

## Security acceptance criteria
- Unauthenticated users cannot access admin APIs or private transfer metadata.
- Admin endpoints enforce authorization server-side; hiding UI controls is not authorization.
- Passwords, session identifiers, raw download tokens and encryption keys never appear in logs.
- Download token hashes are compared safely and tokens have sufficient entropy.
- Concurrent download attempts cannot exceed the configured download count.
- Expiration and revocation block new downloads immediately.
- Uploads enforce size limits while streaming and do not trust client-provided filename or MIME type.
- File storage is outside the public web root and cannot be executed as web content.
- CSRF, XSS, SQL injection, path traversal and IDOR tests are included.
- Encryption keys are stored separately from database and file backups; recovery is tested.
- Backup restore is tested on a clean environment.
- Dependency scanning, static analysis and an independent security review are completed before production security claims.

## Current repository status
The current React admin interface is a visual prototype. It is not connected to a backend, does not authenticate users and does not apply real security settings. The MVP implementation starts with the Go API, PostgreSQL migrations, secure first-admin bootstrap and the first end-to-end upload/download path.
