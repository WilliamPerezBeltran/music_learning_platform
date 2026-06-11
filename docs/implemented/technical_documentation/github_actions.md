# 03 — GitHub Actions CI

## ¿Qué hace el sistema?

Ejecuta un pipeline de integración continua automáticamente en cada push y Pull Request a `main`.
Garantiza que el código compile, esté formateado, los assets construyan correctamente y los tests pasen antes de mergear.

---

## ¿Dónde encontrarlo?

```
.github/
└── workflows/
    └── ci.yml                       ← único workflow del proyecto
```

---

## ¿Cómo está construido?

### Trigger

```yaml
on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]
```

Corre en dos eventos: push directo a `main` y apertura/actualización de PR hacia `main`.

### Infraestructura

- Runner: `ubuntu-latest`
- Elixir: `1.19.5` + OTP `27` vía `erlef/setup-beam@v1`
- Node.js: `20` vía `actions/setup-node@v4`
- PostgreSQL: `16-alpine` como service container

### Variables de entorno globales

```
MIX_ENV=test
PGHOST=localhost
PGUSER=postgres
PGPASSWORD=postgres
PGDATABASE=music_learning_platform_test
```

Estas variables coinciden con las leídas en `config/test.exs`.

---

## ¿Cómo funciona internamente?

### Pasos del pipeline en orden

```
1. actions/checkout@v4               ← clona el repositorio

2. erlef/setup-beam@v1               ← instala Elixir 1.19.5 + OTP 27

3. actions/cache@v4 (deps)           ← restaura caché de deps/ por mix.lock
4. actions/cache@v4 (_build)         ← restaura caché de _build/ por mix.lock

5. actions/setup-node@v4             ← instala Node.js 20
                                        caché de npm por assets/package-lock.json

6. mix deps.get                      ← instala dependencias Elixir

7. npm install --prefix assets       ← instala Tone.js y OSMD en assets/node_modules/

8. mix format --check-formatted      ← falla si hay código sin formatear (MIX_ENV=test)

9. mix compile --warnings-as-errors  ← falla si hay warnings de compilación (MIX_ENV=test)

10. MIX_ENV=dev mix assets.setup     ← descarga binarios de esbuild y tailwind
11. MIX_ENV=dev mix assets.build     ← compila JS y CSS (bundle final)

12. mix test                         ← corre la suite de tests (MIX_ENV=test)
                                        incluye ecto.create + ecto.migrate automáticamente
```

### Por qué assets.setup y assets.build usan MIX_ENV=dev

`esbuild` y `tailwind` están declarados en `mix.exs` con `runtime: Mix.env() == :dev`.
En `MIX_ENV=test` no se inician como aplicaciones OTP.
Forzar `MIX_ENV=dev` en esos pasos garantiza que los binarios y tasks estén disponibles.

### Por qué se cachea `_build` y `deps` por separado

- `deps/` cambia cuando cambia `mix.lock` (nuevas dependencias)
- `_build/` incluye código compilado Y binarios de esbuild/tailwind descargados
- Cachear por `hashFiles('mix.lock')` invalida automáticamente el caché cuando cambian las dependencias

### PostgreSQL como service container

El contenedor de PostgreSQL arranca antes que los steps y espera el healthcheck:

```yaml
options: >-
  --health-cmd pg_isready
  --health-interval 5s
  --health-timeout 5s
  --health-retries 10
```

`mix test` corre el alias `["ecto.create --quiet", "ecto.migrate --quiet", "test"]`
que crea y migra la base de datos de test automáticamente.

---

## ¿Cómo se modifica sin romperlo?

### Agregar un nuevo step

Agregarlo en `.github/workflows/ci.yml` dentro de `steps:`.
Respetar el orden: deps → formato → compilación → assets → tests.

### Cambiar la versión de Elixir o OTP

```yaml
- name: Setup Elixir
  uses: erlef/setup-beam@v1
  with:
    elixir-version: "X.X.X"
    otp-version: "XX"
```

Actualizar también en `mix.exs` si hay restricción de versión en `elixir: "~> X.X"`.

### Agregar variables de entorno al pipeline

Agregarlas en la sección `env:` global del job o como `env:` dentro del step específico.
Si son secretas, agregarlas en GitHub → Settings → Secrets and variables → Actions,
y referenciarlas como `${{ secrets.NOMBRE_VARIABLE }}`.

### Correr tests en múltiples versiones de Elixir

Usar una `matrix` strategy:

```yaml
strategy:
  matrix:
    elixir: ["1.18", "1.19.5"]
    otp: ["26", "27"]
```
