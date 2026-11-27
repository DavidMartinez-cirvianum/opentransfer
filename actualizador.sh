#!/usr/bin/env bash
# Incremental, release-based updater. It never deletes persistent data/config.
set -Eeuo pipefail
IFS=$'\n\t'

REPO_URL="https://github.com/DavidMartinez-cirvianum/opentransfer.git"
APP_ROOT="${OT_APP_DIR:-/opt/opentransfer}"
CONFIG_FILE="${OT_CONFIG_FILE:-/etc/opentransfer/instance.env}"
BACKUP_ROOT="${OT_BACKUP_DIR:-/var/backups/opentransfer}"
MODE="auto"
REF="${1:-}"

log() { printf '[OpenTransfer updater] %s\n' "$*"; }
warn() { printf '[OpenTransfer updater] AVISO: %s\n' "$*" >&2; }
die() { printf '[OpenTransfer updater] ERROR: %s\n' "$*" >&2; exit 1; }
TMP_DIR=""
cleanup() { [[ -z "$TMP_DIR" ]] || rm -rf -- "$TMP_DIR"; }
trap cleanup EXIT
trap 'die "Fallo en la línea $LINENO. La versión anterior y los datos se conservan."' ERR

usage() {
  cat <<'EOF'
Uso:
  sudo ./actualizador.sh v0.2.0

Actualiza a una etiqueta Git versionada. Requiere una etiqueta publicada en GitHub.
El actualizador crea un directorio release nuevo, conserva los anteriores y nunca
borra configuración, base de datos, archivos, claves ni certificados.
No admite ramas móviles como main para evitar actualizaciones no reproducibles.
EOF
}
if [[ "$REF" == "--help" || "$REF" == "-h" ]]; then usage; exit 0; fi
[[ $EUID -eq 0 ]] || die "Ejecuta el actualizador como root."
[[ "$REF" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]] || { usage; die "Indica una versión exacta, por ejemplo v0.2.0."; }
command -v git >/dev/null || die "Falta git."
command -v curl >/dev/null || die "Falta curl."
command -v tar >/dev/null || die "Falta tar."
[[ -f "$CONFIG_FILE" ]] || die "No existe la configuración $CONFIG_FILE."
[[ -L "$APP_ROOT/current" ]] || die "No existe el enlace current. ¿Está instalada OpenTransfer?"
CURRENT="$(readlink -f "$APP_ROOT/current")"
[[ -d "$CURRENT" ]] || die "El release actual no existe."
mkdir -p "$APP_ROOT/releases" "$BACKUP_ROOT"
chmod 750 "$APP_ROOT" "$APP_ROOT/releases" "$BACKUP_ROOT" 2>/dev/null || true

read_config() {
  local key="$1"
  sed -n "s/^${key}=//p" "$CONFIG_FILE" | tail -n 1 | sed -e 's/^"//' -e 's/"$//'
}
HTTP_PORT="$(read_config OT_HTTP_PORT)"
HTTP_PORT="${HTTP_PORT:-8080}"
[[ "$HTTP_PORT" =~ ^[0-9]{1,5}$ ]] || die "OT_HTTP_PORT no es válido en la configuración."

TMP_DIR="$(mktemp -d)"
GIT_DIR="$TMP_DIR/repository"
STAGE_DIR="$TMP_DIR/release"
mkdir -p "$GIT_DIR" "$STAGE_DIR"
git -C "$GIT_DIR" init -q
git -C "$GIT_DIR" remote add origin "$REPO_URL"
log "Descargando la etiqueta $REF..."
git -C "$GIT_DIR" fetch --quiet --depth 1 origin "refs/tags/$REF"
git -C "$GIT_DIR" checkout --quiet --detach FETCH_HEAD
COMMIT="$(git -C "$GIT_DIR" rev-parse HEAD)"
VERSION="$(git -C "$GIT_DIR" show HEAD:VERSION | tr -d '[:space:]')"
EXPECTED="${REF#v}"
[[ "$VERSION" == "$EXPECTED" ]] || die "La etiqueta $REF contiene VERSION=$VERSION; se esperaba $EXPECTED."
if git -C "$GIT_DIR" verify-tag "$REF" >/dev/null 2>&1; then
  log "Firma de etiqueta verificada."
else
  warn "La etiqueta no tiene una firma verificable por las claves instaladas. Commit: $COMMIT"
fi

RELEASE_NAME="${VERSION}-${COMMIT:0:8}"
RELEASE_DIR="$APP_ROOT/releases/$RELEASE_NAME"
[[ ! -e "$RELEASE_DIR" ]] || die "El release $RELEASE_NAME ya existe; no se sobrescribirá."
git -C "$GIT_DIR" archive HEAD | tar -x -C "$STAGE_DIR"
printf '%s\n' "$COMMIT" > "$STAGE_DIR/.source-commit"
mv "$STAGE_DIR" "$RELEASE_DIR"
chown -R root:root "$RELEASE_DIR"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$BACKUP_ROOT/pre-$RELEASE_NAME-$STAMP"
mkdir -m 700 "$BACKUP_DIR"
cp -p "$CONFIG_FILE" "$BACKUP_DIR/instance.env"
log "Configuración respaldada en $BACKUP_DIR (permisos privados)."

if command -v docker >/dev/null && docker compose version >/dev/null 2>&1 && [[ -f "$CURRENT/deploy/compose.yaml" ]]; then
  MODE="docker"
  compose_current() {
    docker compose --project-name opentransfer --env-file "$CONFIG_FILE" \
      -f "$CURRENT/deploy/compose.yaml" --project-directory "$CURRENT" "$@"
  }
  compose_new() {
    docker compose --project-name opentransfer --env-file "$CONFIG_FILE" \
      -f "$RELEASE_DIR/deploy/compose.yaml" --project-directory "$RELEASE_DIR" "$@"
  }
  if compose_current ps --status running database 2>/dev/null | grep -q database; then
    log "Creando respaldo lógico de PostgreSQL..."
    compose_current exec -T database sh -ec 'PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -h 127.0.0.1 -U "$POSTGRES_USER" "$POSTGRES_DB"' > "$BACKUP_DIR/postgresql.sql"
    chmod 600 "$BACKUP_DIR/postgresql.sql"
  else
    warn "El contenedor de base de datos no está activo; no se ha creado dump SQL."
  fi
  compose_new config --quiet
  compose_new build app
elif command -v systemctl >/dev/null && systemctl is-enabled --quiet opentransfer 2>/dev/null; then
  MODE="native"
  command -v go >/dev/null || die "El modo native requiere Go para compilar el nuevo release."
  mkdir -p "$RELEASE_DIR/bin"
  (cd "$RELEASE_DIR" && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=$VERSION" -o "$RELEASE_DIR/bin/opentransfer" ./cmd/opentransfer)
  chmod 755 "$RELEASE_DIR/bin/opentransfer"
else
  die "No se ha podido identificar una instalación Docker o systemd compatible."
fi

PREVIOUS_TARGET="$(readlink "$APP_ROOT/current")"
ln -s "$RELEASE_DIR" "$APP_ROOT/current.new"
mv -Tf "$APP_ROOT/current.new" "$APP_ROOT/current"

rollback() {
  warn "La comprobación posterior ha fallado. Volviendo al release anterior..."
  ln -s "$PREVIOUS_TARGET" "$APP_ROOT/current.rollback"
  mv -Tf "$APP_ROOT/current.rollback" "$APP_ROOT/current"
  if [[ "$MODE" == "docker" ]]; then
    compose_current up -d --build app || true
  else
    systemctl restart opentransfer || true
  fi
}
if [[ "$MODE" == "docker" ]]; then
  if ! compose_new up -d --no-deps app; then rollback; die "No se pudo iniciar el nuevo servicio."; fi
else
  systemctl restart opentransfer
fi

READY=0
for _ in {1..40}; do
  if curl --fail --silent "http://127.0.0.1:$HTTP_PORT/readyz" >/dev/null; then READY=1; break; fi
  sleep 2
done
if ((READY == 0)); then
  rollback
  die "La nueva versión no supera /readyz. Se ha restaurado el release anterior."
fi

log "Actualización completada: $VERSION ($COMMIT)"
log "Release activo: $RELEASE_DIR"
log "Release anterior conservado: $CURRENT (histórico)"
log "Configuración, PostgreSQL, archivos y claves no se han borrado ni regenerado."
log "Respaldos de esta operación: $BACKUP_DIR"
log "No se han ejecutado migraciones automáticas en esta versión."
