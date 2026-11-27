# Instalación de OpenTransfer

Estado: primera base de instalación y diagnóstico. No es todavía una suite de transferencia lista para producción.

## Requisitos

- Linux x86_64 o ARM64.
- 2 GiB libres como mínimo en el volumen de instalación y 2 GiB de RAM recomendados.
- Docker Engine + Docker Compose v2 para el modo recomendado.
- Para modo nativo: systemd, Go 1.23 o posterior y un PostgreSQL externo ya instalado.
- HTTPS terminado en un proxy inverso administrado por la empresa cuando el servicio se exponga fuera de localhost.

El instalador no instala Docker/PostgreSQL por su cuenta y no modifica firewall, SSH, DNS, Nginx, Caddy ni certificados. La empresa decide cuándo y cómo hacerlo.

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

La modalidad nativa instala un binario Go y un servicio systemd. Requiere PostgreSQL previamente instalado, con un usuario y una base de datos creados. En Debian/Ubuntu, por ejemplo:

```bash
sudo apt update
sudo apt install -y postgresql
sudo -u postgres psql
```

Dentro de `psql`, crea un usuario con una contraseña larga y una base de datos propia:

```sql
CREATE ROLE opentransfer LOGIN PASSWORD 'CAMBIA_POR_UNA_CLAVE_LARGA';
CREATE DATABASE opentransfer OWNER opentransfer;
\q
```

Después instala indicando la conexión. Sustituye la contraseña del ejemplo por la que hayas creado:

```bash
sudo ./install.sh --mode native \
  --bind 192.168.56.101 --port 5173 \
  --database-url 'postgres://opentransfer:TU_CLAVE@127.0.0.1:5432/opentransfer?sslmode=disable'
```

También puedes ejecutar `sudo ./install.sh` y escribir la URL cuando el instalador la solicite de forma oculta. Si la dejas vacía, el instalador se detiene antes de crear un release. La dirección `--bind` es la interfaz de red en la que escuchará el servicio; debe existir en ese servidor. Usa `127.0.0.1` para acceso solo local, una IP LAN concreta para acceso desde esa red o `0.0.0.0` para todas las interfaces (solo junto a reglas de red/firewall adecuadas).

La URL contiene credenciales; evita escribirla en scripts compartidos, historial de shell o tickets. Para producción, configura TLS y el modo SSL apropiado de PostgreSQL en vez de desactivar SSL cuando la conexión atraviese una red.

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
