extends RefCounted
## Marca de versión que BridgeClient manda en engine_ready ({"build": BUILD}).
## tools/export_all.sh la reescribe con el commit al exportar y luego la deja
## otra vez así. En el repositorio y en el editor siempre dice "dev".

const BUILD := "dev"
