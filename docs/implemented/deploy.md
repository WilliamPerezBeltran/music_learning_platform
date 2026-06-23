# Deploy — Music Learning Platform

## Dónde está corriendo

| Componente | Servicio | URL / Host |
|---|---|---|
| App (Phoenix) | Fly.io | https://music-demo.fly.dev |
| Base de datos | Supabase (PostgreSQL) | db.hnlralzfqhgzbthwopcx.supabase.co |

## Stack de producción

- **Fly.io** — hostea la app Phoenix como contenedor Docker
- **Supabase** — PostgreSQL gratuito externo (500MB free tier)
- **Docker** — multi-stage build: compila en Elixir, corre en elixir-slim

## Archivos clave de deploy

| Archivo | Propósito |
|---|---|
| `Dockerfile` | Build de producción multi-stage |
| `fly.toml` | Configuración de Fly.io (región, puerto, release command) |
| `rel/overlays/bin/migrate` | Script de migraciones |
| `rel/env.sh.eex` | Variables de entorno para el release |
| `lib/music_learning_platform/release.ex` | Funciones `migrate/0` y `seed/0` para producción |

## Variables de entorno en Fly.io

Están guardadas como secrets encriptados en Fly.io (nunca en el código):

```bash
fly secrets list -a music-demo
# DATABASE_URL   → conexión a Supabase
# SECRET_KEY_BASE → clave de Phoenix
```

---

## Pasos para hacer deploy

### Primera vez (ya hecho)

1. Instalar flyctl: https://fly.io/docs/hands-on/install-flyctl/
2. Login: `fly auth login`
3. Crear app: `fly launch` (responder las preguntas)
4. Setear secrets:
   ```bash
   fly secrets set DATABASE_URL="postgresql://postgres:PASSWORD@db.xxx.supabase.co:5432/postgres?sslmode=require" -a music-demo
   ```
5. Deploy: `fly deploy`
6. Correr migraciones: (se ejecutan automáticamente en cada deploy via `release_command`)
7. Cargar canciones (solo primera vez):
   ```bash
   fly ssh console -a music-demo -C "/app/bin/music_learning_platform eval 'MusicLearningPlatform.Release.seed()'"
   ```

---

### Deploy normal (cada vez que hay cambios)

```bash
fly deploy
```

Las migraciones corren automáticamente antes de iniciar la app.

---

### Comandos útiles

```bash
# Ver estado de la app
fly status -a music-demo

# Ver logs en tiempo real
fly logs -a music-demo

# Abrir la app en el browser
fly open -a music-demo

# Entrar a la consola del servidor
fly ssh console -a music-demo

# Correr migraciones manualmente
fly ssh console -a music-demo -C "/app/bin/music_learning_platform eval 'MusicLearningPlatform.Release.migrate()'"

# Cargar seeds
fly ssh console -a music-demo -C "/app/bin/music_learning_platform eval 'MusicLearningPlatform.Release.seed()'"
```

---

## Supabase — Base de datos

- **Panel:** https://supabase.com/dashboard
- **Free tier:** 500MB, sin expiración
- **Cambiar contraseña:** Supabase → Settings → Database → Reset password
- Después de cambiar contraseña, actualizar secret en Fly:
  ```bash
  fly secrets set DATABASE_URL="postgresql://postgres:NUEVA_PASSWORD@db.hnlralzfqhgzbthwopcx.supabase.co:5432/postgres?sslmode=require" -a music-demo
  fly deploy
  ```
