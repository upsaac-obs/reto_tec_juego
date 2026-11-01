# RutaKids — app de Android

App nativa (Kotlin + Jetpack Compose) con Godot 4.7.2 adentro (`godot-lib` + plugin `RutaBridge`).
El contrato del puente está en `docs/arquitectura.md`, secciones 3 a 5.

## Requisitos

- Android SDK con `sdk.dir` en `local.properties` (no va en git) y el NDK `30.0.16248370`.
- Godot 4.7.2 en el `PATH` (lo usa `sync_godot.sh`) con las plantillas de exportación instaladas.

## Build de prueba

```sh
./sync_godot.sh                                   # exporta el proyecto de Godot a app/src/main/assets/
./gradlew assembleDebug -Pabis=arm64-v8a          # un solo celular, más rápido
./gradlew assembleDebug -Pabis=x86_64             # emulador
```

Sin `-Pabis` se compila para `arm64-v8a` y `armeabi-v7a` (celulares nuevos y viejos).

## Release

### 1. Crear la llave (una sola vez)

La llave **nunca** se sube a git (`keystore.properties`, `*.jks` y `*.keystore` están en `.gitignore`).
Si se pierde, no se puede actualizar la app ya instalada: guarda una copia y las contraseñas en un lugar seguro de la fundación.

```sh
keytool -genkeypair -v -keystore rutakids-release.jks -alias rutakids \
        -keyalg RSA -keysize 4096 -validity 10000
cp keystore.properties.example keystore.properties   # y llena las contraseñas
```

Si falta `keystore.properties`, Gradle avisa con un `AVISO` y firma el release con la llave de depuración
(sirve para medir y probar, **no** para entregar).

### 2. Compilar

```sh
./sync_godot.sh
./gradlew assembleRelease
# APK: app/build/outputs/apk/release/app-release.apk
```

Tamaño esperado (medido el 14 oct, `docs/arquitectura.md`): ~150 MB con arm64 + armv7 y ~78 MB solo arm64.
Casi todo es `libgodot_android.so` (71 MB por arquitectura, ya sin símbolos). Para Google Play conviene
`./gradlew bundleRelease` (cada celular baja solo su arquitectura).

### 3. Revisar antes de entregar

La app **no debe pedir INTERNET** ni ningún otro permiso (REQ-5). Revisa el APK final:

```sh
AAPT2=$(ls -d "$ANDROID_HOME"/build-tools/*/ | tail -1)aapt2
$AAPT2 dump permissions app/build/outputs/apk/release/app-release.apk
$AAPT2 dump badging app/build/outputs/apk/release/app-release.apk | grep -E "package|native-code|application-label:"
```

Lo único que debe salir es `org.fundacionado.rutakids.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`
(lo agrega AndroidX, es interno de la app). Si aparece `android.permission.INTERNET`, no se entrega.

Comprueba también la firma: `$(ls -d "$ANDROID_HOME"/build-tools/*/ | tail -1)apksigner verify --print-certs app/build/outputs/apk/release/app-release.apk`
(no debe decir `CN=Android Debug`).

## Kiosco

- 60 s sin tocar en los menús → Inicio (`KIOSK_IDLE_TIMEOUT_MS` en `ui/Kiosk.kt`). Dentro del nivel cuenta Godot
  y manda `inactivity_timeout`; la app cierra el nivel y vuelve a Inicio.
- En kiosco no hay Salir y Atrás no cierra el nivel ni la app.
- Al activar el kiosco en Tutores, Android pregunta si se fija la pantalla (screen pinning). En algunos
  celulares antes hay que encender *Ajustes → Seguridad → Fijar apps*. Para soltarla:
  desactivar el kiosco en Tutores, o el gesto del sistema (Atrás + Recientes).
