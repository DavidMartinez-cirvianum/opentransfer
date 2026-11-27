# Hoja de ruta OpenTransfer

La prioridad inmediata es entregar un instalador reproducible, un modelo de configuración claro y actualizaciones que preserven los datos. Después construiremos los módulos de producto uno a uno.

## Fase 1 — Instalación y operaciones (en curso)

- [x] Instalador Docker Compose con verificaciones previas.
- [x] Instalación nativa inicial con systemd y PostgreSQL externo.
- [x] Configuración privada, secretos generados y separación de datos.
- [x] Almacenamiento local y NAS montado por el sistema.
- [x] Health/readiness endpoints y pruebas de configuración.
- [x] Actualizador por releases, backup de configuración/DB y rollback de código.
- [ ] Asistente web de configuración inicial.
- [ ] Backups programados y restauración probada.
- [ ] S3 compatible como destino de almacenamiento.

## Fase 2 — Identidad y seguridad

- Usuarios, grupos, roles y sesiones revocables.
- Argon2id y MFA TOTP.
- Invitaciones externas y ámbitos de acceso.
- RBAC/ABAC comprobado por el backend.
- Gestión de políticas de sesión, IP, contraseñas y rate limits.

## Fase 3 — Archivos y transferencias

- Subidas y descargas en streaming.
- Cifrado autenticado en reposo y gestión/rotación de claves.
- Enlaces aleatorios con expiración, contraseña, límite de descargas y revocación.
- Cuotas transaccionales y reservas para subidas concurrentes.
- Detección de tipo, antivirus y retención programada.

## Fase 4 — Espacios y colaboración externa

- Carpetas lógicas personales/departamentales/compartidas.
- Proveedores y contactos independientes.
- Portales separados para empleados, invitados y administración.
- Permisos explícitos de lectura, descarga, subida, compartir y administrar.
- Auditoría exportable y logs técnicos diferenciados.

## Fase 5 — Funciones empresariales

- S3 compatible, NAS y múltiples destinos.
- OIDC/SAML, LDAP y Active Directory.
- WebAuthn/passkeys, SIEM/syslog y DLP.
- E2EE como modalidad separada, tras threat model y revisión independiente.
- Alta disponibilidad y clientes adicionales según demanda.

## Criterio de finalización

Una función solo se considerará terminada cuando el backend la aplique, exista una prueba positiva y negativa, se documenten sus límites y el panel refleje su estado real. Un formulario o un botón no equivalen a una política aplicada.
