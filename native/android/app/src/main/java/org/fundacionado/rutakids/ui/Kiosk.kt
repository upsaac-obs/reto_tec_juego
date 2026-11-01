package org.fundacionado.rutakids.ui

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.util.Log

/** Kiosco: segundos sin tocar en los menús antes de volver a Inicio (docs/sprint_15_28_oct.md, sección 5). */
const val KIOSK_IDLE_TIMEOUT_MS = 60_000L

/** Cada cuánto se revisa el tiempo sin tocar. */
const val KIOSK_IDLE_CHECK_MS = 1_000L

private const val TAG = "RutaKiosk"

/**
 * Fijar pantalla (screen pinning) al activar el kiosco. Sin dueño de dispositivo, Android
 * muestra su aviso para confirmar; para salir hace falta el gesto del sistema o desactivar
 * el kiosco en Tutores. Nunca debe tumbar la app, así que se atrapan los errores.
 */
fun Activity.setScreenPinned(pinned: Boolean) {
    runCatching {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val isPinned = am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        if (pinned && !isPinned) startLockTask()
        if (!pinned && isPinned) stopLockTask()
    }.onFailure { Log.w(TAG, "No se pudo ${if (pinned) "fijar" else "soltar"} la pantalla", it) }
}
