# OpenTransfer

**Your files. Your server. Your control.**

OpenTransfer es una plataforma libre y autoalojada para compartir archivos externamente con control sobre usuarios, invitados, carpetas, cuotas, seguridad y trazabilidad.

## Qué queremos construir

- Usuarios internos con roles y límites individuales.
- Invitados externos por invitación, limitados a carpetas o transferencias concretas.
- Carpetas personales y compartidas con permisos.
- Cuota total de almacenamiento por usuario y tamaño máximo por subida, como controles separados.
- Enlaces de descarga protegidos y revocables.
- Panel administrativo con auditoría y logs técnicos diferenciados.
- Almacenamiento seleccionable: local, NAS y S3-compatible.
- Instalación Docker y Linux nativa.

No es una suite de sincronización general. Consulta [el alcance MVP](docs/MVP.md), [el plan por fases](docs/ROADMAP.md) y [la arquitectura](docs/ARCHITECTURE.md).

## Tecnología prevista

- Backend: Go, monolito modular
- Web: React, TypeScript y Tailwind CSS
- Base de datos: PostgreSQL
- Almacenamiento inicial: filesystem local, con interfaz para NAS y S3
- Despliegue: Docker Compose y, posteriormente, Linux/systemd

## Cifrado

La arquitectura diferencia dos modos:
- **Cifrado gestionado por servidor:** el servidor administra las claves y puede soportar flujos de inspección server-side.
- **Cifrado de extremo a extremo (E2EE):** los clientes cifran/descifran y el servidor almacena ciphertext, sin poder inspeccionar los archivos.

El MVP empieza por cifrado gestionado por servidor en reposo. E2EE se abordará en una fase posterior con protocolo y modelo de amenazas revisados.

## Versiones y actualizaciones

Cada versión publicable que actualice una instalación entregará un script llamado actualizacionvX.Y.Z.sh. Los scripts conservarán base de datos, archivos, configuración, certificados y claves, y aplicarán solo las migraciones necesarias. Consulta [la política de actualizaciones](docs/UPDATES.md).

El repositorio aún no tiene un servicio instalable; por tanto, todavía no debe usarse ningún actualizador para un servidor real.

## Estado del repositorio

El panel React es un prototipo de navegación y diseño. No está conectado a una API, no autentica usuarios y no aplica cuotas, permisos ni auditoría real. No lo expongas como panel de producción.

## Desarrollo del frontend

```bash
cd web
npm install
npm run dev
```

OpenTransfer está en desarrollo activo y no está listo para transferencias sensibles de producción. No se promete seguridad absoluta ni cumplimiento RGPD automático.
