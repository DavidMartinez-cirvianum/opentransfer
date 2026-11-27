# OpenTransfer

**Your files. Your server. Your control.**

OpenTransfer is an open-source, self-hosted platform for secure external file transfers. It is designed for organizations that want to operate their own infrastructure and control how external recipients access shared files.

## MVP direction

The first release focuses on one complete workflow: an authenticated employee uploads a file, creates a protected download link, and can later revoke it. An administrator controls users, security policies, storage and audit history.

See [the MVP scope](docs/MVP.md) for the feature boundary and release acceptance criteria.

## Technology

- Backend: Go modular monolith
- Web interface: React, TypeScript and Tailwind CSS
- Database: PostgreSQL
- Initial storage: local filesystem, with an abstraction for NAS and S3-compatible providers
- Deployment: Docker Compose first; native Linux/systemd installation after the service lifecycle is stable

## Encryption

The architecture distinguishes two modes:

- **Server-managed encryption:** the server manages encryption keys and may support server-side inspection workflows.
- **End-to-end encryption (E2EE):** encryption and decryption happen in clients; the server stores ciphertext and cannot inspect file contents.

The MVP starts with server-managed encryption at rest. E2EE is a later milestone and requires a separately reviewed protocol and threat model. The two modes have different capabilities; E2EE content cannot be scanned by server-side antivirus.

## Repository status

The admin frontend is currently a navigation and setup-flow prototype. It is not connected to a backend, does not authenticate users and does not apply real security policies. Do not expose it as a production administration interface.

## Development

```bash
cd web
npm install
npm run dev
```

The Go API, PostgreSQL schema, secure administrator bootstrap and upload/download workflow are the next implementation milestones.

## Security notice

OpenTransfer is under active development. It is not production-ready and must not be used for sensitive production transfers until authentication, authorization, cryptography, upload handling, backup/restore and security testing have been implemented and reviewed. No software can be guaranteed unhackable.
