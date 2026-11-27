# Initial architecture

Status: proposed baseline for the first implementation. This document describes intended behavior, not features already implemented.

## Product decisions

- Backend: Go, organized as a modular monolith for the first release.
- Admin web: React + TypeScript + Tailwind CSS.
- Database: PostgreSQL for identity, authorization, transfer metadata, policy, configuration and audit events.
- Storage: administrators configure one or more destinations: local filesystem, NAS mounted by the operating system, and S3-compatible object storage. A transfer selects one configured destination.
- Deployment: Docker Compose and native Linux installation. Both run the same application binary and use the same configuration model.
- Encryption: each transfer explicitly selects server-managed encryption or end-to-end encryption (E2EE).

## Runtime topology

The browser connects to a single public HTTPS origin. A reverse proxy (Caddy initially, Nginx also supported) terminates TLS and forwards requests to the Go application. The Go application serves the compiled admin UI and exposes a versioned API under `/api/v1`.

The Go application is a modular monolith with clear internal boundaries:

- Identity and access: users, roles, sessions, MFA and recovery.
- Transfers: upload lifecycle, download tokens, expiration and download limits.
- Policy: size limits, quotas, IP rules and organization defaults.
- Storage: provider interface and local/NAS/S3 adapters.
- Cryptography: server-managed encryption and E2EE protocol metadata.
- Audit: append-only security and administrative events.
- Operations: health checks, diagnostics, backup coordination and configuration validation.

PostgreSQL stores metadata, never file payloads. Large file bytes stream between the client, application and configured storage provider; they are not loaded entirely into application memory.

## Storage abstraction

The application uses a storage interface rather than provider-specific code in transfer handlers. Initial adapters:

1. Local filesystem path.
2. NAS path mounted by the host (NFS/SMB mount managed and secured by the system administrator).
3. S3-compatible object storage.

Each configured storage destination has an ID, display name, provider type, health state and policy. Credentials are stored as protected secrets, not returned by the admin API. NAS paths must be pre-mounted and checked for ownership, permissions, capacity and availability. S3-compatible endpoints require TLS unless an administrator explicitly configures a trusted private network endpoint.

The first version should not silently move data between providers. A transfer remains associated with the storage destination selected at creation time.

## Encryption modes

### Server-managed encryption

- Generate a unique data-encryption key (DEK) per file or transfer.
- Encrypt file content with a vetted authenticated-encryption implementation.
- Wrap the DEK with a key-encryption key (KEK) held outside PostgreSQL and outside the file storage.
- Store only the wrapped DEK and required algorithm/version metadata with the transfer record.
- Design key rotation and recovery before production use.
- Never implement cryptographic primitives or key derivation algorithms from scratch.

This mode allows server-side processing such as malware scanning, subject to the configured workflow and temporary plaintext handling controls.

### End-to-end encryption (E2EE)

- Encryption and decryption happen in the sender's and recipient's clients.
- The server receives and stores ciphertext and cannot inspect file contents.
- Transfer keys must not be sent to the server. A link-fragment or separately shared secret can be evaluated as part of a reviewed protocol.
- Losing the recipient-side key means the server cannot recover the file.
- Server-side antivirus, DLP inspection, previews and content indexing cannot inspect E2EE plaintext.

The E2EE protocol requires a separate threat model, browser security review, protocol review and interoperability tests before it is enabled for production. A normal HTTPS website can still be exposed to malicious client-side code if the server or deployment is compromised; this limitation must be documented.

## Identity and security baseline

- Passwords: Argon2id password hashing with parameters calibrated for the deployment; passwords are never reversibly encrypted.
- MFA: TOTP for the initial release; WebAuthn/passkeys can follow.
- Sessions: Secure, HttpOnly, SameSite cookies, short configurable lifetime, rotation and server-side revocation.
- Authorization: role-based access control with least privilege.
- Download links: high-entropy random tokens; store token hashes, not raw bearer tokens.
- Download limits: enforce atomically in PostgreSQL to avoid concurrent downloads exceeding the configured limit.
- IP restrictions: account for reverse proxies, IPv4/IPv6, NAT and trusted-proxy configuration. Never trust arbitrary forwarded-IP headers.
- Abuse controls: rate limits, upload limits, quotas, login throttling and configurable expiration.
- Audit: record security-relevant actions while minimizing personal data and never logging passwords, session cookies, raw link tokens or encryption keys.

## Configuration and deployment

The application uses one typed configuration model across Docker and native Linux. Non-secret configuration may be supplied by a config file and environment variables. Secrets (database password, S3 credentials, server encryption root key and signing keys) are supplied through protected secret files or a supported secret manager.

Native installation is planned to create a dedicated unprivileged system account, application directories, a systemd unit and a first-admin bootstrap flow. The installer must be idempotent, validate configuration, avoid overwriting existing data and never create a default password.

Docker Compose uses persistent volumes and explicit secret handling. It must not publish PostgreSQL directly to the public network.

## Backup and recovery

A usable backup includes a consistent PostgreSQL backup, file/object data, configuration and the key material required to decrypt server-managed files. Backups must be encrypted and restore-tested. A backup that omits encryption keys is not a valid recovery plan. E2EE keys are intentionally not recoverable by the server.

## Admin UI scope — first milestone

The first frontend milestone is a responsive admin shell and dashboard with navigation for:

- Dashboard
- Transfers
- Users and groups
- Security
- Storage
- Domains and HTTPS
- Backups
- Audit and logs
- System configuration

The current dashboard is a visual prototype using illustrative data. It is not connected to an API and must not be used as a production control plane.

## Explicit non-goals for the first milestone

- No production authentication or user management yet.
- No real upload/download implementation yet.
- No claim of production-grade security or compliance.
- No installer that modifies the host yet.
- No E2EE release until its protocol and threat model have been reviewed.
