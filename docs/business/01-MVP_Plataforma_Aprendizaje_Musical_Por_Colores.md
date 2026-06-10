# Propuesta MVP – Plataforma de Aprendizaje Musical por Colores

## Visión

Crear una plataforma educativa para aprender piano mediante un sistema visual basado en colores, permitiendo que niños y principiantes puedan tocar canciones rápidamente sin necesidad de conocimientos musicales previos.

La idea es combinar:

* Partituras coloreadas.
* Reproducción interactiva.
* Tutoriales guiados.
* Niveles progresivos.
* Contenido gratuito inicial y modelo de suscripción para contenido avanzado.

---

# Referencias Analizadas

## Aplicaciones similares

* https://www.color-coded.app/
* https://klang.io/piano2notes/
* https://www.coloredmusicsheet.com/
* https://playxylo.com/songs?colors=chromanotes

## Conceptos que funcionan bien

* Notas identificadas por colores.
* Nombre de las notas visible.
* Reproducción automática.
* Aprendizaje progresivo.
* Interfaz simple para niños.
* Canciones populares e infantiles.

---

# MVP Inicial

## Funcionalidades básicas

### Partitura interactiva

* Pentagrama tradicional.
* Notas coloreadas.
* Nombre de la nota debajo.
* Letra de la canción.
* Reproducción automática.
* Control de velocidad.
* Indicador visual de la nota actual.

### Opciones de visualización

El usuario podrá activar o desactivar:

* Colores.
* Nombre de las notas.
* Mano izquierda.
* Mano derecha.
* Acordes.
* Letra.
* Numeración de dedos (futuro).

---

# Sistema de Niveles

Cada canción tendrá múltiples versiones.

## Nivel 1

Solo melodía principal.

Ejemplo:

```text
Do Re Mi Fa Sol
```

## Nivel 2

Melodía + notas simples de acompañamiento.

## Nivel 3

Melodía + acordes básicos.

## Nivel 4

Mano izquierda simplificada.

## Nivel 5

Canción completa.

## Niveles Avanzados

Hasta llegar a una interpretación completa y realista de la pieza.

Ejemplo:

```text
Nivel 1 → Solo melodía
Nivel 2 → Melodía + bajos
Nivel 3 → Melodía + acordes
Nivel 4 → Dos manos simplificadas
Nivel 5 → Canción completa
```

---

# Modelo de Negocio

## Freemium

### Gratis

* Primeras canciones.
* Primeros niveles.
* Funciones básicas.

### Premium

* Biblioteca completa.
* Todos los niveles.
* Canciones nuevas cada semana.
* Seguimiento de progreso.
* Tutoriales exclusivos.
* Descarga de partituras PDF.

---

# Estrategia de Crecimiento

## Contenido para redes sociales

Crear videos cortos mostrando:

* Cómo tocar canciones famosas.
* Cómo aprender con colores.
* Antes y después del estudiante.
* Tutoriales rápidos.

Objetivo:

```text
Video
↓
Usuario visita web
↓
Prueba canciones gratis
↓
Descarga aplicación
↓
Suscripción Premium
```

---

# Arquitectura Técnica Recomendada

## Backend

Phoenix + Elixir

## Frontend

Phoenix LiveView

## Audio

Tone.js

## Renderizado de partituras

OpenSheetMusicDisplay

## Formatos musicales

* MusicXML
* MIDI

## IA futura

Microservicio Python independiente para:

* Generación automática de niveles.
* Conversión de audio a partituras.
* Recomendaciones personalizadas.

---

# Ventajas de este enfoque

* Una sola aplicación web.
* Funciona en computador.
* Funciona en tablet.
* Funciona en móvil.
* Menor complejidad inicial que Flutter + múltiples plataformas.
* Excelente rendimiento para contenido musical.
* Permite lanzar rápidamente un MVP.

---

# Diferenciador Principal

El valor no está únicamente en mostrar partituras coloreadas.

El verdadero producto es:

```text
Canción
↓
Nivel 1 (solo melodía)
↓
Nivel 2 (melodía + bajos)
↓
Nivel 3 (acordes básicos)
↓
Nivel 4 (dos manos simplificadas)
↓
Nivel 5 (canción completa)
↓
Tutorial en video
↓
Seguimiento de progreso
```

La combinación de:

* Partituras por colores.
* Aprendizaje progresivo.
* Videos guiados.
* Biblioteca de canciones.


