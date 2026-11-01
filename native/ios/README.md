# Spike de iOS — RutaKids (app nativa + Godot)

> **Hay dos apps en este proyecto de Xcode.** `RutaKidsSpike/` es la prueba técnica del puente (pasos de abajo).
> `RutaKids/` es la app real con el menú nativo: ver la sección "La app RutaKids" al final.
> Los dos targets se compilan igual (sección 3); en Xcode se elige cuál correr en el selector de arriba.

Esta carpeta es la mitad de iOS del spike de `docs/arquitectura.md` (sección 6). La mitad de Android ya pasó en un Samsung Galaxy A15 (`native/android/`). Aquí se prueba lo mismo en un iPhone o iPad **real**:

1. Godot arranca dentro de una app de SwiftUI y avisa `engine_ready`.
2. El menú nativo abre un nivel y recibe el resultado (`level_finished`, `level_exited`).
3. Abrir y cerrar el nivel 10 veces sin cierres y sin que la memoria siga subiendo.
4. Medir: tiempo hasta ver el menú, tiempo hasta `engine_ready`, memoria y tamaño de la app.

Si en 2 días de trabajo no funciona, la regla del documento (H13) es descartar la arquitectura híbrida.

---

## 1. Pasar el proyecto a la Mac

El repositorio está en GitHub: https://github.com/upsaac-obs/reto_tec_juego (pedir acceso de escritura a quien administre `upsaac-obs`). En la Mac:

```bash
git clone https://github.com/upsaac-obs/reto_tec_juego.git rutakids
cd rutakids
git switch -c feature/spike-ios origin/feature/modo-peque   # trae el kit de iOS y los niveles 0 a 3
```

Para subir los resultados: `git push -u origin feature/spike-ios`. GitHub pide usuario y un *personal access token* (no la contraseña), con permiso *Contents: Read and write* en el repositorio.

---

## 2. Preparar la Mac (una sola vez)

1. **Xcode** actualizado desde la App Store, con las *Command Line Tools* (`xcode-select --install`).
2. **Homebrew** (https://brew.sh) y **XcodeGen**: `brew install xcodegen`.
3. **Godot 4.7.2** (la misma versión del proyecto y de Android): bajar `Godot_v4.7.2-stable_macos.universal.zip` de https://github.com/godotengine/godot/releases/tag/4.7.2-stable y moverlo a Aplicaciones.
4. Las **plantillas de exportación 4.7.2**: abrir Godot → Editor → Administrar plantillas de exportación → Descargar e instalar.
5. Una **cuenta de Apple** iniciada en Xcode (Settings → Accounts). Con un Apple ID gratuito alcanza para instalar en un iPhone propio (la app dura 7 días).
6. En el iPhone: Ajustes → Privacidad y seguridad → **Modo de desarrollador** activado.

---

## 3. Compilar y correr

```bash
cd native/ios
GODOT=/Applications/Godot.app/Contents/MacOS/Godot ./export_pck.sh   # crea main.pck (en RutaKids/ y en RutaKidsSpike/)
xcodegen generate                                                     # crea RutaKids.xcodeproj (con las dos apps)
open RutaKids.xcodeproj
```

En Xcode:

1. Esperar a que baje el paquete **SwiftGodotKit** (rama `swiftgodotkit-4.7`; descarga también `libgodot-ios`, tarda la primera vez).
2. Target RutaKidsSpike (o RutaKids, la app real) → *Signing & Capabilities* → elegir el **Team** (la cuenta de Apple).
3. Conectar el iPhone por cable, elegirlo arriba como destino y presionar ▶︎.

> El simulador sirve para revisar que compile, pero **las mediciones solo cuentan en un iPhone o iPad real** (H3).

---

## 4. Qué probar y qué anotar

| Prueba | Cómo | Se anota |
|---|---|---|
| Arranque | Abrir la app desde el ícono (con la app cerrada) | Tiempo hasta ver el menú y el "Godot listo en … ms" que muestra la pantalla |
| Nivel 99 | Tocar "Nivel 99", luego Hacer una falta, Terminar y Continuar en la tarjeta | Que lleguen `level_started`, `level_finished` (con estrellas y faltas) y `level_exited`; que el menú muestre las estrellas |
| Niveles 0, 1 y 2 | Jugarlos completos | Que se vean bien, se manejen y den estrellas |
| Segundo plano | Con un nivel abierto, salir al inicio y regresar | Que el nivel quede en pausa y siga al regresar |
| 10 ciclos | Botón "Abrir y cerrar 10 veces" | La lista "Memoria por ciclo (MB)" y que no se cierre |
| Tamaño | Ajustes → General → Almacenamiento del iPhone → RutaKids spike | Tamaño de la app |

Comparar con Android (Galaxy A15, build *debug*): menú en 1.9 s, `engine_ready` en 3.7 s, memoria 247 → 253 MB en 10 ciclos.

Los resultados van en `docs/arquitectura.md`, sección 6.

---

## 5. Usar Claude Code en la Mac

1. Instalar Claude Code en la Mac (https://claude.com/claude-code) e iniciar sesión.
2. Abrir una terminal en la carpeta del repositorio (`cd rutakids`) y correr `claude`.
3. Pegar este mensaje:

```text
Hola. Este repositorio es RutaKids, un juego de Godot para Fundación ADO. Estamos
probando una arquitectura híbrida: app nativa + Godot incrustado. La mitad de
Android ya funciona; tú vas a hacer la mitad de iOS en esta Mac.

Lee primero native/ios/CLAUDE.md (tus instrucciones), native/ios/README.md y
docs/arquitectura.md. Trabaja en la rama feature/spike-ios. Respóndeme en español.

Empieza revisando que la Mac tenga Xcode, XcodeGen y Godot 4.7.2, luego exporta
main.pck, genera el proyecto y haz que compile. Avísame antes de instalar algo o
de subir cambios a GitHub.
```

El agente de la Mac sigue `native/ios/CLAUDE.md`.

---

## La app RutaKids (menú nativo)

Carpeta `RutaKids/`. Es el menú de `whoisdiego/menuIOS` conectado al juego. Los dibujos están en
`ASSETS de menu de IOS/` (ahí también está la lista de lo que falta).

```text
RutaKids/
  App/RutaKidsApp.swift        arranque: Godot siempre vivo y el menú encima mientras no hay nivel
  Bridge/RutaBridge.swift      puente con Godot; solo manda comandos y avisa con closures
  Model/ProgressStore.swift    guardado en UserDefaults (estrellas, puntos, faltas, modo, kiosco)
  Model/AppModel.swift         une puente, guardado y pantallas (tutorial, Tutores, kiosco, segundo plano)
  Menu/                        Inicio, Niveles, Opciones, Edad, Tutores, Audio y colores
  Resources/es.lproj/          Localizable.strings (lo genera tools/gen_strings.py; no se edita a mano)
```

Cómo se usa:

- **Primera vez:** pide Peque o Grande (dos dibujos). Después, el primer Jugar abre el nivel 0 (tutorial)
  y al salir muestra la lista de niveles. El nivel 1 está abierto; cada nivel se abre con 1 estrella en el anterior.
- **Estrellas:** cada tarjeta muestra abajo las estrellas ganadas (llenas) y las que faltan (vacías).
- **Tutores:** mantener presionado **Opciones 3 segundos** (en el menú) o el **engrane 3 segundos** (dentro de un nivel).
  Ahí se ven las estrellas y faltas por nivel, se cambia el modo, se activa el kiosco y se borra el progreso.
- **Kiosco:** todos los niveles abiertos, no se guarda nada y a los 60 segundos sin tocar se vuelve al inicio.
  Se desactiva en Tutores (mantener Opciones 3 segundos).
- **Segundo plano:** al salir de la app el nivel se pausa y, al volver, sigue.
- **Textos:** salen de `i18n/textos.csv`. Después de cambiarlo, corre `python tools/gen_strings.py`.

### Acceso Guiado en el iPad (kiosco)

El bloqueo de pantalla lo activa el personal en el iPad; la app no puede hacerlo sola.

1. Ajustes → Accesibilidad → **Acceso guiado** → activarlo y poner un código.
2. Abrir RutaKids. Presionar tres veces el botón lateral (iPad con Face ID) o el botón de inicio.
3. Tocar **Comenzar** (arriba a la derecha). Ya no se puede salir de la app sin el código.
4. Para terminar: presionar tres veces el mismo botón, poner el código y tocar **Terminar**.
5. Dentro de RutaKids, activar el **modo kiosco** en Tutores antes de dejar el iPad.

### Pendiente en la Mac

Este código se escribió en Linux **sin poder compilarlo** (igual que el spike). Lo primero es compilar el target
`RutaKids` y corregir lo que diga Xcode; después, probar en un iPhone o iPad real el recorrido completo:
edad → tutorial → niveles → estrellas guardadas → Tutores → kiosco → segundo plano.

