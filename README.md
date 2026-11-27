# OpenTransfer

**Your files. Your server. Your control.**

OpenTransfer is an open-source, self-hosted platform for secure external file transfers, designed for organizations that want to operate their own infrastructure.

## Initial technology direction

- Backend: Go
- Admin web: React, TypeScript, Tailwind CSS
- Database: PostgreSQL
- Storage: selectable local disk, NAS-mounted paths and S3-compatible object storage
- Deployment: Docker Compose and native Linux installation
- Service management: systemd on supported Linux distributions

## Security architecture

The product is planned to support two distinct transfer modes:

1. **Server-managed encryption**: the server manages encryption keys and can support server-side inspection workflows.
2. **End-to-end encryption (E2EE)**: files are encrypted on the sender's device; the server stores ciphertext and cannot inspect file contents.

These modes have different capabilities and must be clearly disclosed to administrators and users. E2EE cannot provide server-side malware scanning of plaintext.

## Repository status

The first milestone is the administration web interface. Its dashboard currently uses illustrative demo data and is not connected to a backend. Do not use it to manage production systems.

## Planned milestones

1. Administration UI shell and dashboard.
2. Go API, PostgreSQL schema, configuration and health checks.
3. Secure first-admin bootstrap, authentication, MFA and RBAC.
4. Storage providers: local, NAS path and S3-compatible.
5. Transfer lifecycle, link policies, quotas and audit events.
6. Docker Compose and native Linux/systemd installation.
7. Backup/restore, hardening, tests and independent security review.

## Development

The admin frontend lives in `web/`.

```bash
cd web
npm install
npm run dev
```

This project is under active development. Security features are not production-ready until implemented, tested and reviewed.
