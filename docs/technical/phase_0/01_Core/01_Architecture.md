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

## 2. Frontend (UI Layer)

### Phoenix LiveView

Responsable de:

- UI reactiva en tiempo real
- Estado de reproducción (play/pause/velocidad)
- Interacción del usuario
- Comunicación con JS hooks

### Principio:
LiveView es el “cerebro de UI”, no el motor musical.

---

## 3. Audio Engine

### Tone.js (JavaScript)

Responsable de:

- Reproducción de audio en tiempo preciso
- Scheduler musical (Transport)
- Control de tempo (BPM / speed)
- Timing de notas

### Regla crítica:
Tone.js es la **única fuente de audio**.

---

## 4. Rendering Engine (Partituras)

### OpenSheetMusicDisplay (OSMD)

Responsable de:

- Renderizar MusicXML como SVG
- Mostrar pentagramas y notas
- Permitir highlight de notas activas

### Integración:
Se conecta vía JS Hook desde LiveView.

---

## 5. Data Layer (Formato Musical)

### Formatos soportados

- MusicXML (principal)
- MIDI (futuro / secundario)

### Responsabilidades

- Representar canciones
- Definir niveles de dificultad
- Mapear estructura musical → eventos temporales

---

## 6. Sync Engine (CRÍTICO)

Este es el **núcleo del sistema**.

### Responsabilidades:

- Sincronizar:
  - Audio (Tone.js)
  - Visual (OSMD)
  - Estado (LiveView)

### Modelo mental:

```text
MusicXML → Event Timeline → Sync Engine → (Audio + Visual)