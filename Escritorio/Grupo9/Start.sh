#!/bin/bash
# Comando: Start
# Descripcion: Dispara un proceso
# Parametros:
#	$1: Nombre del proceso a disparar
# Codigos de salida:
#	0: Salida exitosa
# 	1: La cantidad de parametros es distinta a 1
#	2: La inicializacion de ambiente no fue realidaza anteriormente
#	3: El proceso ya se encontraba corriendo

# Chequeo que la cantidad de parametros sea la correcta
if [ $# -ne 1 ]; then
	echo "Se ha llamado a Start con una cantidad de parametros distinta a 1"
#	./Logging.sh "Start" "Se ha llamado a Start con una cantidad de parametros distinta a 1" "ERR"
	exit 1
fi

# Chequeo que el ambiente haya sido inicializado
if [ -z "$INIT" ] || [ $INIT -ne 1 ]; then
      echo "La inicialización de ambiente no fue realizada al momento de utilizar el comando Start"
#	./Logging.sh "Start" "La inicialización de ambiente no fue realizada al momento de utilizar el comando Start" "ERR"
      exit 2
fi

COMANDO=$1

# Obtengo el PID del proceso
PID=$(./GetPID.sh "$COMANDO")

#Si el PID esta vacio significa que el proceso no esta corriendo
if [ -z "$PID" ]; then
	./$COMANDO &
	echo "Se disparo el proceso $COMANDO"
#	./Logging.sh "Start" "Se disparo el proceso $COMANDO" "INFO"
	exit 0
else
	echo "El proceso $COMANDO ya se encontraba corriendo"
#	./Logging.sh "Start" "El proceso $COMANDO ya se encontraba corriendo" "WAR"
	exit 3
fi

