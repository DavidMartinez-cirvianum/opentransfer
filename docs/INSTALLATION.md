# Instalación de OpenTransfer

Estado: primera base de instalación y diagnóstico. No es todavía una suite de transferencia lista para producción.

## Requisitos

- Linux x86_64 o ARM64.
- 2 GiB libres como mínimo en el volumen de instalación y 2 GiB de RAM recomendados.
- Docker Engine + Docker Compose v2 para el modo recomendado.
- Para modo nativo: systemd y Go 1.23 o posterior.
- La instalación automática de PostgreSQL está disponible en Debian/Ubuntu mediante APT. En otras distribuciones se puede conectar a un PostgreSQL existente.
- HTTPS terminado en un proxy inverso administrado por la empresa cuando el servicio se exponga fuera de localhost.

El instalador no instala Docker ni modifica firewall, SSH, DNS, Nginx, Caddy o certificados. En modo nativo puede instalar PostgreSQL localmente si se elige esa opción.

## Instalación Docker Compose

Desde una copia clonada del repositorio:

```bash
sudo ./install.sh
```

Instalación no interactiva con valores explícitos:

```bash
sudo ./install.sh --mode docker --bind 127.0.0.1 --port 8080 \
  --storage local --storage-path /var/lib/opentransfer/files --yes
```

El modo Docker usa PostgreSQL privado en una red interna de Compose. La base de datos no publica ningún puerto en el host. La aplicación se publica por defecto en `127.0.0.1:8080`, lista para un proxy inverso local.

## Instalación Linux nativa

La instalación nativa puede configurar PostgreSQL de dos formas. Si ejecutas el asistente de forma interactiva, te preguntará cuál prefieres:

1. **Instalar PostgreSQL localmente (recomendado):** en Debian/Ubuntu instala los paquetes mediante APT si faltan, inicia el servicio, crea un usuario y una base de datos exclusivos para OpenTransfer, genera una contraseña aleatoria y guarda la conexión en el archivo privado de configuración.
2. **Usar un PostgreSQL existente:** te pedirá la URL de conexión con la contraseña oculta mientras escribes.

La opción automática requiere permisos root y conexión a los repositorios APT. No altera roles ni bases de datos existentes: si encuentra el nombre elegido ocupado, se detiene sin modificarlo. Puedes elegir otro nombre con `--postgres-db` y `--postgres-user`.

### Instalación interactiva

```bash
sudo ./install.sh
```

Selecciona `native`, configura la IP/puerto y el almacenamiento. Cuando pregunte por PostgreSQL, pulsa Enter para instalarlo localmente o elige la opción 2 para introducir una conexión existente.

### Instalación automática no interactiva

En Debian/Ubuntu, el siguiente comando instala PostgreSQL si es necesario y prepara una base de datos propia:

```bash
sudo ./install.sh --mode native --postgres install \
  --bind 192.168.56.101 --port 5173 --yes
```

También puedes indicar nombres distintos para evitar colisiones con bases de datos que ya existan:

```bash
sudo ./install.sh --mode native --postgres install \
  --postgres-db opentransfer_prod --postgres-user opentransfer_app \
  --bind 192.168.56.101 --port 5173 --yes
```

### Usar PostgreSQL existente

```bash
sudo ./install.sh --mode native --postgres external \
  --bind 192.168.56.101 --port 5173
```

El instalador solicita la URL de PostgreSQL sin mostrarla en pantalla. Para automatización también acepta `--database-url`, aunque los argumentos de línea de comandos pueden ser visibles temporalmente en la lista de procesos y quedar en el historial del shell; para contraseñas es preferible el prompt oculto.

Ejemplo de URL:

```
postgres://opentransfer:CONTRASEÑA@127.0.0.1:5432/opentransfer?sslmode=disable
```

Si la contraseña contiene caracteres reservados de URL, codifícalos porcentualmente. Usa TLS y el modo SSL apropiado cuando PostgreSQL esté en otra máquina o la conexión atraviese una red no confiable.

### Distribuciones distintas de Debian/Ubuntu

La instalación automática mediante APT no se ejecuta en Fedora, RHEL, Arch u otras familias. Instala PostgreSQL según la documentación de tu distribución y usa `--postgres external` para introducir la URL local o remota.

La dirección `--bind` es la interfaz de red en la que escuchará OpenTransfer; debe estar asignada al servidor. Usa `127.0.0.1` para acceso solo local, una IP LAN concreta para acceso desde esa red o `0.0.0.0` para todas las interfaces (solo junto a reglas de red/firewall adecuadas). El instalador no abre puertos.

## Directorios persistentes

| Ruta predeterminada | Contenido | Se reemplaza al actualizar |
|---|---|---|
| `/opt/opentransfer/releases/` | Cada versión del código | No; se añade un release |
| `/opt/opentransfer/current` | Enlace al release activo | Sí, de forma atómica |
| `/etc/opentransfer/instance.env` | Configuración y secretos | Nunca automáticamente |
| `/var/lib/opentransfer/postgres/` | Datos PostgreSQL (Docker) | Nunca |
| `/var/lib/opentransfer/files/` | Archivos (almacenamiento local por defecto) | Nunca |
| `/var/backups/opentransfer/` | Copias previas a actualizaciones | Nunca automáticamente |

No muevas ni borres estas rutas sin un procedimiento de migración y una copia verificada.

## Almacenamiento NAS

OpenTransfer no monta SMB/NFS por sí mismo. Primero monta el recurso en Linux mediante fstab/systemd y valida su persistencia tras reiniciar. Después:

```bash
sudo ./install.sh --storage nas --storage-path /mnt/opentransfer
```

La ruta debe existir y ser escribible por la identidad que ejecuta la aplicación. En Docker, el contenedor usa UID/GID 10001; ajusta ACL/permisos del NAS para esa identidad. El instalador no hace `chown -R` sobre un NAS existente.

## Primer arranque y diagnóstico

```bash
# Docker
docker compose -p opentransfer -f /opt/opentransfer/current/deploy/compose.yaml ps
docker compose -p opentransfer -f /opt/opentransfer/current/deploy/compose.yaml logs --tail=100

# Nativo
sudo systemctl status opentransfer
sudo journalctl -u opentransfer -n 100 --no-pager

# Diagnóstico HTTP
curl -fsS http://127.0.0.1:8080/healthz
curl -fsS http://127.0.0.1:8080/readyz
```

`/healthz` confirma que el proceso HTTP responde. `/readyz` comprueba permisos de escritura del directorio y conectividad TCP con el host PostgreSQL; todavía no valida autenticación, esquema ni migraciones SQL.

## Desinstalación

No existe un desinstalador destructivo en esta fase. Para retirar el servicio sin perder datos, detén el servicio/los contenedores y conserva por separado configuración, base de datos, archivos y claves. No ejecutes `docker compose down -v`.
