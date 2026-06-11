# Explicación del Modelo de Datos vs tu MVP Core (conectado)

---

# 1. La idea clave

Tu sistema NO es una base de datos compleja.

Es esto:

> Una canción → varias versiones (niveles) → una versión se convierte en datos de tiempo → eso se reproduce en pantalla en tiempo real

Todo el modelo gira alrededor de eso.

---

# 2. Cómo se traduce tu MVP al modelo de datos

## MVP: “Tomar una canción, dividirla en niveles, mostrarla y reproducirla”

---

# Song = la canción base

Ejemplo:
- Bartolito
- Estrellita

Aquí NO hay niveles todavía.

---

# SongVersion = los niveles del MVP

Esto ES tu sistema de niveles.

Ejemplo:

Bartolito
├── Nivel 1 (melodía)
├── Nivel 2 (simplificada)
├── Nivel 3 (acordes)
└── Nivel 4 (completa)

Cada nivel ES una SongVersion

---

# ContentAsset = archivos crudos

Aquí guardas:
- MusicXML
- audio
- MIDI

Ejemplo:

Bartolito → musicxml_v1.xml  
Bartolito → audio.mp3  

Esto es solo almacenamiento, no lógica.

---

# MusicTimeline = canción lista para reproducir

Aquí empieza lo importante del MVP.

Significa:

“Ya convertí el MusicXML en algo que puedo reproducir en tiempo real”

Contiene:
- BPM
- duración total
- precisión de tiempo

Es el motor temporal de la canción.

---

# MusicalEvent = lo que ves en pantalla

Esto es lo más importante del MVP.

Ejemplo:

note_on C4 en 0.5s  
note_off C4 en 1.0s  
note_on E4 en 1.0s  

Cada evento es:
- una nota
- un acorde
- un silencio
- un inicio/fin

Esto permite:
- resaltar nota actual
- sincronizar audio
- mostrar colores
- mostrar letra sincronizada

---

# PlaybackSession = estado del usuario

Esto es runtime:

Ejemplo:
- canción actual
- nivel actual
- tiempo actual (32s)
- play / pause
- velocidad

No es contenido, es estado.

---

# 3. Flujo real del sistema

1. Song (Bartolito)
      ↓
2. SongVersion (Nivel 1, 2, 3, 4)
      ↓
3. MusicTimeline (versión procesada)
      ↓
4. MusicalEvents (notas con tiempo)
      ↓
5. PlaybackSession (usuario reproduciendo)

---

# 4. En lenguaje simple

1. Subo una canción → Song  
2. Creo niveles → SongVersion  
3. La convierto a tiempo → MusicTimeline  
4. La divido en notas → MusicalEvent  
5. El usuario la reproduce → PlaybackSession  

---

# 5. Lo que te estaba confundiendo

Tu modelo mezcla 3 cosas:

## A. Contenido
- Song
- SongVersion
- ContentAsset

## B. Motor musical
- MusicTimeline
- MusicalEvent

## C. Runtime del usuario
- PlaybackSession

---

# 6. Relación directa con el MVP

## MVP Core 1: Mostrar canción
- Song
- SongVersion
- MusicalEvent

## MVP Core 2: Reproducir canción
- MusicTimeline
- MusicalEvent
- PlaybackSession

## MVP Core 3: Niveles
- SongVersion

## MVP Core 4: Configuración visual
- MusicalEvent (qué mostrar o no mostrar)

---

# 7. Versión mínima del sistema

Song  
 └── SongVersion (niveles)  
        └── MusicalEvent (notas en el tiempo)  
               └── PlaybackSession (usuario interactuando)

---

# 8. Resumen final

- Song → canción
- SongVersion → niveles
- MusicTimeline + MusicalEvent → música en tiempo real
- PlaybackSession → interacción del usuario