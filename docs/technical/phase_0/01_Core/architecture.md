# Arquitectura Técnica Recomendada (Mejorada)

## 1. Backend (Core System)

### Phoenix + Elixir

Responsable de:

- Orquestación del estado de la aplicación
- Gestión de canciones, niveles y configuración
- Coordinación de sincronización (tiempo musical lógico)
- APIs internas para LiveView

### Concepto clave:
El backend **NO reproduce audio ni renderiza música**, solo coordina.

---

### Background Jobs / Workers (Capa Asíncrona)

Responsable de:

- Procesamiento de MusicXML
- Generación de niveles de canciones
- Validación y normalización de archivos musicales
- Pre-cálculo de estructuras para el Sync Engine
- Tareas pesadas fuera del flujo de LiveView

### Concepto clave:
Los workers son el backend diferido, no afectan la interacción en tiempo real.

---

### Event Timeline Layer (NÚCLEO MUSICAL)

Responsable de:

- Convertir MusicXML en eventos temporales
- Representar la canción como una línea de tiempo
- Servir como fuente de verdad del sistema musical
- Soportar niveles de dificultad (0.1 → 0.10)

### Concepto clave:
 Todo se sincroniza contra la timeline, no contra OSMD ni Tone.js

---

### State Model (CONTROL GLOBAL)

Responsable de:

- Estado de reproducción (play/pause/stop)
- Tiempo actual de la canción
- Nivel activo
- Canción activa
- Configuración visual global

### Concepto clave:
 Es la única fuente de verdad del sistema en runtime

---

## 2. Frontend (UI Layer)

### Phoenix LiveView

Responsable de:

- UI reactiva en tiempo real
- Estado de reproducción visual
- Interacción del usuario
- Comunicación con JS hooks

### Principio:
LiveView es el “cerebro de UI”, no el motor musical.

---

## 3. JS Bridge Layer (COMUNICACIÓN)

Responsable de:

- Conectar LiveView ↔ JavaScript
- Emitir eventos de reproducción
- Sincronizar estado con Tone.js y OSMD
- Manejar hooks del frontend

### Componentes:

- OSMD Hook
- Tone.js Player Hook
- Sync Controller Hook

### Concepto clave:
 Es el puente obligatorio entre backend y motor musical

---

## 4. Audio Engine

### Tone.js (JavaScript)

Responsable de:

- Reproducción de audio en tiempo preciso
- Scheduler musical (Transport)
- Control de tempo (BPM / speed)
- Timing de notas

### Regla crítica:
Tone.js es la **única fuente de audio**

---

## 5. Rendering Engine (Partituras)

### OpenSheetMusicDisplay (OSMD)

Responsable de:

- Renderizar MusicXML como SVG
- Mostrar pentagramas y notas
- Highlight de notas activas

### Integración:
Se conecta vía JS Bridge Layer

---

## 6. Data Layer (Formato Musical)

### Formatos soportados

- MusicXML (principal)
- MIDI (futuro)

### Responsabilidades

- Representar canciones
- Definir niveles de dificultad
- Convertir datos → Event Timeline

---

## 7. Sync Engine (CRÍTICO)

Responsable de:

- Sincronizar Timeline → Audio + Visual
- Coordinar OSMD y Tone.js
- Mantener consistencia temporal

### Modelo mental:

```text
MusicXML → Event Timeline → Sync Engine → (Audio + Visual)
```

---

┌──────────────────────────────────────────────────────────────┐
│                        USER BROWSER                          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              Phoenix LiveView (UI Layer)             │    │
│  │                                                      │    │
│  │  - Play / Pause / Controls                           │    │
│  │  - Visual feedback (colores, notas)                  │    │
│  │  - Estado UI                                         │    │
│  └──────────────────────────────────────────────────────┘    │
│                 │                         │                  │
│                 │ JS Bridge Layer        │ Events            │
│                 ▼                         ▼                  │
│        ┌───────────────────┐   ┌────────────────────┐        │
│        │   OSMD Renderer   │   │   Tone.js Audio    │        │
│        │ (Partituras SVG)  │   │ (Playback Engine)  │        │
│        └───────────────────┘   └────────────────────┘        │
│                                                              │
└───────────────────────────────┬──────────────────────────────┘
                                │
                                │ LiveView Events / State Sync
                                ▼
┌───────────────────────────────────────────────────────────-──┐
│                     BACKEND (PHOENIX / ELIXIR)               │
│                                                              │
│  ┌─────────────────────────────────────────────────────-┐    │
│  │                 STATE MODEL (GLOBAL)                 │    │
│  │                                                      │    │
│  │  - canción activa                                    │    │
│  │  - nivel activo                                      │    │
│  │  - tiempo actual                                     │    │
│  │  - estado play/pause                                 │    │
│  └──────────────────────────────────────────────────────┘    │
│                              │                               │
│                              ▼                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              SYNC ENGINE (CORE MUSICAL)              │    │
│  │                                                      │    │
│  │  Timeline → sincroniza audio + visual                │    │
│  │                                                      │    │
│  │  MusicXML → Event Timeline → Sync Engine             │    │
│  └──────────────────────────────────────────────────────┘    │
│                              │                               │
│                              ▼                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │           EVENT TIMELINE (MUSICAL CORE)              │    │
│  │                                                      │    │
│  │  notas con tiempo, duración, nivel                   │    │
│  │  fuente de verdad musical                            │    │
│  └──────────────────────────────────────────────────────┘    │
│                              │                               │
│                              ▼                               │
│  ┌──────────────────────────────────────────────────────┐    │
│  │     BACKGROUND WORKERS (ASYNC PROCESSING)            │    │
│  │                                                      │    │
│  │  - procesar MusicXML                                 │    │
│  │  - generar niveles                                   │    │
│  │  - normalizar datos                                  │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘


# Explicación simple del flujo

## 1. Usuario interactúa

- Da Play  
- Cambia velocidad  
- Selecciona canción  

---

## 2. LiveView (UI Layer)

- Recibe acción  
- Actualiza estado  
- Envía evento a JS Bridge  

---

## 3. JS Bridge Layer

- Conecta backend ↔ frontend  
- Envía comandos a:  
  - OSMD (visual)  
  - Tone.js (audio)  

---

## 4. OSMD + Tone.js

- OSMD → dibuja partituras  
- Tone.js → reproduce audio  

---

## 5. Backend (cerebro real)

### State Model
- controla TODO el estado global  

### Event Timeline
- convierte música en eventos con tiempo real  

### Sync Engine
- asegura que audio + visual van sincronizados  

---

## 6. Workers (background)

- preparan canciones antes de reproducirse  
- generan niveles  
- procesan archivos pesados  


### IDEA CLAVE DEL SISTEMA
```text
MusicXML
   ↓
Event Timeline (verdad musical)
   ↓
Sync Engine (coordinador)
   ↓
Audio (Tone.js) + Visual (OSMD)
```

### RESUMEN ULTRA SIMPLE

- LiveView = UI
- JS Bridge = conexión
- Tone.js = sonido
- OSMD = visual
- Event Timeline = música real
- Sync Engine = cerebro del sistema
- Workers = procesamiento en background
- State Model = control global