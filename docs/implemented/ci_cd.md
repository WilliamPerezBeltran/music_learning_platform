# CI/CD — Music Learning Platform

## Flujo completo

```
push a feature/* o fix/*
        ↓
   Pull Request → main
        ↓
   CI corre tests automáticamente
        ↓
   PR aprobado + tests verdes
        ↓
   Merge a main
        ↓
   CD hace deploy automático a Fly.io
```

---

## CI — Integración Continua

**Archivo:** `.github/workflows/ci.yml`

**Se activa:** en cada Pull Request hacia `main`

**Qué hace:**
1. Levanta PostgreSQL 16 en el runner de GitHub
2. Instala Elixir 1.19.5 + OTP 28
3. Instala dependencias (`mix deps.get`)
4. Compila (`mix compile --warnings-as-errors`)
5. Corre migraciones (`mix ecto.migrate`)
6. Corre los 133 tests (`mix test`)

**Resultado:**
- ✅ Tests pasan → merge habilitado
- ❌ Tests fallan → merge bloqueado

---

## CD — Entrega Continua

**Archivo:** `.github/workflows/fly-deploy.yml`

**Se activa:** en cada push o merge a `main`

**Qué hace:**
1. Instala flyctl
2. Corre `fly deploy --remote-only`
3. Fly buildea la imagen Docker y deploya en producción
4. Las migraciones corren automáticamente (via `release_command`)

**Secret requerido en GitHub:**
- `FLY_API_TOKEN` → token de deploy de Fly.io

---

## Branch Protection en main

Configurado en GitHub → Settings → Branches → Ruleset:

- ✅ Require pull request before merging
- ✅ Require status checks to pass (job: `Tests`)
- ✅ Block force pushes
- ✅ Restrict deletions

**Nadie puede hacer push directo a `main`.**

---

## Reglas de trabajo

| Acción | Permitido |
|---|---|
| Push directo a `main` | ❌ |
| Push a `feature/*`, `fix/*`, `chore/*` | ✅ |
| Merge sin tests verdes | ❌ |
| Merge con tests verdes | ✅ |
| Deploy manual | `fly deploy` desde terminal |

---

## Secrets en GitHub

| Secret | Descripción |
|---|---|
| `FLY_API_TOKEN` | Token de deploy para Fly.io |

Agregar en: `GitHub → Settings → Secrets and variables → Actions`
