#!/bin/bash
# Comando: Stop
# Descripcion: Detener un proceso
# Parametros:
#	$1: Nombre del proceso a detener
# Codigos de salida:
#	0: Salida exitosa
# 	1: La cantidad de parametros es distinta a 1
#	2: El proceso no estaba corriendo

# Chequeo que la cantidad de parametros sea la correcta
if [ $# -ne 1 ]; then
	echo "Se ha llamado a Stop con una cantidad de parametros distinta a 1"
#	./Logging.sh "Stop" "Se ha llamado a Stop con una cantidad de parametros distinta a 1" "ERR"
	exit 1
fi

COMANDO=$1

# Obtengo el PID del proceso
PID=$(./GetPID.sh "$COMANDO")

#Si el PID esta vacio significa que el proceso no esta corriendo
if [ -z "$PID" ]; then
	echo "El proceso $COMANDO no esta corriendo"
#	./Logging.sh "Stop" "El proceso $COMANDO no esta corriendo" "WAR"
	exit 2
else
	kill $PID
	echo "Se detuvo el proceso $COMANDO"
#	./Logging.sh "Stop" "Se detuvo el proceso $COMANDO" "INFO"
	exit 0
fi

