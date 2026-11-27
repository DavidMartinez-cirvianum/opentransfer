# OpenTransfer — plan de desarrollo por fases

Este documento es el plan de producto y ejecución. Cada fase se cierra con criterios verificables antes de avanzar. Decir «siguiente fase» significa continuar con la fase siguiente de esta lista, conservando las decisiones ya tomadas.

## Principios del producto

- Autoalojado: la organización controla su servidor, sus datos y sus políticas.
- Transferencias externas seguras: no pretende ser una suite de sincronización de archivos.
- Administración detallada: usuarios, invitados, cuotas, carpetas, permisos, transferencias, seguridad, auditoría y diagnóstico.
- Seguridad aplicada en el servidor: la interfaz nunca será la única barrera de autorización.
- Actualizaciones incrementales: conservar datos, configuración, claves y personalizaciones; migrar solo lo necesario.
- No declarar una función lista hasta que esté implementada, probada y conectada al backend.

## Modelo funcional acordado

### Usuarios internos
Cuentas pertenecientes a la organización. Tendrán rol, estado, sesiones, MFA y límites individuales. Un administrador podrá establecer límites predeterminados y excepciones por usuario.

### Invitados externos
Se crearán mediante invitación por correo. La invitación tendrá caducidad, podrá revocarse y concederá acceso únicamente a la carpeta o transferencia indicada. Un invitado no será un miembro normal ni podrá consultar el resto de la organización. La subida para invitados estará desactivada por defecto y solo se habilitará mediante permiso explícito.

### Carpetas
Carpetas lógicas para organizar archivos y transferencias. Podrán ser personales o compartidas. Tendrán propietario y permisos explícitos de lectura, subida, compartición y administración. Compartir una carpeta con un invitado no le dará acceso global. OpenTransfer no implementará sincronización de escritorio ni edición colaborativa de documentos en el MVP.

### Límites y cuotas
Se configurarán por separado:
- Tamaño máximo de un archivo por subida.
- Cuota total de almacenamiento asignada a cada usuario.
- Opcionalmente, cuota de una carpeta o espacio compartido.
- Límites de transferencia: caducidad, descargas y tamaño total permitido.

El servidor comprobará los límites antes y durante la subida. Reservará cuota para cargas en curso, recalculará el tamaño real al terminar y liberará la reserva si falla o se cancela. Las comprobaciones serán transaccionales para que dos subidas simultáneas no superen la cuota.

### Auditoría y logs
- Auditoría: eventos de seguridad y acciones de usuario/administrador, con actor, acción, recurso, fecha, resultado y contexto mínimo necesario.
- Logs técnicos: funcionamiento de API, tareas, errores, almacenamiento y actualizaciones.
- No registrar contraseñas, cookies, tokens completos, claves ni contenido de archivos.
- Acceso, exportación y cambios en las políticas de retención de auditoría también quedarán auditados.

## Fases

### Fase 1 — Definición del producto y panel de administración (actual)
**Objetivo:** fijar el alcance, el modelo de permisos y la experiencia administrativa antes de construir backend.

Incluye:
- Navegación del panel para transferencias, carpetas, usuarios, invitados, cuotas, seguridad, almacenamiento, auditoría, logs y sistema.
- Especificación de roles, invitados, permisos de carpetas, cuotas y eventos.
- Arquitectura de datos y contrato de actualizaciones incrementales.
- Identificación explícita de lo que es prototipo y no funciona todavía.

**Cierre:** documentación coherente, decisiones de producto registradas y panel prototipo alineado con esas decisiones. No implica que el sistema sea instalable ni esté listo para producción.

### Fase 2 — Base técnica, API e identidad
**Objetivo:** crear una aplicación ejecutable y una base segura.

Incluye:
- Servicio Go modular, API versionada y endpoints de salud/readiness.
- PostgreSQL y migraciones versionadas.
- Configuración validada y gestión separada de secretos.
- Primer administrador mediante CLI o token de un solo uso, sin contraseña predeterminada.
- Inicio/cierre de sesión, sesiones revocables, Argon2id, TOTP y RBAC inicial.
- Registro de auditoría base y pruebas de autorización.
- Entorno Docker Compose de desarrollo y pruebas.

**Cierre:** arranque reproducible, migraciones probadas, bootstrap de administrador seguro y API protegida. Aún no habrá transferencias completas.

### Fase 3 — Usuarios, invitados, carpetas y cuotas
**Objetivo:** construir la gestión de acceso y capacidad.

Incluye:
- Alta, edición, desactivación y restauración controlada de usuarios.
- Invitaciones por correo con token de un solo uso, caducidad y revocación.
- Rol guest aislado y permisos limitados al recurso compartido.
- Carpetas personales y compartidas, estructura lógica y permisos por carpeta.
- Asignación individual de roles y límites.
- Tamaño máximo de archivo, cuota total por usuario y, cuando proceda, por carpeta.
- Reservas de cuota para subidas simultáneas y liberación segura ante cancelaciones.
- Historial de invitaciones, cambios de permisos y consumo.

**Cierre:** pruebas que demuestren que un invitado no puede salir del ámbito invitado, que no hay acceso entre usuarios/carpetas sin permiso y que las cuotas resisten cargas concurrentes.

### Fase 4 — Motor de transferencias
**Objetivo:** completar la ruta principal de envío y descarga.

Incluye:
- Subidas y descargas en streaming.
- Almacenamiento local fuera del directorio público.
- Enlaces de alta entropía almacenando solo el hash del token.
- Caducidad, contraseña opcional, revocación y límite de descargas atómico.
- Cifrado gestionado por el servidor en reposo, con claves separadas de la base de datos y los archivos.
- Asociación de transferencias a usuario y carpeta.
- Políticas para que un invitado solo pueda operar sobre lo que se le ha compartido.
- Pruebas de tamaño, MIME, nombres, rutas y concurrencia.

**Cierre:** flujo real de subida, creación de enlace, descarga, revocación y borrado/retención controlados.

### Fase 5 — Centro de administración, auditoría y observabilidad
**Objetivo:** convertir el panel en una herramienta real para IT.

Incluye:
- Panel conectado a datos reales: actividad, capacidad, salud y tareas pendientes.
- Búsqueda y filtros de usuarios, invitados, carpetas y transferencias.
- Auditoría consultable, exportable y con retención configurable.
- Logs técnicos estructurados, niveles, filtros y correlación por request ID.
- Vista de sesiones, intentos fallidos, límites alcanzados y eventos anómalos.
- Políticas globales y excepciones individuales.
- Notificaciones administrativas relevantes.

**Cierre:** cada acción sensible aparece en auditoría, los logs no contienen secretos y los permisos del panel se verifican en el backend.

### Fase 6 — Instalación, mantenimiento y actualizaciones
**Objetivo:** facilitar el despliegue y las actualizaciones sin pérdida de datos.

Incluye:
- Docker Compose documentado y versionado.
- Instalación Linux nativa con usuario de sistema sin privilegios y servicio systemd.
- Comprobación previa, copia de seguridad, migraciones y comprobación de salud.
- Un script en la raíz por cada versión publicable: actualizacionvX.Y.Z.sh.
- Actualización por componentes y migraciones incrementales; nunca reinstalar volúmenes o borrar datos.
- Informe de actualización y procedimiento de recuperación.

**Cierre:** pruebas de actualización desde la versión anterior en una instalación con datos reales de prueba, configuración personalizada y claves; verificar que todo se conserva.

### Fase 7 — Almacenamiento, copias y comunicaciones
**Objetivo:** ampliar opciones operativas.

Incluye:
- NAS mediante montaje del host y validación de permisos/salud.
- Almacenamiento S3-compatible.
- Selección de destino por transferencia y monitorización de capacidad.
- SMTP y plantillas de correo.
- Backups consistentes de base de datos, archivos, configuración y material de claves, con cifrado y restauración verificada.

**Cierre:** pruebas de fallos de almacenamiento y restauración completa en un entorno limpio.

### Fase 8 — Funciones empresariales avanzadas
**Objetivo:** ampliar integraciones y modalidades avanzadas después de asegurar el núcleo.

Incluye:
- E2EE con protocolo y modelo de amenazas revisados de forma independiente.
- OIDC/SAML, LDAP y Active Directory.
- Antivirus/DLP e integración SIEM/syslog.
- WebAuthn/passkeys y roles más granulares.
- Clientes móviles y de escritorio.
- Alta disponibilidad y despliegues multi-nodo, si existe demanda real.

**Cierre:** cada integración con pruebas de seguridad, documentación de límites y revisión específica. E2EE seguirá siendo un modo distinto del cifrado gestionado por servidor.

## Cómo trabajaremos

1. Avanzaremos una fase cada vez.
2. Antes de cerrar cada fase se revisarán criterios de aceptación y pruebas.
3. No se marcarán como terminadas funciones que solo tengan diseño visual.
4. Cada versión que cambie una instalación publicable incluirá su script actualizacionvX.Y.Z.sh y notas de versión.
5. No se creará un actualizador ficticio mientras no exista una instalación ejecutable que actualizar.
