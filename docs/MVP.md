# OpenTransfer MVP

## Objetivo

Entregar un flujo autoalojado y administrable para que una organización almacene, organice y comparta archivos con usuarios internos e invitados externos, con políticas de seguridad y trazabilidad. No es una suite general de sincronización de archivos.

## Usuarios y acceso

### Roles iniciales
- **Administrador:** configura la instancia, usuarios, políticas, almacenamiento y auditoría.
- **Miembro:** crea y gestiona sus transferencias y carpetas según sus permisos.
- **Invitado:** cuenta externa limitada al contenido o carpeta que se le ha compartido. No tiene acceso general a la organización ni al panel administrativo.

El backend aplicará siempre la autorización. Ocultar un botón en React no es un control de seguridad.

### Invitaciones
- Invitación por correo con token aleatorio de un solo uso y caducidad.
- Posibilidad de revocar invitaciones pendientes y accesos concedidos.
- Ámbito explícito: una transferencia o carpeta concreta.
- Verificación de correo; MFA según política cuando el riesgo lo requiera.
- Subida por parte de invitados desactivada por defecto; un miembro autorizado o administrador podrá concederla expresamente.
- Límites propios para invitados y registro de aceptación, expiración y revocación.

## Carpetas

- Carpetas personales y compartidas para organizar archivos y transferencias.
- Jerarquía lógica de carpetas; el cliente nunca construye rutas físicas del almacenamiento.
- Propietario y permisos de lectura, subida, compartición y administración.
- Permisos heredados de forma explícita y comprobada en servidor.
- Compartir una carpeta con un invitado no da acceso a otras carpetas ni a la organización.
- No incluye sincronización de escritorio, edición colaborativa ni gestión documental general.

## Cuotas y límites

Deben distinguirse:
1. **Máximo por archivo:** tamaño máximo de cada subida.
2. **Cuota total por usuario:** máximo de GB ocupados por archivos atribuibles al usuario.
3. **Cuota de carpeta/espacio compartido:** opcional, cuando se implemente la administración de espacios compartidos.
4. **Límites de transferencia:** expiración, número máximo de descargas y tamaño permitido.

El administrador podrá definir valores predeterminados y excepciones por usuario. El panel mostrará cuota asignada, uso confirmado, subidas pendientes y espacio disponible. Los invitados tendrán límites restringidos propios; por defecto no podrán subir.

El servidor reservará cuota al iniciar una subida, validará el flujo mientras recibe datos, confirmará el tamaño final y liberará reservas ante errores o cancelaciones. Las reservas y consumos se actualizarán de forma transaccional para impedir que subidas simultáneas superen los límites. Los archivos eliminados o cuya retención expire liberarán espacio según la política y el resultado real del borrado.

## Flujo de transferencia

1. Un miembro autenticado elige una carpeta y sube un archivo.
2. El servidor aplica permisos, cuota, límite por archivo y política de almacenamiento.
3. OpenTransfer crea un enlace de descarga con token de alta entropía; la base de datos guarda solo el hash del token.
4. El propietario puede fijar expiración, contraseña opcional y número máximo de descargas.
5. El destinatario descarga según la política. Puede ser un destinatario por enlace o un invitado autenticado con acceso a una carpeta.
6. El propietario o un administrador revoca el enlace; la revocación y caducidad bloquean nuevas descargas.
7. Los datos se eliminan de acuerdo con la política de retención y las reglas de backup.

## Auditoría y logs

La auditoría y los logs técnicos son funciones distintas.

### Auditoría de seguridad y negocio
Registrar, como mínimo:
- Inicios de sesión, cierres de sesión, MFA, fallos y revocación de sesiones.
- Creación, desactivación y cambios de rol de usuarios.
- Invitaciones enviadas, aceptadas, expiradas y revocadas.
- Creación de carpetas, cambios de permisos y comparticiones.
- Subidas iniciadas, completadas, rechazadas y canceladas.
- Descargas, enlaces creados, expirados y revocados.
- Cuotas y políticas modificadas o alcanzadas.
- Cambios de almacenamiento, configuración, backups y actualizaciones.
- Consulta y exportación de registros de auditoría.

Cada evento tendrá fecha, actor, acción, recurso, resultado y request ID; IP y datos de cliente se guardarán solo cuando sean necesarios y conforme a una política de retención. La auditoría será de solo anexado para el rol de aplicación, con acceso administrativo restringido.

### Logs operativos
Logs estructurados para API, base de datos, tareas en segundo plano, almacenamiento, correo y mantenimiento. Incluirán niveles y request ID para diagnóstico. No contendrán contraseñas, cookies, tokens completos, claves, URLs con secretos ni contenido de archivos.

## P0 — MVP funcional

- Una organización y una instancia.
- Go modular monolith, API versionada, React + TypeScript + Tailwind.
- PostgreSQL para identidad, permisos, metadatos, cuotas, políticas y auditoría.
- Almacenamiento local inicial, fuera del webroot, mediante una interfaz que permita NAS y S3 posteriormente.
- Primer administrador mediante CLI o token de configuración de un solo uso; nunca una contraseña predeterminada.
- Argon2id, TOTP, sesiones seguras/revocables y RBAC.
- Usuarios internos y rol invitado limitado, con invitaciones seguras por correo.
- Carpetas personales y compartidas con permisos comprobados en backend.
- Cuota total por usuario y máximo por archivo, con reservas concurrentes.
- Subidas y descargas en streaming.
- Cifrado gestionado por el servidor en reposo con claves fuera de PostgreSQL y almacenamiento.
- Enlaces protegidos, contraseña opcional, expiración, límite de descargas y revocación.
- Auditoría de acciones sensibles y logs técnicos estructurados.
- Límites de tasa, protección de inicio de sesión, límites de tamaño y validación de configuración.
- Docker Compose para desarrollo y primer despliegue controlado; instalación Linux nativa posteriormente.
- Health checks, copias de seguridad y procedimiento de restauración probado antes de producción.

## P1 — después del primer flujo completo

- NAS mediante ruta montada y validación de salud/permisos.
- Almacenamiento S3-compatible y selección de destino por transferencia.
- Cuotas por espacios compartidos y grupos.
- SMTP completo, plantillas y notificaciones.
- Política de IP y configuración de proxy de confianza.
- Exportación avanzada de auditoría, syslog/SIEM y retención programada.
- WebAuthn/passkeys y roles administrativos granulares.
- Instalador nativo systemd y actualizaciones incrementales versionadas.

## P2 — hoja de ruta empresarial

- E2EE con protocolo, modelo de amenazas y revisión independiente.
- OIDC/SAML, LDAP y Active Directory.
- Antivirus/DLP.
- Aplicaciones de escritorio y móviles.
- Alta disponibilidad y multi-nodo.

## No objetivos

- No es un sustituto completo de Nextcloud, Dropbox o un sistema de sincronización.
- No se habilita subida anónima pública por defecto.
- No se promete seguridad absoluta ni cumplimiento RGPD automático.
- No se implementa criptografía propia.
- No se mezclan E2EE y contenido legible por el servidor en una misma transferencia.
- No se hace migración silenciosa de archivos entre proveedores.
- No se modifican firewall, SSH, DNS ni proxy existente sin consentimiento.

## Navegación del panel de administración

1. Resumen y estado de la instancia.
2. Transferencias.
3. Carpetas y permisos.
4. Usuarios internos.
5. Invitados e invitaciones.
6. Cuotas y límites.
7. Seguridad y sesiones.
8. Almacenamiento.
9. Dominio y HTTPS.
10. Copias de seguridad.
11. Auditoría.
12. Logs técnicos.
13. Sistema y actualizaciones.

Un control solo se mostrará como activo cuando el backend lo aplique y existan pruebas. Los secretos no se devolverán por API ni se volverán a mostrar después de guardarlos.

## Criterios de aceptación de seguridad

- No hay acceso sin autenticación a la administración o metadatos privados.
- Permisos y límites comprobados en backend en cada operación.
- Invitados aislados a la carpeta/transferencia autorizada.
- No hay acceso horizontal entre usuarios, carpetas u organizaciones.
- Las cuotas resisten subidas simultáneas, fallos, cancelaciones y reintentos.
- Los tokens se generan con CSPRNG y solo se guardan sus hashes.
- La expiración y revocación bloquean el acceso inmediatamente.
- Las subidas se validan en streaming; no se confía en nombre o MIME del cliente.
- No hay traversal, IDOR, SQLi, XSS ni CSRF en los flujos probados.
- Los logs y auditoría no contienen secretos.
- Las claves están separadas de la base de datos y los archivos; recuperación probada.
- Restauración de backup probada en entorno limpio.
- Análisis de dependencias, pruebas de seguridad y revisión independiente antes de afirmar que está listo para producción.

## Estado actual del repositorio

El panel React es un prototipo visual. No está conectado al backend, no autentica usuarios, no persiste carpetas ni cuotas y no registra eventos reales. La implementación comienza por la base Go/PostgreSQL y después aborda usuarios, invitados, carpetas y límites. Este documento define el objetivo; no afirma que esas funciones ya existan.
