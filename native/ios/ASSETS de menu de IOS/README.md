# ASSETS de menu de IOS

Imágenes del menú de iOS (vienen de `whoisdiego/menuIOS`). Todo está dentro de `Assets.xcassets`,
que es el formato que Xcode necesita; la app las pide por nombre, p. ej. `Image("imagen_nl1")`.

## Lo que ya está

| Nombre | Dónde se usa |
| --- | --- |
| `bg_zona_vial` | Fondo de Inicio, Niveles, Opciones, Edad y Tutores |
| `icon_back` | Botón de regreso (Niveles y Tutores) |
| `imagen_nl1` … `imagen_nl8` | Tarjeta de cada nivel (el mismo número que el `level_id` del juego) |

## Lo que falta (mientras no estén, la app dibuja uno de reemplazo y no se rompe)

| Nombre | Qué es |
| --- | --- |
| `btn_jugar` | Botón Jugar completo (se ve a 200 × 200 pt) |
| `btn_opciones` | Botón Opciones completo (se ve a 56 pt de alto) |
| `age_peque`, `age_grande` | Dibujos de la pantalla de edad (se ven a 110 pt de alto) |
| `bg_music.mp3` | Música de fondo (va en la app, no en el catálogo de imágenes) |
| `tap.mp3` | Sonido de toque (igual) |

Para agregar una imagen: dentro de `Assets.xcassets` crea una carpeta `<nombre>.imageset` con la imagen y un
`Contents.json` (se puede copiar el de otra), o arrástrala al catálogo en Xcode.

> Ojo: `bg_zona_vial` trae un edificio con letrero "ADO" y un camión rojo. `CLAUDE.md` pide no usar el logo,
> el camión ni la terminal de ADO, y el equipo todavía tiene pendiente decidir si se puede usar el logo.
