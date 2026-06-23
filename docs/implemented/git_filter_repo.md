# git-filter-repo

## Qué es

Herramienta de línea de comandos para reescribir el historial de Git. Es la recomendación oficial del equipo de Git para reemplazar `git filter-branch`.

## Para qué sirve

- Eliminar texto de mensajes de commits
- Borrar archivos sensibles (.env, contraseñas) que quedaron en el historial
- Renombrar autores o emails en commits
- Reducir el tamaño de un repositorio eliminando archivos grandes

## Instalación

```bash
pip install git-filter-repo
```

## Uso básico

Eliminar texto de todos los mensajes de commits:

```bash
git filter-repo --message-callback '
return message.replace(b"texto a eliminar", b"")
' --force
```

Después de reescribir el historial, hacer force push:

```bash
git push origin main --force
```

## Importante

- Reescribe los hashes de todos los commits afectados
- Elimina el remote `origin` automáticamente (hay que volver a agregarlo)
- Es destructivo — usar con cuidado en ramas compartidas
