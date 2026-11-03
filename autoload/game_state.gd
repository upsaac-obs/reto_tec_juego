extends Node
## Estado global de la partida: modo de edad, kiosco y nivel actual.
## También guarda la paleta de colores del juego (la misma que assets/ui/theme.tres).

# Paleta oficial de ADO
const COLOR_ADO_RED := Color("#DD2835")
const COLOR_DARK_PURPLE := Color("#3F1B4E")
const COLOR_GOLD := Color("#FFC700")
const COLOR_WHITE := Color("#FFFFFF")
const COLOR_SKY_TOP := Color("#4A235A")
const COLOR_SKY_MID := Color("#9C4B79")
const COLOR_SKY_HORIZON := Color("#E86F56")
const COLOR_ASPHALT := Color("#534A5E")

# Colores extra (propuesta)
const COLOR_OUTLINE := Color("#1E0F26")
const COLOR_SHADOW := Color("#2A2230")
## Banqueta de cantera (plan visual). El lila de antes queda como acento (COLOR_LILAC).
const COLOR_SIDEWALK := Color("#C9BDB4")
const COLOR_LILAC := Color("#B8A6CC")
const COLOR_WARM_LIGHT := Color("#F8C99B")
const COLOR_GREEN := Color("#3FA34D")
const COLOR_DARK_GREEN := Color("#2B6B3F")
const COLOR_GLASS := Color("#7FC8E8")
const COLOR_SKIN_LIGHT := Color("#F2C29B")
const COLOR_SKIN_MEDIUM := Color("#C68B59")
const COLOR_SKIN_DARK := Color("#8A5A3B")
# Extra del plan visual (docs/plan_visual.md): ciudad poblana poco saturada.
const COLOR_SIDEWALK_JOINT := Color("#968A85")
const COLOR_GRASS_SOFT := Color("#5E9A5A")
const COLOR_BRICK := Color("#B5523B")
const COLOR_TALAVERA := Color("#2E4DA0")
const COLOR_OCHRE := Color("#E3A548")
const COLOR_MEXICAN_PINK := Color("#E0457B")
const COLOR_LEAF_LIGHT := Color("#7CC56B")

## Conversión para los letreros de velocidad: 60 km/h = 240 px/s (máximo del auto).
const PX_PER_KMH := 4.0

const MODE_PEQUE := "peque"
const MODE_GRANDE := "grande"

## "peque" (4 a 7 años: el auto avanza solo) o "grande" (8 a 13 años: dos
## pedales). El nativo lo manda en start_level. Con F6 en el editor se usa este
## valor: cámbialo aquí para probar un nivel en modo peque.
var mode: String = MODE_GRANDE
## En kiosco todo está abierto y no se guarda nada.
var kiosk: bool = false
## Datos del nivel abierto (los pone BridgeClient). null en idle.
var level: LevelData
