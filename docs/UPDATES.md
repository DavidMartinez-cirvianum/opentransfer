# Política de actualizaciones de OpenTransfer

## Convención de versión y nombre

Las versiones publicables usarán MAJOR.MINOR.PATCH. Cada versión que requiera actualizar una instalación entregará en la raíz un script con este formato:

- actualizacionv0.2.0.sh
- actualizacionv0.3.0.sh
- actualizacionv1.0.0.sh

El nombre exacto corresponderá a la versión de destino. El script debe indicar qué versión mínima admite y qué cambios aplica. Los cambios solo documentales o de prototipo que no alteren una instalación ejecutable no necesitan un script de servidor.

## Datos que una actualización debe conservar

- Base de datos PostgreSQL y sus volúmenes.
- Archivos y objetos transferidos.
- Usuarios, invitados, carpetas, permisos, transferencias y auditoría.
- Configuración local, variables y secretos.
- Claves de cifrado y material de recuperación.
- Certificados TLS y configuración del proxy que no administre OpenTransfer.
- Logs y copias existentes.

Los datos persistentes estarán separados de los binarios, imágenes y archivos de cada release.

## Comportamiento obligatorio del script

1. Comprobar sistema, permisos, versión instalada, espacio disponible y estado del servicio.
2. Adquirir un bloqueo para impedir dos actualizaciones simultáneas.
3. Mostrar los cambios y detenerse ante una versión no compatible.
4. Crear y verificar una copia previa de base de datos, archivos y configuración; el material de claves se protegerá por separado y nunca se imprimirá.
5. Descargar o instalar únicamente artefactos de la versión objetivo, verificando checksum y firma cuando estén disponibles.
6. Aplicar solo las migraciones necesarias, en orden y con registro de versión.
7. Mantener compatibilidad hacia atrás durante la migración: expandir, migrar datos y retirar estructuras antiguas solo en una versión posterior.
8. Reiniciar únicamente los servicios necesarios y comprobar health/readiness.
9. Guardar un informe con resultado, versión anterior/nueva, migraciones y ubicación de la copia.
10. Si falla, conservar la copia y el diagnóstico; no borrar datos ni intentar una restauración destructiva automática.

## Prohibiciones

- Nunca ejecutar docker compose down -v.
- Nunca borrar o recrear volúmenes de PostgreSQL o almacenamiento.
- Nunca sobrescribir un fichero de configuración existente por defecto.
- Nunca regenerar claves de cifrado durante una actualización.
- Nunca borrar carpetas de archivos, logs o backups.
- Nunca actualizar a latest sin fijar una versión.
- Nunca modificar firewall, SSH, DNS o configuración de un proxy ajeno sin permiso explícito.
- Nunca ejecutar una migración destructiva irreversible como parte de una actualización rutinaria.

## Diseño de recuperación

- Mantener releases en directorios separados o usar imágenes Docker versionadas.
- Cambiar la versión activa de forma atómica cuando sea posible.
- Mantener migraciones compatibles con la versión anterior para permitir volver atrás con el binario si la migración lo permite.
- Si una migración de datos no permite rollback seguro, detener la actualización y requerir un procedimiento explícito de restauración desde la copia verificada.
- Probar cada script desde la versión anterior en un entorno con datos, cuotas, invitados, carpetas y archivos de ejemplo.

## Estado actual

El repositorio todavía contiene un prototipo frontend y documentación; no existe aún un servicio instalable ni una estructura de datos persistente. Por tanto, todavía no es posible crear honestamente un actualizador de servidor funcional. El primer script ejecutable se entregará cuando existan el runtime y el procedimiento real de instalación. Crear ahora un script que solo descargue código o reinicie servicios inexistentes daría una falsa sensación de seguridad.
