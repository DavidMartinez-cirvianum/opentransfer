# Seguridad y límites conocidos

OpenTransfer está en desarrollo. No lo uses todavía para transferencias sensibles ni lo expongas directamente a Internet como si fuera un producto terminado.

## Controles de esta base

- Contenedor sin root, filesystem raíz de solo lectura y capacidades Linux eliminadas.
- PostgreSQL sin puerto publicado en el host en el despliegue Compose.
- Publicación HTTP limitada a localhost por defecto.
- Configuración privada con permisos 0600 y secretos aleatorios en la instalación inicial.
- Servicio systemd con aislamiento y privilegios mínimos.
- Cabeceras HTTP básicas y logs JSON.
- Separación entre código versionado, configuración y datos persistentes.
- Actualización por releases, con conservación del release anterior y comprobación de salud.

## Aún no implementado

No hay todavía autenticación, panel de administración conectado, usuarios, MFA, permisos, carpetas, transferencias, cuotas, tokens de descarga, auditoría de negocio, análisis antivirus ni cifrado de archivos. La clave `OT_ENCRYPTION_KEY` se genera y se conserva para el diseño de almacenamiento cifrado, pero esta versión no cifra todavía los archivos. El endpoint `/readyz` solo prueba conectividad TCP a PostgreSQL, no autenticación o integridad de esquema.

No declares cumplimiento RGPD, E2EE o seguridad empresarial hasta que esos módulos estén implementados, revisados y probados.

## Operación segura

- Configura TLS mediante un proxy inverso mantenido por la organización.
- Restringe el acceso administrativo a redes de confianza.
- Aplica backups cifrados y prueba restauraciones.
- Conserva las claves fuera del servidor principal con acceso controlado.
- Revisa logs y permisos del filesystem.
- Actualiza solo desde etiquetas/versiones revisadas.
- No registres credenciales ni contenido de documentos.
