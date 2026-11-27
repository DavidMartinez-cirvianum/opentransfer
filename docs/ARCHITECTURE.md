# Arquitectura inicial de OpenTransfer

Estado: arquitectura propuesta. Describe comportamiento previsto, no funciones ya implementadas.

## Decisiones de producto

- Backend Go como monolito modular inicial.
- Frontend React, TypeScript y Tailwind CSS.
- PostgreSQL para identidad, permisos, sesiones, invitaciones, carpetas, transferencias, políticas, cuotas y auditoría.
- Almacenamiento configurable: filesystem local, NAS montado por el sistema operativo y S3-compatible.
- Despliegue Docker Compose y Linux nativo con systemd, compartiendo binario y configuración.
- Cifrado de servidor como modalidad inicial; E2EE como modalidad futura independiente y sujeta a revisión.

## Módulos Go

- Identity: usuarios, invitados, invitaciones, MFA y sesiones.
- Authorization: RBAC, permisos y comprobaciones de ámbito.
- Folders: jerarquía lógica, propietario, miembros y permisos.
- Quotas: límites por usuario/carpeta, reservas y reconciliación de consumo.
- Transfers: ciclo de subida, enlaces, expiración y descargas.
- Policy: políticas globales e individuales, rate limits e IP.
- Storage: interfaz y adaptadores local/NAS/S3.
- Crypto: cifrado gestionado por servidor y, en una fase futura, metadatos E2EE.
- Audit: eventos de seguridad y negocio.
- Operations: logs, health checks, actualizaciones, tareas y backups.

## Modelo de datos conceptual

Tablas principales previstas:
- organizations: una organización por instancia en el MVP, dejando el tenant ID preparado donde aporte seguridad.
- users: miembros e invitados; estado, correo verificado, rol y límites individuales.
- invitations: email destinatario, ámbito, permisos, hash del token, creador, expiración, aceptación y revocación.
- sessions: sesiones revocables con hash del identificador y expiración.
- folders: jerarquía lógica, propietario y organización.
- folder_memberships: usuario/invitado, carpeta y permisos concedidos.
- storage_destinations: tipo, configuración no secreta, referencias a secretos y estado.
- transfers: creador, carpeta, destino, tamaño, estado, política de enlace y metadatos criptográficos.
- download_tokens: hash del token, estado, límites y expiración.
- quota_limits: límites por usuario o carpeta.
- quota_reservations: subidas en curso, reserva, caducidad y estado.
- quota_usage: consumo confirmado y actualizado a partir de operaciones verificadas.
- audit_events: eventos anexables, actor, acción, recurso, resultado, fecha y request ID.

Las cargas útiles de archivos nunca se almacenan en PostgreSQL. Las filas tendrán claves y restricciones que eviten referencias cruzadas entre organización, usuario, carpeta y recurso.

## Usuarios invitados y permisos

Un invitado es una identidad externa de privilegio mínimo, no un usuario interno con otro nombre. El backend debe comprobar la pertenencia al ámbito en cada petición. Las invitaciones usan tokens aleatorios de un solo uso y se persiste solo su hash. Deben caducar y poder revocarse.

Permisos iniciales de carpeta: lectura, subida, compartir y administración. Se evitarán reglas ambiguas de denegación/herencia: cada versión definirá la precedencia y la probará expresamente. La invitación a una carpeta nunca habilita navegación fuera de ella. La subida de invitados requiere permiso explícito y cuota propia.

## Cuotas y concurrencia

Se diferencian:
- max_file_size_bytes: tamaño máximo de cada archivo.
- storage_quota_bytes: consumo máximo total asignado a usuario.
- folder_quota_bytes: opcional, para espacios compartidos.
- transfer_limit_bytes: límite propio de una transferencia.

Antes de aceptar el cuerpo de una subida, la API valida tamaño declarado si existe y reserva capacidad en una transacción. Durante el streaming corta al superar max_file_size. Al completar, valida tamaño real, confirma el consumo y asocia el archivo. Si falla, expira o se cancela, la reserva se libera mediante un proceso seguro e idempotente. Las reservas evitan que cargas paralelas sobrepasen la cuota. Un trabajo periódico puede reconciliar contadores a partir de transferencias verificadas, sin sobrescribir operaciones activas.

No se confiará en el navegador para aplicar límites. No se calculará el espacio únicamente por el tamaño enviado por el cliente.

## Carpetas y almacenamiento

Las carpetas serán metadatos lógicos; los IDs de almacenamiento no serán rutas proporcionadas por usuarios. Se evitará construir rutas con nombres de archivos sin sanitización y comprobación de raíz. Los objetos se escribirán fuera del webroot.

La interfaz Storage abstrae los proveedores:
1. Filesystem local.
2. NAS montado por el administrador del sistema (NFS/SMB); validar montaje, propietario, permisos y capacidad.
3. S3-compatible, con TLS y credenciales proporcionadas como secreto.

Cada transferencia permanece ligada al destino elegido. No hay movimientos automáticos entre destinos en el MVP.

## Transferencias y cifrado

### Cifrado gestionado por servidor
- Clave de datos única por archivo o transferencia.
- Cifrado autenticado mediante implementación mantenida.
- Clave de datos envuelta por clave de cifrado raíz mantenida fuera de PostgreSQL y almacenamiento.
- Versionado de formato, algoritmo y material de claves para rotación.
- Nunca implementar primitivas propias.

### E2EE futuro
El cliente cifra y descifra; el servidor recibe ciphertext. Las claves no llegan al servidor y la pérdida de clave puede hacer irrecuperable el archivo. Antivirus, DLP, indexación y previews server-side no pueden inspeccionar el texto claro. Requiere threat model, revisión de protocolo, revisión del cliente web y pruebas de interoperabilidad independientes.

## Auditoría y logs operativos

La auditoría de negocio/seguridad se almacena separada de logs técnicos:
- Auditoría: actor, acción, recurso, timestamp, resultado, request ID y contexto mínimo.
- Logs operativos: eventos estructurados de API, jobs, almacenamiento, SMTP y mantenimiento.

La identidad de la aplicación tendrá permiso de insertar eventos de auditoría pero no de editarlos o borrarlos. No se afirmará que la base de datos es inviolable: un administrador de sistema con control total podría manipularla. Se podrá exportar a un destino externo/SIEM en una fase posterior. Acceder y exportar auditoría generará su propio evento.

Nunca registrar passwords, cookies, bearer tokens completos, claves, URL con secretos o contenido de archivos. Definir retención configurable y minimización de IP/User-Agent.

## Seguridad de identidad y API

- Password hashing Argon2id, nunca cifrado reversible.
- TOTP inicial; WebAuthn después.
- Sesiones Secure, HttpOnly, SameSite, rotación y revocación.
- CSRF token/controles de origen para sesiones por cookie.
- Autorización en servidor y comprobaciones contra IDOR.
- Rate limits, login throttling, límites de subida y cuotas.
- Proxy de confianza configurado explícitamente; no confiar en forwarded headers arbitrarios.
- Tokens de descarga y de invitación aleatorios; guardar hashes.
- Streaming y límites de memoria; no cargar archivos completos en RAM.

## Configuración e instalación

Un único modelo de configuración tipado para Docker y Linux nativo. Parámetros no secretos por archivo o entorno. Credenciales y claves en archivos protegidos o secret manager, nunca devueltos por la API.

Docker Compose no publicará PostgreSQL en interfaces públicas. Instalación nativa prevista con usuario de sistema sin privilegios, directorios separados, systemd y bootstrap seguro. No modificar firewall, SSH, DNS o proxy existentes sin permiso.

## Ciclo de actualización

Los datos persistentes estarán separados de releases y binarios:
- configuración/secrets;
- PostgreSQL y volúmenes;
- archivos/objetos;
- material de claves;
- logs/backups.

Cada versión publicable tendrá un script actualizacionvX.Y.Z.sh en la raíz. El script comprobará versión, permisos, espacio y salud; creará una copia verificable; descargará artefactos versionados con checksum; ejecutará migraciones incrementales; reiniciará solo componentes necesarios; y validará health checks.

Las migraciones seguirán expand-migrate-contract y mantendrán compatibilidad hacia atrás cuando sea posible. No ejecutar docker compose down -v, no borrar volúmenes, no sobrescribir configuración, no regenerar claves y no hacer rollback destructivo automático. El procedimiento completo está en docs/UPDATES.md.

## Backups y recuperación

Una copia utilizable incluye PostgreSQL consistente, archivos/objetos, configuración y el material necesario para recuperar cifrado gestionado por servidor. Las copias estarán cifradas y restauradas periódicamente en un entorno limpio. Las claves se protegerán de forma separada. Las claves E2EE no serán recuperables por el servidor.

## Estado de implementación

El repositorio contiene un prototipo frontend, aún sin API, autenticación, permisos reales, sistema de carpetas, cuotas ni logs del servidor. La arquitectura debe construirse y probarse por fases. No considerar ningún control del frontend como protección hasta que el backend lo aplique.
