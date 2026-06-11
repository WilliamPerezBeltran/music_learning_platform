# music_learning_platform

---

## Documentación

```
docs/
├── planned/
└── implemented/
```

### planned/
Todo lo que se pensó antes de desarrollar.

**Pregunta que responde:** ¿Qué vamos a construir?

Contiene la visión del producto, decisiones de arquitectura, modelo de datos, roadmap de fases y documentación técnica de referencia de cada componente del sistema, escrita antes de escribir una sola línea de código.

---

### implemented/
Todo lo que ya existe en el código.

**Pregunta que responde:** ¿Qué ya está construido y cómo?

#### technical_documentation

**Proyecto Phoenix**
Se creó el proyecto base con `mix phx.new` usando Phoenix 1.8.5 + LiveView 1.1 + Tailwind v4 + DaisyUI + Heroicons v2.2 + Bandit como servidor HTTP. La base de datos es PostgreSQL 16.

**Docker**
Se configuraron tres modos de ejecución:
- `docker compose up` — app + base de datos en contenedores (puertos 4000 y 5410)
- `docker compose -f docker-compose.db.yml up` — solo PostgreSQL en Docker, app corre local
- `mix phx.server` — todo local

**Dependencias agregadas**

| Capa | Paquete | Versión | Propósito |
|---|---|---|---|
| Elixir | `sweet_xml` | 0.7.5 | Parseo de archivos MusicXML en el backend |
| JavaScript | `tone` | 15.1.3 | Motor de audio — reproducción de notas en el navegador |
| JavaScript | `opensheetmusicdisplay` | 1.9.1 | Renderizado de partituras MusicXML como SVG |


### Ramas
```
main        ← producción, solo merge via PR
feature/*   ← nuevas funcionalidades
fix/*       ← correcciones de bugs
chore/*     ← mantenimiento
```

### Commits (Conventional Commits)
```
feat(scope): descripción
fix(scope): descripción
refactor(scope): descripción
test(scope): descripción
docs(scope): descripción
chore(scope): descripción
```

---