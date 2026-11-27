# OpenTransfer

**Your files. Your server. Your control.**

OpenTransfer es un proyecto autoalojado para transferir y compartir documentos con control organizativo. La visión incluye funciones inspiradas en suites como ownCloud —usuarios, grupos, carpetas, almacenamiento, cuotas, compartición y administración—, pero no se presenta como un clon completo ni como una alternativa lista para producción.

> **Estado:** primera base de instalación y operaciones. El backend actual solo ofrece health/readiness y validación de configuración. Todavía no hay transferencias, autenticación ni panel de administración funcional. No lo expongas a Internet ni almacenes documentos sensibles todavía.

## Empezar

Requisitos: Linux x86_64/ARM64 y Docker Engine con Compose v2.

```bash
git clone https://github.com/DavidMartinez-cirvianum/opentransfer.git
cd opentransfer
sudo ./install.sh
```

El instalador:
- comprueba sistema, arquitectura, disco, memoria, herramientas y puerto;
- prepara Docker Compose o, de forma inicial, un servicio Linux/systemd;
- genera contraseñas y una clave aleatorias;
- guarda la configuración en `/etc/opentransfer/instance.env` con permisos privados;
- separa releases, configuración, PostgreSQL y archivos;
- no cambia firewall, SSH, DNS ni proxy existente.

Para instalar en modo nativo con PostgreSQL automático: `sudo ./install.sh --mode native --postgres install --bind 192.168.56.101 --port 5173 --yes`. En modo interactivo también puedes elegir un PostgreSQL existente; el instalador pide su URL ocultando la contraseña. Para NAS, primero monta SMB/NFS en el host y después ejecuta `sudo ./install.sh --storage nas --storage-path /mnt/opentransfer`.

Consulta [la guía de instalación](docs/INSTALLATION.md) y [todas las variables](docs/CONFIGURATION.md).

## Actualizaciones sin borrar datos

Cuando haya una etiqueta estable publicada:

```bash
sudo ./actualizador.sh v0.2.0
```

El actualizador despliega un release nuevo, conserva los anteriores, respalda la configuración y PostgreSQL (Docker), cambia el enlace activo y verifica `/readyz`. Si falla, vuelve al release anterior. No borra los archivos, volúmenes, credenciales ni claves.

Lee [la política de actualizaciones](docs/UPDATES.md) antes de actualizar. No hay todavía una etiqueta de release publicada ni un actualizador que deba ejecutarse en una instancia de producción.

## Arquitectura

- Backend: Go, monolito modular previsto.
- Persistencia: PostgreSQL.
- Almacenamiento inicial: filesystem local o NAS montado en Linux.
- Despliegue: Docker Compose recomendado; systemd con PostgreSQL externo.
- Seguridad y límites conocidos: [docs/SECURITY.md](docs/SECURITY.md).
- Plan de producto: [docs/ROADMAP.md](docs/ROADMAP.md).

## Desarrollo

```bash
go test ./...
go vet ./...
go run ./cmd/opentransfer
```

El servidor requiere las variables de entorno definidas en `config/instance.env.example`.

## Alcance honesto

El objetivo es construir una plataforma con capacidades empresariales comparables en amplitud a ownCloud, pero por fases: identidad y permisos primero; después transferencias y almacenamiento; posteriormente auditoría, seguridad avanzada e integraciones. Ninguna función se marcará como disponible hasta que el backend la aplique y esté probada.
