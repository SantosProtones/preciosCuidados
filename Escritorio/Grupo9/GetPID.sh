#!/bin/bash
# Funcion: GetPID
# Descripcion: Devuelve el PID de un proceso
# Parametros:
#	$1: Nombre del proceso cuyo PID queremos obtener
# Codigos de salida:
#	0: Salida exitosa
#	1: La cantidad de parametros es distinta a 1
#	2: No se pudo encontrar el PID

# Chequeo que la cantidad de parametros sea la correcta
if [ $# -ne 1 ]; then
	echo "Se ha llamado a GetPID con una cantidad de parametros distinta a 1"
	exit 1
fi

COMANDO=$1
PID=$(ps -e | grep "$COMANDO" | awk '{ print $1 }')

if [ -z $PID ]; then
	exit 2
else
	echo "$PID"
	exit 0
fi
