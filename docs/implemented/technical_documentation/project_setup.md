# Configuración del Proyecto

## ¿Qué hace el sistema?

Aplicación web Phoenix que sirve como base de la plataforma de aprendizaje musical.
En este estado expone una página de inicio por defecto con la base de datos conectada.
No tiene funcionalidad musical aún — es el esqueleto sobre el que se construye todo lo demás.

---

## ¿Cómo está construido?

### Stack

| Tecnología | Versión | Rol |
|---|---|---|
| Elixir | 1.19.5 | Lenguaje del backend |
| Phoenix | 1.8.5 | Framework web |
| Phoenix LiveView | 1.1 | UI reactiva en tiempo real |
| PostgreSQL | 16 | Base de datos |
| Tailwind v4 + DaisyUI | — | Estilos CSS |
| Heroicons | v2.2 | Íconos |
| Bandit | 1.12 | Servidor HTTP |
| esbuild | 0.25 | Bundler de assets JS |

### Estructura de archivos

```
/
├── mix.exs                                        ← dependencias y aliases del proyecto
├── mix.lock                                       ← versiones exactas de dependencias
├── CLAUDE.md                                      ← contexto del proyecto para Claude Code
├── CONTEXT.md                                     ← referencia técnica del proyecto
├── AGENTS.md                                      ← guías Phoenix 1.8 para agentes AI
├── config/
│   ├── config.exs                                 ← configuración base (esbuild, tailwind, endpoint)
│   ├── dev.exs                                    ← configuración de desarrollo (DB via env vars, live reload)
│   ├── test.exs                                   ← configuración de tests (DB via env vars, sandbox)
│   ├── prod.exs                                   ← configuración de producción
│   └── runtime.exs                                ← variables de entorno en runtime
├── lib/
│   ├── music_learning_platform/
│   │   ├── application.ex                         ← punto de entrada OTP, árbol de supervisión
│   │   ├── repo.ex                                ← conexión a PostgreSQL (Ecto)
│   │   └── mailer.ex                              ← configuración de email
│   └── music_learning_platform_web/
│       ├── router.ex                              ← rutas HTTP
│       ├── endpoint.ex                            ← configuración del endpoint HTTP
│       ├── components/
│       │   ├── core_components.ex                 ← componentes reutilizables (inputs, botones, etc.)
│       │   └── layouts.ex                         ← layouts de la app
│       └── controllers/
│           └── page_controller.ex                 ← controlador de la página de inicio
├── assets/
│   ├── js/app.js                                  ← entry point JavaScript
│   ├── css/app.css                                ← entry point CSS (Tailwind)
│   ├── package.json                               ← dependencias JS (tone, opensheetmusicdisplay)
│   ├── package-lock.json                          ← versiones exactas JS
│   └── vendor/                                    ← librerías JS incluidas por Phoenix
├── priv/
│   ├── repo/migrations/                           ← migraciones de base de datos
│   └── static/                                    ← archivos estáticos servidos públicamente
├── test/                                          ← tests del proyecto
├── Dockerfile                                     ← imagen genérica
├── Dockerfile.dev                                 ← imagen de desarrollo con hot reload
├── docker-compose.yml                             ← app + PostgreSQL en contenedores
├── .env.example                                   ← variables de entorno requeridas
└── .github/
    └── workflows/
        └── ci.yml                                 ← pipeline de integración continua
```

---

## ¿Cómo funciona internamente?

### Arranque del sistema

```
mix phx.server
    ↓
MusicLearningPlatform.Application.start/2          ← lib/music_learning_platform/application.ex
    ↓
Supervisor inicia:
  ├── MusicLearningPlatform.Repo                   ← pool de conexiones PostgreSQL
  ├── MusicLearningPlatformWeb.Endpoint            ← servidor HTTP (Bandit)
  └── MusicLearningPlatform.PubSub                 ← bus de mensajes LiveView
    ↓
Request HTTP → Endpoint → Router → Controller → Respuesta
```

### Configuración de base de datos

`config/dev.exs` y `config/test.exs` leen variables de entorno con fallback a valores locales:

```elixir
# dev.exs
hostname: System.get_env("DB_HOST", "localhost")
username: System.get_env("DB_USER", "postgres")
password: System.get_env("DB_PASSWORD", "postgres")
database: System.get_env("DB_NAME", "music_learning_platform_dev")

# test.exs
hostname: System.get_env("PGHOST", "localhost")
username: System.get_env("PGUSER", "postgres")
password: System.get_env("PGPASSWORD", "postgres")
```

En Docker, estas variables las inyecta `docker-compose.yml`.

### Modos de ejecución

| Modo | Comando | Puerto app | Puerto DB |
|---|---|---|---|
| Docker completo | `docker compose up` | 4000 | 5410 |
| Solo DB en Docker | `docker compose -f docker-compose.db.yml up` + `mix phx.server` | 4000 local | 5410 |
| Todo local | `mix phx.server` | 4000 | 5432 local |

---

## ¿Cómo se modifica sin romperlo?

### Agregar una ruta

1. Definir en `lib/music_learning_platform_web/router.ex`
2. Crear controlador en `lib/music_learning_platform_web/controllers/`
3. Crear template en `lib/music_learning_platform_web/controllers/{nombre}_html/`

### Agregar una migración

```bash
mix ecto.gen.migration nombre_de_la_migracion
# editar el archivo generado en priv/repo/migrations/
mix ecto.migrate
```

### Variables de entorno

Copiar `.env.example` a `.env` y ajustar los valores.
Los fallbacks en `dev.exs` y `test.exs` permiten correr sin `.env` en desarrollo local.

### Verificar que nada se rompió

```bash
mix precommit
# compile --warnings-as-errors + deps.unlock --unused + format + test
```
