import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "org.fundacionado.rutakids"
    // Necesario para quitar los símbolos de depuración de libgodot_android.so en release.
    ndkVersion = "30.0.16248370"
    compileSdk { version = release(37) { minorApiLevel = 2 } }

    defaultConfig {
        applicationId = "org.fundacionado.rutakids"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        // Igual que el export de Godot: celulares viejos (armv7) y nuevos (arm64).
        // x86_64 (emulador) solo si se pide: -Pabis=x86_64. Para instalar más
        // rápido en un solo celular: ./gradlew assembleDebug -Pabis=arm64-v8a
        val abis = (findProperty("abis") as String?)?.split(",")
            ?: listOf("arm64-v8a", "armeabi-v7a")
        ndk { abiFilters += abis }
    }

    // La llave de release NO va en git: se lee de keystore.properties (ver README.md).
    val keystoreFile = rootProject.file("keystore.properties")
    val releaseKeys = Properties().apply { if (keystoreFile.exists()) keystoreFile.inputStream().use { load(it) } }
    signingConfigs {
        if (keystoreFile.exists()) {
            create("release") {
                storeFile = rootProject.file(releaseKeys.getProperty("storeFile"))
                storePassword = releaseKeys.getProperty("storePassword")
                keyAlias = releaseKeys.getProperty("keyAlias")
                keyPassword = releaseKeys.getProperty("keyPassword")
            }
        }
    }

    buildFeatures { compose = true }

    buildTypes {
        release {
            signingConfig = if (keystoreFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("AVISO: falta native/android/keystore.properties; el release se firma con la llave de DEPURACIÓN (no sirve para publicar).")
                signingConfigs.getByName("debug")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Los .pck y archivos de Godot ya vienen comprimidos o no ganan nada.
    androidResources {
        noCompress += listOf("pck", "scn", "res", "ctex", "import")
        // Igual que la plantilla de Godot: sin esto Android deja fuera la carpeta
        // .godot/ (empieza con punto) y Godot no encuentra sus escenas exportadas.
        ignoreAssetsPattern = "!.svn:!.git:!.gitignore:!.ds_store:!*.scc:<dir>_*:!CVS:!thumbs.db:!picasa.ini:!*~"
    }
}

dependencies {
    // Debe ser exactamente la misma versión que el editor de Godot (H9).
    implementation("org.godotengine:godot:4.7.2.stable")
    implementation("androidx.fragment:fragment-ktx:1.9.1")
    implementation("androidx.activity:activity-compose:1.13.0")
    implementation(platform("androidx.compose:compose-bom:2026.09.00"))
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    // Menú: navegación entre pantallas, ViewModel del puente y guardado (plan, sección 5).
    implementation("androidx.navigation:navigation-compose:2.9.5")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.9.4")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.9.4")
    implementation("androidx.datastore:datastore-preferences:1.1.7")
}
