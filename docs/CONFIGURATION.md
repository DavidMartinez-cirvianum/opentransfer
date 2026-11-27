# Configuración de OpenTransfer

La configuración de la instancia se guarda en `/etc/opentransfer/instance.env` (por defecto). El instalador genera secretos aleatorios y establece permisos `0600`. No subas el archivo a Git, no lo adjuntes a incidencias y no copies sus secretos en logs.

## Variables actuales

| Variable | Descripción | Valor inicial |
|---|---|---|
| `OT_LISTEN_ADDR` | Dirección HTTP interna (modo nativo) | `127.0.0.1:8080` |
| `OT_PUBLIC_URL` | URL pública anunciada a los usuarios | URL definida durante instalación |
| `OT_LOG_LEVEL` | Nivel de logs: debug/info/warn/error | `info` |
| `OT_DATABASE_URL` | URL de PostgreSQL | Generada en Docker; externa en native |
| `OT_STORAGE_BACKEND` | `local` o `nas` montado en Linux | `local` |
| `OT_STORAGE_LOCAL_PATH` | Ruta absoluta del almacenamiento | `/var/lib/opentransfer/files` |
| `OT_ENCRYPTION_KEY` | Clave aleatoria de 32 bytes codificada en base64 | Generada por instalación |
| `OT_BIND_ADDRESS` | Interfaz host publicada por Docker | `127.0.0.1` |
| `OT_HTTP_PORT` | Puerto host publicado por Docker | `8080` |
| `OT_POSTGRES_DATA_DIR` | Directorio host de PostgreSQL | `/var/lib/opentransfer/postgres` |
| `POSTGRES_DB` | Base de datos inicial de Docker | `opentransfer` |
| `POSTGRES_USER` | Usuario inicial de Docker | `opentransfer` |
| `POSTGRES_PASSWORD` | Secreto inicial de PostgreSQL Docker | Aleatorio |

## Recomendaciones

- Conserva `OT_ENCRYPTION_KEY` en un gestor de secretos y en una copia de recuperación cifrada separada. Perderla puede impedir recuperar archivos cifrados en futuras versiones.
- No cambies `POSTGRES_PASSWORD` a mano sin actualizar también la contraseña del rol PostgreSQL.
- Mantén `OT_BIND_ADDRESS=127.0.0.1` cuando el proxy inverso esté en el mismo servidor.
- Si el proxy está en otra máquina, define una interfaz privada, restringe el tráfico en la red corporativa y configura explícitamente la política de firewall. El instalador no abre puertos.
- Usa TLS entre proxy y servicio cuando atraviese una red no confiable.
- No uses `OT_LOG_LEVEL=debug` en entornos con datos reales salvo para una investigación controlada.

## NAS

Para NFS/SMB el administrador monta primero el recurso en el host. Selecciona `OT_STORAGE_BACKEND=nas` y define `OT_STORAGE_LOCAL_PATH` a la ruta montada. La aplicación trata ese punto de montaje como un filesystem local. Deben probarse permisos, disponibilidad tras reinicios, locking y rendimiento en la infraestructura concreta.

## Límites de implementación

La base actual valida estas variables y usa PostgreSQL/almacenamiento para checks de disponibilidad. Todavía no hay transferencias, cuotas, carpetas, usuarios, MFA ni cifrado de archivos implementados. Los valores que se incorporen para esos módulos se documentarán aquí cuando el backend los aplique y tengan pruebas. No configures una opción pensando que ya impone una política que aún no existe.
