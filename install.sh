#!/usr/bin/env bash
# OpenTransfer installer. It never removes existing application data or config.
set -Eeuo pipefail
IFS=$'\n\t'

REPO_URL="https://github.com/DavidMartinez-cirvianum/opentransfer.git"
REPO_API="https://api.github.com/repos/DavidMartinez-cirvianum/opentransfer"
REF="main"
MODE="docker"
APP_ROOT="/opt/opentransfer"
CONFIG_DIR="/etc/opentransfer"
DATA_DIR="/var/lib/opentransfer"
BACKUP_DIR="/var/backups/opentransfer"
BIND_ADDRESS="127.0.0.1"
HTTP_PORT="8080"
PUBLIC_URL=""
STORAGE_BACKEND="local"
STORAGE_PATH=""
DATABASE_URL=""
POSTGRES_MODE="auto"
POSTGRES_DB="opentransfer"
POSTGRES_USER="opentransfer"
POSTGRES_MANAGED=0
DB_PASSWORD=""
PG_PORT=""
ASSUME_YES=0
NO_START=0
SOURCE_DIR=""
TMP_DIR=""

log() { printf '[OpenTransfer] %s\n' "$*"; }
warn() { printf '[OpenTransfer] AVISO: %s\n' "$*" >&2; }
die() { printf '[OpenTransfer] ERROR: %s\n' "$*" >&2; exit 1; }
cleanup() { [[ -z "$TMP_DIR" ]] || rm -rf -- "$TMP_DIR"; }
trap cleanup EXIT
trap 'die "Fallo en la línea $LINENO. No se han eliminado tus datos."' ERR

usage() {
  cat <<'EOF'
OpenTransfer installer

Uso:
  sudo ./install.sh [opciones]

Opciones:
  --mode docker|native       Docker Compose (por defecto) o Linux + systemd
  --ref REF                  Rama o etiqueta de origen (por defecto: main)
  --app-dir RUTA             Raíz de instalación (por defecto: /opt/opentransfer)
  --config-dir RUTA          Configuración privada (por defecto: /etc/opentransfer)
  --data-dir RUTA            Datos persistentes (por defecto: /var/lib/opentransfer)
  --backup-dir RUTA          Copias locales (por defecto: /var/backups/opentransfer)
  --bind DIRECCION           Dirección host de publicación (por defecto: 127.0.0.1)
  --port PUERTO              Puerto HTTP (por defecto: 8080)
  --url URL                  URL pública / URL del proxy inverso
  --storage local|nas        Disco local o NAS ya montado por el sistema
  --storage-path RUTA        Ruta absoluta donde persistir los archivos
  --database-url URL         URL PostgreSQL para modo native
  --postgres auto|install|external  Instalar PostgreSQL local o usar uno existente
  --postgres-db NOMBRE       Nombre de la base de datos local (por defecto: opentransfer)
  --postgres-user NOMBRE     Usuario PostgreSQL local (por defecto: opentransfer)
  --yes                      Usar valores predeterminados sin preguntar
  --no-start                 Instalar sin iniciar los servicios
  --help                     Mostrar esta ayuda

No instala Docker ni modifica firewall, SSH, DNS o proxy inverso. En modo native
puede instalar PostgreSQL localmente en Debian/Ubuntu o usar una base existente.
Consulta docs/INSTALLATION.md antes de desplegar.
EOF
}

while (($#)); do
  case "$1" in
    --mode) MODE="${2:?Falta el valor de --mode}"; shift 2 ;;
    --ref) REF="${2:?Falta el valor de --ref}"; shift 2 ;;
    --app-dir) APP_ROOT="${2:?Falta el valor de --app-dir}"; shift 2 ;;
    --config-dir) CONFIG_DIR="${2:?Falta el valor de --config-dir}"; shift 2 ;;
    --data-dir) DATA_DIR="${2:?Falta el valor de --data-dir}"; shift 2 ;;
    --backup-dir) BACKUP_DIR="${2:?Falta el valor de --backup-dir}"; shift 2 ;;
    --bind) BIND_ADDRESS="${2:?Falta el valor de --bind}"; shift 2 ;;
    --port) HTTP_PORT="${2:?Falta el valor de --port}"; shift 2 ;;
    --url) PUBLIC_URL="${2:?Falta el valor de --url}"; shift 2 ;;
    --storage) STORAGE_BACKEND="${2:?Falta el valor de --storage}"; shift 2 ;;
    --storage-path) STORAGE_PATH="${2:?Falta el valor de --storage-path}"; shift 2 ;;
    --database-url) DATABASE_URL="${2:?Falta el valor de --database-url}"; shift 2 ;;
    --postgres) POSTGRES_MODE="${2:?Falta el valor de --postgres}"; shift 2 ;;
    --postgres-db) POSTGRES_DB="${2:?Falta el valor de --postgres-db}"; shift 2 ;;
    --postgres-user) POSTGRES_USER="${2:?Falta el valor de --postgres-user}"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    --no-start) NO_START=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "Opción desconocida: $1" ;;
  esac
done

[[ $EUID -eq 0 ]] || die "Ejecuta el instalador como root: sudo ./install.sh"
[[ ! -e "$APP_ROOT/current" && ! -L "$APP_ROOT/current" ]] || die "Ya existe una instalación en $APP_ROOT/current. Para actualizar usa ./actualizador.sh VERSION; install.sh no debe reinstalar una instancia existente."
[[ "$(uname -s)" == "Linux" ]] || die "Solo se admiten sistemas Linux."
case "$(uname -m)" in x86_64|aarch64|arm64) ;; *) die "Arquitectura no soportada: $(uname -m)" ;; esac
[[ "$MODE" == "docker" || "$MODE" == "native" ]] || die "--mode debe ser docker o native."
[[ "$POSTGRES_MODE" == "auto" || "$POSTGRES_MODE" == "install" || "$POSTGRES_MODE" == "external" ]] || die "--postgres debe ser auto, install o external."
[[ "$POSTGRES_DB" =~ ^[A-Za-z_][A-Za-z0-9_]{0,62}$ ]] || die "--postgres-db debe ser un identificador SQL simple de hasta 63 caracteres."
[[ "$POSTGRES_USER" =~ ^[A-Za-z_][A-Za-z0-9_]{0,62}$ ]] || die "--postgres-user debe ser un identificador SQL simple de hasta 63 caracteres."
[[ "$STORAGE_BACKEND" == "local" || "$STORAGE_BACKEND" == "nas" ]] || die "--storage debe ser local o nas."
[[ "$HTTP_PORT" =~ ^[0-9]{1,5}$ ]] && ((HTTP_PORT > 0 && HTTP_PORT < 65536)) || die "Puerto inválido."
[[ "$REF" =~ ^[A-Za-z0-9._/-]+$ ]] || die "Referencia Git inválida."
for p in "$APP_ROOT" "$CONFIG_DIR" "$DATA_DIR" "$BACKUP_DIR"; do
  [[ "$p" == /* && "$p" != *" "* && "$p" != *"|"* ]] || die "Las rutas deben ser absolutas y no contener espacios ni '|': $p"
done

command -v curl >/dev/null || die "Falta curl."
command -v tar >/dev/null || die "Falta tar."
command -v openssl >/dev/null || die "Falta openssl."
command -v df >/dev/null || die "Falta df."
command -v ss >/dev/null || die "Falta ss."

if [[ -z "$STORAGE_PATH" ]]; then STORAGE_PATH="$DATA_DIR/files"; fi
[[ "$STORAGE_PATH" == /* && "$STORAGE_PATH" != *" "* && "$STORAGE_PATH" != *":"* && "$STORAGE_PATH" != *"|"* ]] || die "La ruta de almacenamiento debe ser absoluta y no contener espacios, ':' ni '|'."
[[ "$STORAGE_PATH" != "$APP_ROOT"* && "$STORAGE_PATH" != "$CONFIG_DIR"* ]] || die "El almacenamiento no puede estar dentro del directorio de código ni de configuración."

mkdir -p "$(dirname "$APP_ROOT")" "$(dirname "$CONFIG_DIR")" "$(dirname "$DATA_DIR")"
AVAILABLE_KB="$(df -Pk "$(dirname "$APP_ROOT")" | awk 'NR==2 {print $4}')"
[[ "$AVAILABLE_KB" =~ ^[0-9]+$ ]] && ((AVAILABLE_KB >= 2097152)) || die "Se necesitan al menos 2 GiB libres en el volumen de instalación."
MEM_KB="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
if [[ "$MEM_KB" =~ ^[0-9]+$ ]] && ((MEM_KB < 2097152)); then warn "Hay menos de 2 GiB de RAM; el rendimiento puede ser insuficiente."; fi
if ((ASSUME_YES == 0)); then
  read -r -p "Modo [docker/native] (docker): " answer
  [[ -z "$answer" ]] || MODE="$answer"
  [[ "$MODE" == "docker" || "$MODE" == "native" ]] || die "Modo no válido."
  read -r -p "Dirección de escucha (localhost o IP de red) [$BIND_ADDRESS]: " answer
  [[ -z "$answer" ]] || BIND_ADDRESS="$answer"
  read -r -p "Puerto HTTP [$HTTP_PORT]: " answer
  [[ -z "$answer" ]] || HTTP_PORT="$answer"
  if [[ -z "$PUBLIC_URL" ]]; then
    read -r -p "URL pública (vacío si aún no tienes dominio): " PUBLIC_URL
  fi
  read -r -p "Almacenamiento [local/nas] ($STORAGE_BACKEND): " answer
  [[ -z "$answer" ]] || STORAGE_BACKEND="$answer"
  if [[ "$STORAGE_BACKEND" == "nas" && "$STORAGE_PATH" == "$DATA_DIR/files" ]]; then
    read -r -p "Ruta del NAS ya montado: " STORAGE_PATH
  fi
  if [[ "$MODE" == "native" && "$POSTGRES_MODE" == "auto" && -z "$DATABASE_URL" ]]; then
    read -r -p "PostgreSQL: [1] instalar automáticamente aquí (recomendado) [2] usar uno existente (1): " answer
    case "${answer,,}" in
      2|e|externo|existente) POSTGRES_MODE="external" ;;
      ""|1|i|instalar|local) POSTGRES_MODE="install" ;;
      *) die "Selecciona 1 (instalar) o 2 (usar uno existente)." ;;
    esac
  fi
fi
[[ "$MODE" == "docker" || "$MODE" == "native" ]] || die "Modo no válido."
if [[ "$MODE" == "docker" ]]; then
  command -v docker >/dev/null || die "Docker no está instalado. Consulta https://docs.docker.com/engine/install/."
  docker compose version >/dev/null 2>&1 || die "Se necesita Docker Compose v2 (docker compose)."
else
  command -v go >/dev/null || die "El modo native requiere Go instalado (versión 1.23 o posterior)."
  command -v systemctl >/dev/null || die "El modo native requiere systemd."
  command -v useradd >/dev/null || die "No se encuentra useradd."
  # The connection string is collected after loading any existing protected config.
fi
[[ "$STORAGE_BACKEND" == "local" || "$STORAGE_BACKEND" == "nas" ]] || die "Backend de almacenamiento no válido."
[[ "$HTTP_PORT" =~ ^[0-9]{1,5}$ ]] && ((HTTP_PORT > 0 && HTTP_PORT < 65536)) || die "Puerto inválido."
[[ "$BIND_ADDRESS" == "localhost" || "$BIND_ADDRESS" =~ ^[0-9a-fA-F:.]+$ ]] || die "Dirección de bind inválida (usa localhost o una dirección IP)."
[[ "$STORAGE_PATH" == /* && "$STORAGE_PATH" != *" "* && "$STORAGE_PATH" != *":"* && "$STORAGE_PATH" != *"|"* ]] || die "La ruta de almacenamiento debe ser absoluta y no contener espacios, ':' ni '|'."
[[ "$PUBLIC_URL" == "" || "$PUBLIC_URL" =~ ^https?://[^[:space:]]+$ ]] || die "URL pública inválida (usa http:// o https://)."
if ss -ltn | awk -v p=":$HTTP_PORT" '$4 ~ p"$" {found=1} END {exit !found}'; then
  die "El puerto $HTTP_PORT ya está ocupado. Elige otro puerto o configura tu proxy."
fi
if [[ -z "$PUBLIC_URL" ]]; then
  case "$BIND_ADDRESS" in
    0.0.0.0|::) URL_HOST="$(hostname -I 2>/dev/null | awk '{print $1}')"; URL_HOST="${URL_HOST:-127.0.0.1}" ;;
    *) URL_HOST="$BIND_ADDRESS" ;;
  esac
  if [[ "$URL_HOST" == *:* ]]; then
    PUBLIC_URL="http://[$URL_HOST]:$HTTP_PORT"
  else
    PUBLIC_URL="http://$URL_HOST:$HTTP_PORT"
  fi
fi
if [[ "$STORAGE_BACKEND" == "nas" ]]; then
  [[ -d "$STORAGE_PATH" ]] || die "La ruta NAS debe existir y estar montada antes de instalar."
  command -v mountpoint >/dev/null && mountpoint -q "$STORAGE_PATH" || warn "No se ha podido confirmar que $STORAGE_PATH sea un punto de montaje."
fi

CONFIG_FILE="$CONFIG_DIR/instance.env"
if [[ -f "$CONFIG_FILE" ]]; then
  read_existing_config() {
    sed -n "s/^${1}=//p" "$CONFIG_FILE" | tail -n 1 | sed -e 's/^"//' -e 's/"$//'
  }
  warn "Se ha encontrado configuración previa; se usarán sus rutas y valores de publicación sin modificar los secretos."
  STORAGE_BACKEND="$(read_existing_config OT_STORAGE_BACKEND)"
  STORAGE_PATH="$(read_existing_config OT_STORAGE_LOCAL_PATH)"
  HTTP_PORT="$(read_existing_config OT_HTTP_PORT)"
  BIND_ADDRESS="$(read_existing_config OT_BIND_ADDRESS)"
  PUBLIC_URL="$(read_existing_config OT_PUBLIC_URL)"
  DATABASE_URL="$(read_existing_config OT_DATABASE_URL)"
  POSTGRES_MANAGED="$(read_existing_config OT_POSTGRES_MANAGED)"
  POSTGRES_MANAGED="${POSTGRES_MANAGED:-0}"
  POSTGRES_DB="$(read_existing_config POSTGRES_DB)"
  POSTGRES_DB="${POSTGRES_DB:-opentransfer}"
  POSTGRES_USER="$(read_existing_config POSTGRES_USER)"
  POSTGRES_USER="${POSTGRES_USER:-opentransfer}"
  [[ -n "$STORAGE_BACKEND" && -n "$STORAGE_PATH" && -n "$HTTP_PORT" ]] || die "La configuración existente está incompleta. Revisa $CONFIG_FILE manualmente."
fi
[[ "$STORAGE_BACKEND" == "local" || "$STORAGE_BACKEND" == "nas" ]] || die "Backend de almacenamiento no válido en la configuración."
[[ "$HTTP_PORT" =~ ^[0-9]{1,5}$ ]] && ((HTTP_PORT > 0 && HTTP_PORT < 65536)) || die "Puerto inválido en la configuración."
[[ "$STORAGE_PATH" == /* && "$STORAGE_PATH" != *" "* && "$STORAGE_PATH" != *":"* && "$STORAGE_PATH" != *"|"* ]] || die "Ruta de almacenamiento inválida en la configuración."
if [[ "$STORAGE_BACKEND" == "nas" ]]; then
  [[ -d "$STORAGE_PATH" ]] || die "La ruta NAS configurada no existe; no se creará para evitar escribir en el disco local si el NAS está desmontado."
  command -v mountpoint >/dev/null && mountpoint -q "$STORAGE_PATH" || warn "No se ha podido confirmar que $STORAGE_PATH sea un punto de montaje."
fi

# Configure PostgreSQL before staging application files. Native mode supports
# an automatically managed local PostgreSQL or an existing external instance.
install_local_postgres() {
  [[ -r /etc/os-release ]] || die "No se puede identificar la distribución para instalar PostgreSQL."
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}" in
    debian|ubuntu) ;;
    *)
      case " ${ID_LIKE:-} " in
        *" debian "*|*" ubuntu "*) ;;
        *) die "La instalación automática de PostgreSQL solo está preparada para Debian/Ubuntu. Usa --postgres external en otra distribución." ;;
      esac
      ;;
  esac
  command -v apt-get >/dev/null || die "No se encuentra apt-get. Usa --postgres external o instala PostgreSQL manualmente."
  command -v dpkg-query >/dev/null || die "No se encuentra dpkg-query."
  if ! dpkg-query -W -f='${Status}' postgresql 2>/dev/null | grep -q "install ok installed"; then
    log "Instalando PostgreSQL mediante APT..."
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-client
  else
    log "PostgreSQL ya está instalado; se reutilizará el servicio local."
  fi
  command -v pg_lsclusters >/dev/null || die "Falta pg_lsclusters (paquete postgresql-common)."
  command -v runuser >/dev/null || die "Falta runuser para administrar PostgreSQL de forma segura."
  systemctl enable --now postgresql
  local cluster version name port
  cluster="$(pg_lsclusters --no-header | awk '$4 == "online" {print $1, $2, $3; exit}')"
  if [[ -z "$cluster" ]]; then
    cluster="$(pg_lsclusters --no-header | awk 'NF {print $1, $2, $3; exit}')"
    if [[ -n "$cluster" ]]; then
      IFS=' ' read -r version name port _ <<< "$cluster"
      log "Iniciando el clúster PostgreSQL $version/$name..."
      pg_ctlcluster "$version" "$name" start
    else
      version="$(psql --version | awk '{print $3}' | cut -d. -f1)"
      [[ "$version" =~ ^[0-9]+$ ]] || die "No se pudo detectar la versión de PostgreSQL para crear el clúster."
      log "Creando el clúster PostgreSQL $version/main..."
      pg_createcluster "$version" main --start
    fi
    cluster="$(pg_lsclusters --no-header | awk '$4 == "online" {print $1, $2, $3; exit}')"
  fi
  [[ -n "$cluster" ]] || die "No hay ningún clúster PostgreSQL en línea."
  # The script uses a strict global IFS (newline/tab); parse pg_lsclusters columns with spaces explicitly.
  IFS=' ' read -r version name port _ <<< "$cluster"
  [[ "$port" =~ ^[0-9]{1,5}$ ]] || die "No se pudo detectar un puerto válido del clúster PostgreSQL (obtenido: '$port'; fila: '$cluster')."
  PG_PORT="$port"

  # If a previous run already wrote a managed database URL to the protected
  # config, keep its password. Rotating it here would desynchronize PostgreSQL
  # and instance.env because existing configuration is deliberately preserved.
  if [[ -f "$CONFIG_FILE" ]]; then
    if [[ "$POSTGRES_MANAGED" == "1" && -n "$DATABASE_URL" ]]; then
      log "Se conserva la conexión PostgreSQL de la configuración existente."
      psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "SELECT 1" >/dev/null || die "La conexión PostgreSQL guardada en $CONFIG_FILE no funciona. No se cambiarán usuarios, contraseñas ni datos."
      POSTGRES_MANAGED=1
      return 0
    fi
    die "Ya existe $CONFIG_FILE y no identifica una base PostgreSQL administrada por OpenTransfer. No se modificará PostgreSQL ni la configuración."
  fi

  local role_exists db_exists db_owner
  role_exists="$(runuser -u postgres -- psql -X -A -t -p "$PG_PORT" -d postgres -v ON_ERROR_STOP=1 -c "SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$POSTGRES_USER')")"
  db_exists="$(runuser -u postgres -- psql -X -A -t -p "$PG_PORT" -d postgres -v ON_ERROR_STOP=1 -c "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = '$POSTGRES_DB')")"

  DB_PASSWORD="$(openssl rand -hex 32)"
  if [[ "$role_exists" == "t" && "$db_exists" == "t" ]]; then
    # Recover an interrupted previous installation only when the existing
    # database is already owned by the dedicated OpenTransfer role.
    db_owner="$(runuser -u postgres -- psql -X -A -t -p "$PG_PORT" -d postgres -v ON_ERROR_STOP=1 -c "SELECT pg_get_userbyid(datdba) FROM pg_database WHERE datname = '$POSTGRES_DB'")"
    [[ "$db_owner" == "$POSTGRES_USER" ]] || die "Ya existen $POSTGRES_USER/$POSTGRES_DB, pero la base no pertenece al usuario de OpenTransfer (propietario: '$db_owner'). No se modificará nada."
    log "Recuperando la base de datos de una instalación anterior incompleta..."
    runuser -u postgres -- psql -X -v ON_ERROR_STOP=1 -p "$PG_PORT" -d postgres <<SQL
ALTER ROLE $POSTGRES_USER WITH LOGIN PASSWORD '$DB_PASSWORD';
SQL
  elif [[ "$role_exists" == "f" && "$db_exists" == "f" ]]; then
    log "Creando el usuario y la base de datos OpenTransfer..."
    # Feed SQL through stdin: the generated password is not exposed in process arguments or a file.
    runuser -u postgres -- psql -X -v ON_ERROR_STOP=1 -p "$PG_PORT" -d postgres <<SQL
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', '$POSTGRES_USER', '$DB_PASSWORD')
\\gexec
SELECT format('CREATE DATABASE %I OWNER %I', '$POSTGRES_DB', '$POSTGRES_USER')
\\gexec
SQL
  else
    die "Solo existe uno de los recursos PostgreSQL ($POSTGRES_USER/$POSTGRES_DB). No se modificará nada automáticamente."
  fi
  DATABASE_URL="postgres://$POSTGRES_USER:$DB_PASSWORD@127.0.0.1:$PG_PORT/$POSTGRES_DB?sslmode=disable"
  PGPASSWORD="$DB_PASSWORD" psql -X -h 127.0.0.1 -p "$PG_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -A -t -v ON_ERROR_STOP=1 -c "SELECT 1" | grep -qx "1" || die "PostgreSQL se ha configurado, pero no se ha podido validar la conexión TCP."
  POSTGRES_MANAGED=1
}

if [[ "$MODE" == "native" ]]; then
  if [[ -n "$DATABASE_URL" && "$POSTGRES_MODE" == "install" ]]; then
    die "No combines --postgres install con --database-url. Usa --postgres external para una base de datos existente."
  fi
  if [[ -n "$DATABASE_URL" && "$POSTGRES_MODE" == "auto" ]]; then
    POSTGRES_MODE="external"
  fi
  if [[ "$POSTGRES_MODE" == "auto" ]]; then
    if ((ASSUME_YES == 1)); then
      POSTGRES_MODE="install"
    else
      read -r -p "¿Cómo quieres configurar PostgreSQL? [1] Instalar localmente (recomendado) [2] Usar uno existente (1): " answer
      case "${answer,,}" in
        2|e|externo|existente) POSTGRES_MODE="external" ;;
        ""|1|i|instalar|local) POSTGRES_MODE="install" ;;
        *) die "Selecciona 1 (instalar) o 2 (usar uno existente)." ;;
      esac
    fi
  fi
  if [[ "$POSTGRES_MODE" == "install" ]]; then
    install_local_postgres
  else
    if [[ -z "$DATABASE_URL" ]]; then
      ((ASSUME_YES == 0)) || die "Has elegido --postgres external: proporciona --database-url."
      printf '\nUsaremos un PostgreSQL existente. La URL se solicitará sin mostrar la contraseña.\n'
      read -r -s -p "URL PostgreSQL (postgres://usuario:clave@servidor:5432/base): " DATABASE_URL
      printf '\n'
    fi
    [[ "$DATABASE_URL" =~ ^postgres(ql)?://[^[:space:]]+$ ]] || die "URL PostgreSQL vacía o inválida. Usa postgres:// o postgresql:// con host y base de datos."
    POSTGRES_MANAGED=0
  fi
fi

LISTEN_HOST="$BIND_ADDRESS"
if [[ "$LISTEN_HOST" == *:* ]]; then
  LISTEN_ADDR="[$LISTEN_HOST]:$HTTP_PORT"
else
  LISTEN_ADDR="$LISTEN_HOST:$HTTP_PORT"
fi
HEALTH_HOST="$BIND_ADDRESS"
case "$HEALTH_HOST" in 0.0.0.0|::) HEALTH_HOST="127.0.0.1" ;; esac
if [[ "$HEALTH_HOST" == *:* ]]; then
  HEALTH_URL="http://[$HEALTH_HOST]:$HTTP_PORT"
else
  HEALTH_URL="http://$HEALTH_HOST:$HTTP_PORT"
fi

mkdir -p "$APP_ROOT/releases" "$CONFIG_DIR" "$DATA_DIR" "$BACKUP_DIR" "$STORAGE_PATH"
chmod 750 "$APP_ROOT" "$APP_ROOT/releases" "$DATA_DIR" "$BACKUP_DIR" 2>/dev/null || true
chmod 750 "$CONFIG_DIR"

if [[ ! -f "$CONFIG_FILE" ]]; then
  log "Generando configuración privada en $CONFIG_FILE..."
  if [[ "$MODE" == "docker" ]]; then
    DB_PASSWORD="$(openssl rand -hex 32)"
    POSTGRES_MANAGED=0
  fi
  ENCRYPTION_KEY="$(openssl rand -base64 32)"
  if [[ "$MODE" == "docker" ]]; then
    DATABASE_URL="postgres://$POSTGRES_USER:$DB_PASSWORD@database:5432/$POSTGRES_DB?sslmode=disable"
  else
    [[ -n "$DATABASE_URL" ]] || die "Falta OT_DATABASE_URL para modo native."
  fi
  umask 077
  CONFIG_TMP="$CONFIG_FILE.tmp.$$"
  cat > "$CONFIG_TMP" <<EOF
# OpenTransfer private configuration. Keep this file secret (chmod 600).
OT_CONFIG_FILE=$CONFIG_FILE
OT_LISTEN_ADDR=$LISTEN_ADDR
OT_PUBLIC_URL=$PUBLIC_URL
OT_LOG_LEVEL=info
OT_DATABASE_URL=$DATABASE_URL
OT_STORAGE_BACKEND=$STORAGE_BACKEND
OT_STORAGE_LOCAL_PATH=$STORAGE_PATH
OT_ENCRYPTION_KEY=$ENCRYPTION_KEY
OT_BIND_ADDRESS=$BIND_ADDRESS
OT_HTTP_PORT=$HTTP_PORT
OT_POSTGRES_DATA_DIR=$DATA_DIR/postgres
OT_POSTGRES_MANAGED=$POSTGRES_MANAGED
POSTGRES_DB=$POSTGRES_DB
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$DB_PASSWORD
EOF
  chmod 600 "$CONFIG_TMP"
  mv "$CONFIG_TMP" "$CONFIG_FILE"
else
  warn "Ya existe $CONFIG_FILE. Se conserva sin sobrescribirlo."
  chmod 600 "$CONFIG_FILE"
fi


TMP_DIR="$(mktemp -d)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/go.mod" && -f "$SCRIPT_DIR/Dockerfile" ]]; then
  SOURCE_DIR="$SCRIPT_DIR"
else
  log "Descargando el código de OpenTransfer ($REF)..."
  mkdir -p "$TMP_DIR/source"
  curl --fail --silent --show-error --location --retry 3 "$REPO_API/tarball/$REF" -o "$TMP_DIR/source.tar.gz"
  tar -xzf "$TMP_DIR/source.tar.gz" --strip-components=1 -C "$TMP_DIR/source"
  SOURCE_DIR="$TMP_DIR/source"
fi
[[ -f "$SOURCE_DIR/VERSION" && -f "$SOURCE_DIR/go.mod" ]] || die "El código descargado no contiene VERSION/go.mod."
VERSION="$(tr -d '[:space:]' < "$SOURCE_DIR/VERSION")"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]] || die "VERSION no sigue el formato esperado: $VERSION"
SHORT_SHA="local"
if command -v git >/dev/null && git -C "$SOURCE_DIR" rev-parse --short=8 HEAD >/dev/null 2>&1; then
  SHORT_SHA="$(git -C "$SOURCE_DIR" rev-parse --short=8 HEAD)"
fi
RELEASE_NAME="${VERSION}-${SHORT_SHA}"
RELEASE_DIR="$APP_ROOT/releases/$RELEASE_NAME"
# An interrupted earlier attempt may have left an inactive release directory.
# Never delete it; use a unique new release path instead.
if [[ -e "$RELEASE_DIR" ]]; then
  RELEASE_NAME="${RELEASE_NAME}-retry-$(date -u +%Y%m%dT%H%M%SZ)"
  RELEASE_DIR="$APP_ROOT/releases/$RELEASE_NAME"
fi
STAGE_DIR="$APP_ROOT/releases/.stage-$RELEASE_NAME-$$"
mkdir -m 750 "$STAGE_DIR"
tar --exclude=.git --exclude=backups --exclude=data -cf - -C "$SOURCE_DIR" . | tar -xf - -C "$STAGE_DIR"
mv "$STAGE_DIR" "$RELEASE_DIR"

if [[ "$MODE" == "docker" ]]; then
  if [[ "$STORAGE_BACKEND" == "local" && "$STORAGE_PATH" == "$DATA_DIR/files" ]]; then
    chown 10001:10001 "$STORAGE_PATH"
  fi
  docker compose --project-name opentransfer --env-file "$CONFIG_FILE" \
    -f "$RELEASE_DIR/deploy/compose.yaml" --project-directory "$RELEASE_DIR" config --quiet
  if ((NO_START == 0)); then
    docker compose --project-name opentransfer --env-file "$CONFIG_FILE" \
      -f "$RELEASE_DIR/deploy/compose.yaml" --project-directory "$RELEASE_DIR" up -d --build
    ln -s "$RELEASE_DIR" "$APP_ROOT/current.new"
    mv -Tf "$APP_ROOT/current.new" "$APP_ROOT/current"
    log "Esperando a que la API responda..."
    READY=0
    for _ in {1..40}; do
      if curl --fail --silent "$HEALTH_URL/readyz" >/dev/null; then READY=1; break; fi
      sleep 2
    done
    ((READY == 1)) || die "Los contenedores están instalados, pero /readyz no responde. Consulta docker compose logs."
  fi
else
  if ! id opentransfer >/dev/null 2>&1; then
    useradd --system --home-dir "$DATA_DIR" --shell /usr/sbin/nologin opentransfer
  fi
  install -d -o opentransfer -g opentransfer -m 750 "$DATA_DIR"
  if [[ "$STORAGE_BACKEND" == "local" && "$STORAGE_PATH" == "$DATA_DIR/files" ]]; then
    chown opentransfer:opentransfer "$STORAGE_PATH"
  fi
  runuser -u opentransfer -- test -w "$STORAGE_PATH" || die "El usuario opentransfer no puede escribir en $STORAGE_PATH. Ajusta permisos/ACL del almacenamiento."
  command -v go >/dev/null || die "No se encuentra Go."
  (cd "$RELEASE_DIR" && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=$VERSION" -o "$RELEASE_DIR/bin/opentransfer" ./cmd/opentransfer)
  chown -R root:root "$RELEASE_DIR"
  chmod 755 "$RELEASE_DIR/bin/opentransfer"
  SERVICE_TMP="$TMP_DIR/opentransfer.service"
  sed -e "s|/opt/opentransfer|$APP_ROOT|g" -e "s|/etc/opentransfer/instance.env|$CONFIG_FILE|g" -e "s|/var/lib/opentransfer|$DATA_DIR|g" \
    -e "s|ReadWritePaths=$DATA_DIR|ReadWritePaths=$DATA_DIR $STORAGE_PATH|" \
    "$RELEASE_DIR/deploy/opentransfer.service" > "$SERVICE_TMP"
  if [[ "$POSTGRES_MANAGED" == "1" ]]; then
    sed -i 's/^After=network-online.target$/After=network-online.target postgresql.service/' "$SERVICE_TMP"
    sed -i '/^After=network-online.target/a Wants=postgresql.service' "$SERVICE_TMP"
  fi
  install -m 644 "$SERVICE_TMP" /etc/systemd/system/opentransfer.service
  ln -s "$RELEASE_DIR" "$APP_ROOT/current.new"
  mv -Tf "$APP_ROOT/current.new" "$APP_ROOT/current"
  if ((NO_START == 0)); then
    systemctl daemon-reload
    systemctl enable --now opentransfer
    systemctl is-active --quiet opentransfer || die "El servicio systemd no ha arrancado. Consulta journalctl -u opentransfer."
  fi
fi

log "Instalación preparada."
log "Código: $RELEASE_DIR"
log "Configuración privada: $CONFIG_FILE"
log "Datos persistentes: $DATA_DIR"
log "Almacenamiento: $STORAGE_PATH"
log "URL prevista: $PUBLIC_URL"
if ((NO_START == 1)); then
  log "No se ha iniciado ningún servicio (--no-start)."
else
  if [[ "$MODE" == "docker" ]]; then
    log "Estado: docker compose -p opentransfer -f $APP_ROOT/current/deploy/compose.yaml ps"
  else
    log "Estado: systemctl status opentransfer"
  fi
fi
log "No se ha modificado firewall, SSH, DNS ni proxy inverso."
