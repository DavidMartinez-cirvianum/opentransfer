# Política de actualizaciones

## Principio

Las actualizaciones añaden un release de código nuevo y cambian el enlace `current`. No reinstalan la instancia y no borran ni regeneran:

- `/etc/opentransfer/instance.env` (configuración, claves y credenciales);
- el directorio PostgreSQL;
- los archivos almacenados;
- certificados y configuración del proxy inverso;
- releases anteriores.

No se ejecuta `docker compose down -v`, `rm -rf /var/lib/opentransfer` ni un reset del repositorio de instalación.

## Comando

Cuando exista una etiqueta estable publicada en GitHub:

```bash
sudo ./actualizador.sh v0.2.0
```

El actualizador exige una etiqueta semántica exacta, comprueba que el fichero VERSION de esa etiqueta coincide y registra el commit descargado. No actualiza desde `main` ni desde una rama móvil.

## Qué hace

1. Comprueba permisos, configuración, release actual y herramientas.
2. Descarga la etiqueta a un repositorio temporal y comprueba su versión.
3. Crea un directorio nuevo `releases/VERSION-COMMIT`; nunca sobreescribe el release anterior.
4. Respalda el archivo de configuración. En Docker, intenta crear también un dump lógico de PostgreSQL.
5. Valida Compose/compila el binario antes de activar la nueva versión.
6. Cambia `current` atómicamente.
7. Reinicia únicamente el servicio de aplicación y espera `/readyz`.
8. Si falla el health check, vuelve al release anterior. Los directorios y datos permanecen intactos.

Los releases antiguos no se limpian automáticamente. La limpieza será una operación de mantenimiento explícita cuando exista una política segura de retención.

## Scripts por versión

Cada versión publicable que cambie el procedimiento de actualización debe incluir en la raíz un wrapper auditable `actualizacionvX.Y.Z.sh` que invoque o especialice `actualizador.sh`, además de notas de versión y migraciones versionadas. No se debe publicar un wrapper ficticio para una versión sin cambios.

## Migraciones futuras

Cuando haya esquema SQL, cada migración deberá ser incremental, transaccional cuando sea posible, idempotente y compatible con el código anterior durante el despliegue (expand/migrate/contract). Antes de migrar se exigirá backup PostgreSQL verificable. Los cambios de datos/archivos nunca se automatizarán con `rm` masivo ni rollback destructivo. El rollback de código no deshace migraciones incompatibles: estas necesitarán un plan independiente y probado.

## Limitaciones de esta primera versión

El backend actual todavía no implementa tablas de negocio ni migraciones SQL. Por eso el actualizador no ejecuta migraciones automáticas. El dump SQL de respaldo es de precaución; el directorio de archivos se conserva in situ y no se copia en cada actualización.
