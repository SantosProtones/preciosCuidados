#!/bin/bash

#----------------------------------------------------------------------------------------------------------------------
#
# Path Locales
#
#----------------------------------------------------------------------------------------------------------------------

#NOVEDIR="../arribos"
#ACEPDIR="../aceptados"
#RECHDIR="../rechazados"
#MAEDIR="../mae"
PRECDIR="$MAEDIR/precios"
asociados="$MAEDIR/asociados.mae"

#----------------------------------------------------------------------------------------------------------------------
#
# Funciones Locales
#
#----------------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------------------------
#
# Inicio del Comando Listener
#
#----------------------------------------------------------------------------------------------------------------------

T_SLEEP=30 # Tiempo de espera entre cada vuelta (en seg)
loop=0 

#----------------------------------------------------------------------------------------------------------------------
#
# Se verifica que el sistema este inicializado
#
#----------------------------------------------------------------------------------------------------------------------

INICIALIZADO=$INIT

if [ -z $INICIALIZADO ]; then
	echo "La inicialización del ambiente no fue realizada al momento de ejecutar el comando Listener"
else
# 	pid_listener=$(ps -e | grep 'Listener.sh$' | awk '{ print $1 }')
    pid_listener=`./GetPID.sh "Listener.sh"`
	for ((  ; 1 == 1 ; )); do
	
# 1. Grabar en el Log el nro de ciclo.
		loop=`expr $loop+1 | bc`
		mensaje="PID Listener.sh: $pid_listener Ciclo $loop Hora: $(date +%T)"
		echo $BINDIR 	
		`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "INFO"`

# 2. Chequear si hay archivos en el directorio $NOVEDIR
		cantidad_novedades=`ls "$NOVEDIR/" -F | grep -e "[^/]$" | wc -l`
		if [ $cantidad_novedades -gt 0 ];then

# Se obtienen los archivos del directorio $NOVEDIR para procesar por el comando Listener
			novedades=`ls "$NOVEDIR/" -1 -F | grep -e "[^/]$"`	
			SAVEIFS=$IFS
			IFS=$(echo -en "\n\b")

			for novedad in $novedades
				do
					file "$NOVEDIR/$novedad" | grep -e "text" > /dev/null
					if [ $? -ne 0 ]; then
						file "$NOVEDIR/$novedad" | grep -e "empty" > /dev/null
						if [ $? -ne 0 ]; then
							mensaje="Archivo $novedad rechazado. Tipo de archivo Invalido"
							`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "ERR"`
							`$BINDIR/Mover.sh "$NOVEDIR/$novedad" "$RECHDIR" "Listener.sh"`
#   						echo $novedad "no es un archivo valido, mover archivo a RECHDIR. Tipo de archivo Invalido"
						continue
						fi
					fi

# 3. Validación del nombre del archivo

# 3.b Archivos de listas de precios

# 3.b.a Validación del formato del registro			
					es_lista_precios=`echo $novedad | grep -e "^[^-^ ]*-[0-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9].*$" | wc -l`
	
					if [ $es_lista_precios -eq 1 ];then

# 3.b.b Validación de la fecha
						fecha_novedad=`echo $novedad | cut -d'-' -f2 | cut -d'.' -f1`
						fecha_valida=`date -d $fecha_novedad +%Y%m%d 2> /dev/null`
				
						if [ -z $fecha_valida ]; then	
							fecha_valida='00000000'
						fi					
				
						if [ $fecha_novedad -eq $fecha_valida ]; then
							if [ $fecha_novedad -gt '20140101' ]; then
								mensaje="Archivo $novedad aceptado. Es lista de Precios"
								`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "INFO"`
								`$BINDIR/Mover.sh "$NOVEDIR/$novedad" "$MAEDIR/precios" "Listener.sh"`	
#								echo $novedad "es lista de precios, mover archivo a MAEDIR/precios"
								continue
							else									
								mensaje="Archivo $novedad rechazado. Fecha invalida"
								`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "ERR"`
								`$BINDIR/Mover.sh "$NOVEDIR/$novedad" "$RECHDIR" "Listener.sh"`								
								continue
							fi
						else
							mensaje="Archivo $novedad rechazado. Fecha invalida"
							`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "ERR"`
							`$BINDIR/Mover.sh "$NOVEDIR/$novedad" "$RECHDIR" "Listener.sh"`								
							continue
						fi
					fi

# 3.a Archivos de listas de compras			

# 3.a.a Validación del formato del registro
					es_lista_compras=`echo $novedad | grep -e "^[^.]*.[^-^ ]*$" | wc -l`
			 					
					if [ $es_lista_compras -eq 1 ];then

# 3.a.b Validación en archivo maestro de asociados
						asociado=`echo $novedad | cut -d'.' -f1`
						existe_asociado=`cat $asociados | grep -e "^[^;]*;[^;]*;$asociado;[^;];*[^;]*$" | wc -l`

# 3.a.c La novedad es lista de compras
						if [ $existe_asociado -eq 1 ];then
							
							mensaje="Archivo $novedad aceptado. Es lista de Compras"
							`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "INFO"`
							`$BINDIR/Mover.sh "$NOVEDIR/$novedad" "$ACEPDIR" "Listener.sh"`
#							echo $novedad "es lista de compras, mover archivo a ACEPDIR"
							continue
						else
	
							mensaje="Archivo $novedad rechazado. Asociado inexistente"
							`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "ERR"`
							`$BINDIR/Mover.sh "$NOVEDIR/$novedad" "$RECHDIR" "Listener.sh"`		
#							echo $novedad "no es un archivo valido, mover archivo a RECHDIR. Asociado inexistente"
							continue 					
						fi
					fi
 					mensaje="Archivo $novedad rechazado. Nombre del archivo con formato invalido"
					`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "ERR"`
					`$BINDIR/Mover.sh "$NOVEDIR/$novedad" "$RECHDIR" "Listener.sh"`				
#					echo $novedad "no es un archivo valido, mover archivo a RECHDIR. Nombre del archivo con formato invalido"	
				done

			IFS=$SAVEIFS
		else
			mensaje="No hay archivos en la carpeta arribos"
			`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "WAR"`				
#			echo "No hay archivos en la carpeta arribos"
		fi
		
# 7. Invocación MasterList

# 7.a. Chequear si hay archivos en el directorio $PRECDIR - Lista de precios
		cantidad_lista_precios=`ls "$MAEDIR/precios/" -1 -F | grep -e "[^/]$" | wc -l`			
		if [ $cantidad_lista_precios -gt 0 ];then

# 7.b. PID MasterList
#			pid_masterlist=`ps -e | grep -e 'MasterList.sh$' | awk '{print $1}'`
			pid_masterlist=`./GetPID.sh "Masterlist.sh"`			
			if [ -z "$pid_masterlist" ]; then
#				echo "Ejecutar ./MasterList.sh"
				`$BINDIR/Start.sh Masterlist.sh`
#				pid_masterlist=`ps -e | grep -e 'Masterlist.sh$' | awk '{print $1}'`
				pid_masterlist=`./GetPID.sh "Masterlist.sh"`				
				mensaje="PID De MasterList Lanzado: $pid_masterlist"
				`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "INFO"`
			else
				mensaje="El proceso MasterList.sh ya está ejecutándose"
				`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "WAR"`
			fi

		fi

# 8. Invocacion Rating

# 8.a. Chequear si hay archivos en el directorio $ACEPDIR - Lista de Compras
		cantidad_lista_compras=`ls "$ACEPDIR/" -1 -F | grep -e "[^/]$" | wc -l`			
		if [ $cantidad_lista_compras -gt 0 ];then

# 7.b. PID MasterList
#			pid_rating=`ps -e | grep -e 'Rating.sh$' | awk '{print $1}'`
			pid_rating=`./GetPID.sh "Rating.sh"`			
			if [ -z "$pid_rating" ]; then
#				echo "Ejecutar ./Rating.sh"
#				`$BINDIR/Start.sh Rating.sh $ACEPDIR $MAEDIR $INFODIR $RECHDIR`
				`$BINDIR/Rating.sh $ACEPDIR $MAEDIR $INFODIR $RECHDIR`
#				pid_rating=`ps -e | grep -e 'Rating.sh$' | awk '{print $1}'`
				pid_rating=`./GetPID.sh "Rating.sh"`
				mensaje="PID De Rating Lanzado: $pid_Rating"
				`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "INFO"`
			else
				mensaje="El proceso Rating.sh ya está ejecutándose"
				`$BINDIR/Logging.sh "Listener.sh" "$mensaje" "WAR"`
			fi

		fi

		sleep $T_SLEEP # duermo T_SLEEP segundos
	done
fi

