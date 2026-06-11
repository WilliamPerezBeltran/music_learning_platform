# Dependencias Instaladas

## ¿Qué hace el sistema con estas dependencias?

Cada dependencia cubre una capa específica de la arquitectura.
Juntas habilitan: backend Elixir, renderizado de partituras, reproducción de audio y base de datos.

---

## ¿Dónde están declaradas?

| Tipo | Archivo |
|---|---|
| Dependencias Elixir | `mix.exs` → función `deps/0` |
| Versiones exactas Elixir | `mix.lock` |
| Dependencias JavaScript | `assets/package.json` |
| Versiones exactas JS | `assets/package-lock.json` |
| Binarios descargados | `_build/` (esbuild, tailwind) |
| Módulos JS instalados | `assets/node_modules/` (ignorado por git) |

---

## Dependencias Elixir

### Instaladas con el proyecto (Phoenix 1.8.5)

| Paquete | Versión | Rol en el sistema |
|---|---|---|
| `phoenix` | 1.8.8 | Framework web — routing, controllers, LiveView |
| `phoenix_live_view` | 1.1.31 | UI reactiva — capa de presentación del sistema |
| `phoenix_ecto` | 4.7.0 | Integración Phoenix + Ecto |
| `ecto_sql` | 3.14.0 | ORM y query builder para PostgreSQL |
| `postgrex` | 0.22.2 | Driver PostgreSQL |
| `bandit` | 1.12.0 | Servidor HTTP |
| `jason` | 1.4.5 | Serialización JSON |
| `tailwind` | 0.4.1 | Wrapper Mix para Tailwind CSS |
| `esbuild` | 0.10.0 | Wrapper Mix para esbuild (bundler JS) |
| `heroicons` | v2.2.0 | Íconos SVG vía componente `<.icon>` |
| `gettext` | 1.0.2 | Internacionalización |
| `swoosh` | 1.26.1 | Email (no usado en Fase 0) |
| `req` | 0.6.1 | HTTP client |
| `dns_cluster` | 0.2.0 | Clustering de nodos Elixir |
| `phoenix_live_dashboard` | 0.8.7 | Dashboard de métricas en `/dev/dashboard` |
| `telemetry_metrics` | 1.1.0 | Métricas del sistema |
| `telemetry_poller` | 1.3.0 | Polling de métricas |
| `phoenix_live_reload` | 1.6.2 | Hot reload en desarrollo |

### Agregada en Fase 0

| Paquete | Versión | Archivo | Propósito |
|---|---|---|---|
| `sweet_xml` | 0.7.5 | `mix.exs` | Parseo de archivos MusicXML — pendiente de uso hasta implementar el parser |

---

## Dependencias JavaScript

### Agregadas en Fase 0

| Paquete | Versión | Archivo | Propósito |
|---|---|---|---|
| `opensheetmusicdisplay` | ^1.9.1 | `assets/package.json` | Renderizado de partituras MusicXML como SVG — pendiente de integración |
| `tone` | ^15.1.3 | `assets/package.json` | Motor de audio en el navegador — pendiente de integración |

### Incluidas por Phoenix (vendor)

| Archivo | Rol |
|---|---|
| `assets/vendor/topbar.js` | Barra de progreso en navegación |
| `assets/vendor/heroicons.js` | Íconos SVG |
| `assets/vendor/daisyui.js` | Componentes UI sobre Tailwind |
| `assets/vendor/daisyui-theme.js` | Temas de DaisyUI |

---

## ¿Cómo funciona internamente?

### Flujo de assets JS en el navegador

```
assets/js/app.js                     ← entry point
    ↓ esbuild bundlea
priv/static/assets/js/app.js         ← bundle final servido al navegador
```

`opensheetmusicdisplay` y `tone` están instalados en `assets/node_modules/`
y serán importados en `assets/js/app.js` cuando se implementen los hooks.

---

## ¿Cómo se modifica sin romperlo?

### Actualizar una dependencia Elixir

```bash
mix hex.info nombre_paquete
mix deps.update nombre_paquete
mix test
```

### Actualizar una dependencia JavaScript

```bash
npm update nombre_paquete --prefix assets
MIX_ENV=dev mix assets.build
mix test
```

### Agregar una nueva dependencia Elixir

1. Agregar en `deps/0` en `mix.exs`
2. `mix deps.get`
3. Verificar con `mix precommit`

### Agregar una nueva dependencia JavaScript

1. Agregar en `assets/package.json`
2. `npm install --prefix assets`
3. Importar en `assets/js/app.js`
4. Verificar con `MIX_ENV=dev mix assets.build`
