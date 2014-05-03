#!/bin/bash

# Variables que ya tendrian que estar seteadas
#LOGSIZE=22
#LOGDIR="/home/alumnos/Desktop"
#LOGEXT='dat'
#

if [ "$LOGEXT" == "" ]
	then
		LOGEXT="log"
fi

if [ $# -lt 2 -o $# -gt 3 ]
then 
echo "Cantidad de parámetros inválida"
else 


When=`date`
Who=`whoami`
Where=$1
if [ $# -eq 3 ]
then
	if [ $3 == 'INFO' -o $3 == 'WAR' -o $3 == 'ERR' ] 
	then
		What=$3
	else
		What='INFO'
	fi


else 
What='INFO'
fi
Why=$2

#Armo la linea a imprimir en el log
Tab='        '
Linea="[$When] $Tab [$Who] $Tab [$Where] $Tab [$What] $Tab [$Why]"

#verifico la existencia del archivo de log

ArchLog="$LOGDIR/$Where.$LOGEXT"

if [ -f "$ArchLog" ]
then
	NumLineas=`wc -l "$ArchLog" | cut -f1 -d' '`   #Lineas actuales
	NumBytes=`wc -c "$ArchLog" | cut -f1 -d' '` 			#Bytes actuales
	LOGBYTES=`expr $LOGSIZE \* 1024`	#Bytes permitidos

	#echo "NumLineas: $NumLineas."
	#echo "NumBytes: $NumBytes."
	#echo "LOGBYTES: $LOGBYTES."

	if [ "$NumBytes" -ge "$LOGBYTES" ] 
	then
		i=1	
		while [ $NumLineas -gt 50 ]
		do
			sed -i '1d' "$ArchLog"
			i=`expr $i + 1`
			NumLineas=`wc -l "$ArchLog" | cut -f1 -d' '`	
		done
	echo "Log exedido para poder controlar que se está realizando este trabajo">>"$ArchLog"
	fi
	#Concateno mi linea
	echo $Linea>>"$ArchLog"
else
	echo $Linea>"$ArchLog"
fi

fi
