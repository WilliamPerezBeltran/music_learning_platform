# SOLID Principles en Phoenix (Elixir)

# Introducción

Los principios SOLID son un conjunto de reglas de diseño orientadas a construir software mantenible, extensible y fácil de probar. Aunque fueron formulados originalmente para lenguajes orientados a objetos, sus conceptos aplican perfectamente a Phoenix y Elixir.

En Phoenix, SOLID debe aplicarse principalmente en:

* Contexts
* Domain Services
* Policies
* Queries
* Commands
* Workers
* Integraciones externas
* LiveViews
* Controllers

No debe aplicarse ciegamente a Schemas ni a estructuras simples de datos.

---

# S — Single Responsibility Principle (SRP)

## Definición

Un módulo debe tener una única razón para cambiar.

Cada módulo debe encargarse de una sola responsabilidad del negocio.

---

## Incorrecto

```elixir
defmodule MusicLearning.Songs do
  def create_song(attrs) do
    # validar
    # guardar
    # generar thumbnail
    # enviar email
    # registrar auditoría
    # indexar búsqueda
  end
end
```

Este módulo tiene múltiples responsabilidades.

---

## Correcto

```elixir
Songs.create_song(attrs)

SongThumbnailGenerator.generate(song)

SongNotifier.notify_creation(song)

SongAudit.log_creation(song)

SongSearchIndexer.index(song)
```

Cada módulo hace una sola cosa.

---

## En Phoenix

Separar:

```text
Context
    ↓
Domain Service
    ↓
Repository
    ↓
Notifications
    ↓
Search
```

No mezclar todo en el Context.

---

# O — Open/Closed Principle (OCP)

## Definición

El software debe estar abierto para extensión y cerrado para modificación.

Debemos poder agregar comportamiento nuevo sin modificar código existente.

---

## Incorrecto

```elixir
def play_sound(type) do
  case type do
    :piano -> ...
    :guitar -> ...
    :violin -> ...
  end
end
```

Cada nuevo instrumento obliga a modificar el módulo.

---

## Correcto

```elixir
defprotocol Instrument do
  def play(instrument, note)
end
```

Implementaciones:

```elixir
defimpl Instrument, for: Piano do
  ...
end

defimpl Instrument, for: Violin do
  ...
end
```

Ahora se pueden agregar instrumentos nuevos sin modificar el código existente.

---

## Aplicación práctica

Sistema de reproducción:

```text
Playback Engine
    ↓
Instrument Behaviour
    ↓
Piano
Guitar
Violin
Flute
Trumpet
```

---

# L — Liskov Substitution Principle (LSP)

## Definición

Una implementación debe poder sustituir a otra sin romper el sistema.

---

## Incorrecto

```elixir
defmodule Piano do
  def play(note) do
    ...
  end
end

defmodule BrokenInstrument do
  def play(note) do
    raise "not implemented"
  end
end
```

No puede reemplazar a Piano.

---

## Correcto

```elixir
@callback play(note :: String.t()) :: :ok
```

Todas las implementaciones respetan el contrato.

```elixir
Piano.play("C4")
Violin.play("C4")
Flute.play("C4")
```

Funcionan exactamente igual desde el punto de vista del consumidor.

---

## Aplicación en Phoenix

Cuando usamos Behaviours:

```elixir
PaymentProvider

StorageProvider

EmailProvider

InstrumentProvider
```

Todas las implementaciones deben cumplir el mismo contrato.

---

# I — Interface Segregation Principle (ISP)

## Definición

Los consumidores no deben depender de funciones que no utilizan.

---

## Incorrecto

```elixir
@callback create()
@callback update()
@callback delete()
@callback upload()
@callback stream()
@callback notify()
```

Todos los módulos deben implementar todo.

---

## Correcto

```elixir
StorageBehaviour

NotificationBehaviour

StreamingBehaviour
```

Interfaces pequeñas y específicas.

---

## Ejemplo

En lugar de:

```elixir
MusicProvider
```

tener:

```elixir
PlaybackProvider

RecordingProvider

ExportProvider
```

Cada módulo implementa únicamente lo necesario.

---

# D — Dependency Inversion Principle (DIP)

## Definición

Los módulos de alto nivel no deben depender de módulos de bajo nivel.

Ambos deben depender de abstracciones.

---

## Incorrecto

```elixir
defmodule Songs do
  def create(attrs) do
    Mailgun.send_email(...)
  end
end
```

Songs depende directamente de Mailgun.

---

## Correcto

```elixir
defmodule Songs do
  def create(attrs) do
    EmailProvider.send(...)
  end
end
```

Configuración:

```elixir
config :music_learning,
  email_provider: MailgunProvider
```

Obtención:

```elixir
Application.fetch_env!(
  :music_learning,
  :email_provider
)
```

---

## Beneficios

Cambiar:

```text
Mailgun
```

por:

```text
SendGrid
```

no afecta el dominio.

---

# SOLID aplicado a una arquitectura Phoenix

## Context Layer

Responsabilidad:

```text
Coordinar casos de uso
```

No debe:

```text
Enviar emails
Generar PDFs
Hablar con AWS
Procesar imágenes
```

---

## Domain Services

Responsabilidad:

```text
Lógica de negocio
```

Ejemplo:

```text
SongProgressCalculator

LessonCompletionService

AchievementAwarder
```

---

## LiveViews

Responsabilidad:

```text
UI
Eventos
Estado visual
```

No deben contener:

```text
Reglas complejas de negocio
```

---

## Workers

Responsabilidad:

```text
Procesos asíncronos
```

Ejemplo:

```text
EmailWorker

ThumbnailWorker

ImportCsvWorker
```

---

## Queries

Responsabilidad:

```text
Consultas complejas
```

Ejemplo:

```elixir
SongsQueries

LessonsQueries

ProgressQueries
```

---

## Commands

Responsabilidad:

```text
Operaciones que modifican estado
```

Ejemplo:

```text
CreateSong

PublishSong

CompleteLesson

AwardAchievement
```

---

# Estructura recomendada

```text
lib/
├── music_learning/
│
├── songs/
│   ├── song.ex
│   ├── commands/
│   ├── queries/
│   ├── services/
│   ├── policies/
│   ├── validators/
│   └── behaviours/
│
├── lessons/
│   ├── lesson.ex
│   ├── commands/
│   ├── queries/
│   ├── services/
│   ├── policies/
│   └── validators/
│
├── infrastructure/
│   ├── email/
│   ├── storage/
│   ├── search/
│   └── payments/
│
└── web/
    ├── live/
    ├── controllers/
    └── components/
```

---

# Regla práctica para Phoenix

Antes de escribir un módulo pregúntate:

1. ¿Tiene una sola responsabilidad?

   * SRP

2. ¿Puedo extenderlo sin modificarlo?

   * OCP

3. ¿Puedo sustituir una implementación por otra?

   * LSP

4. ¿La interfaz es pequeña y específica?

   * ISP

5. ¿Dependo de una abstracción y no de una implementación concreta?

   * DIP

Si las cinco respuestas son "sí", el diseño probablemente está alineado con SOLID.
