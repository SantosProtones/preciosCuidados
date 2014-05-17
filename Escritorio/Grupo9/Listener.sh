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

T_SLEEP=10 # Tiempo de espera entre cada vuelta (en seg)
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
    pid_masterlist="NoEstaCorriendo"
    pid_rating="NoEstaCorriendo"
    
	for ((  ; 1 == 1 ; )); do
	
# 1. Grabar en el Log el nro de ciclo.
		loop=`expr $loop+1 | bc`
		mensaje="PID Listener: $pid_listener Ciclo $loop Hora: $(date +%T)" 	
		`"$BINDIR/Logging.sh" "Listener" "$mensaje" "INFO"`

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
							`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`
							`"$BINDIR/Mover.sh" "$NOVEDIR/$novedad" "$RECHDIR" "Listener"`
#   						echo $novedad "no es un archivo valido, mover archivo a RECHDIR. Tipo de archivo Invalido"
						continue
						fi
					fi

# 3. Validación del nombre del archivo

# 3.b Archivos de listas de precios

# 3.b.a Validación del formato del registro			
					es_lista_precios=`echo $novedad | grep -e "^[^-^ ]*-[0-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9]\..*$" | wc -l`
	
					if [ $es_lista_precios -eq 1 ];then

# 3.b.b Validación de la fecha
						fecha_novedad=`echo $novedad | cut -d'-' -f2 | cut -d'.' -f1`
						fecha_valida=`date -d $fecha_novedad +%Y%m%d 2> /dev/null`
						fecha_actual=`date +%Y%m%d 2> /dev/null`
				
						if [ -z $fecha_valida ]; then	
							fecha_valida='00000000'
						fi					
				
						if [ $fecha_novedad -eq $fecha_valida ]; then
							if [ $fecha_novedad -gt '20140101' ]; then
								if [ $fecha_novedad -le $fecha_actual ]; then
# 3.b.c Validación de usuario colaborador
									asociado=`echo $novedad | cut -d'.' -f2`						
									existe_asociado=`cat $asociados | grep -e "^[^;]*;[^;]*;$asociado;[^;]*;*[^;]*$" | wc -l`	
	
									if [ $existe_asociado -gt 0 ]; then
										es_colaborador=`cat $asociados | grep -e "^[^;]*;[^;]*;$asociado;1;*[^;]*$" | wc -l`
										if [ $es_colaborador -gt 0 ]; then	
											mensaje="Archivo $novedad aceptado. Es lista de Precios"
											`"$BINDIR/Logging.sh" "Listener" "$mensaje" "INFO"`
											`"$BINDIR/Mover.sh" "$NOVEDIR/$novedad" "$MAEDIR/precios" "Listener"`	
											continue
										else
											mensaje="Archivo $novedad rechazado. Usuario no es colaborador"
											`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`
											`"$BINDIR/Mover.sh" "$NOVEDIR/$novedad" "$RECHDIR" "Listener"`
											continue
										fi
									else
										mensaje="Archivo $novedad rechazado. Usuario inexistente"
										`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`
										`"$BINDIR/Mover.sh" "$NOVEDIR/$novedad" "$RECHDIR" "Listener"`
										continue
									fi
								else
									mensaje="Archivo $novedad rechazado. Fecha invalida"
									`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`
									`"$BINDIR/Mover.sh" "$NOVEDIR/$novedad" "$RECHDIR" "Listener"`
									continue
								fi				
								
							else									
								mensaje="Archivo $novedad rechazado. Fecha invalida"
								`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`
								`"$BINDIR/Mover.sh" "$NOVEDIR/$novedad" "$RECHDIR" "Listener"`								
								continue
							fi
						else
							mensaje="Archivo $novedad rechazado. Fecha invalida"
							`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`
							`"$BINDIR/Mover.sh" "$NOVEDIR/$novedad" "$RECHDIR" "Listener"`								
							continue
						fi
					fi

# 3.a Archivos de listas de compras			

# 3.a.a Validación del formato del registro
					es_lista_compras=`echo $novedad | grep -e "^[^.]*\.[^-^ ]*$" | wc -l`
			 					
					if [ $es_lista_compras -eq 1 ];then

# 3.a.b Validación en archivo maestro de asociados
						asociado=`echo $novedad | cut -d'.' -f1`
						existe_asociado=`cat $asociados | grep -e "^[^;]*;[^;]*;$asociado;[^;];*[^;]*$" | wc -l`

# 3.a.c La novedad es lista de compras
						if [ $existe_asociado -eq 1 ];then
							
							mensaje="Archivo $novedad aceptado. Es lista de Compras"
							`"$BINDIR/Logging.sh" "Listener" "$mensaje" "INFO"`
							`"$BINDIR/Mover.sh" "$NOVEDIR/$novedad" "$ACEPDIR" "Listener"`
#							echo $novedad "es lista de compras, mover archivo a ACEPDIR"
							continue
						else
	
							mensaje="Archivo $novedad rechazado. Asociado inexistente"
							`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`
							`"$BINDIR/Mover.sh" "$NOVEDIR/$novedad" "$RECHDIR" "Listener"`		
#							echo $novedad "no es un archivo valido, mover archivo a RECHDIR. Asociado inexistente"
							continue 					
						fi
					fi
 					mensaje="Archivo $novedad rechazado. Nombre del archivo con formato invalido"
					`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`
					`"$BINDIR/Mover.sh" "$NOVEDIR/$novedad" "$RECHDIR" "Listener"`				
#					echo $novedad "no es un archivo valido, mover archivo a RECHDIR. Nombre del archivo con formato invalido"	
				done

			IFS=$SAVEIFS
		else
			mensaje="No hay archivos en la carpeta arribos"
			`"$BINDIR/Logging.sh" "Listener" "$mensaje" "WAR"`				
#			echo "No hay archivos en la carpeta arribos"
		fi
		
# 7. Invocación MasterList
# 7. Obtengo los PID de Masterlist y Rating
#		pid_masterlist=`./GetPID.sh "Masterlist.sh"`
#		pid_rating=`./GetPID.sh "Rating.sh"`
 		#pid_masterlist=`ps -e | grep -e 'Masterlist.sh$' | awk '{ print $1 }'`
		#pid_rating=`ps -e | grep -e 'Rating.sh$' | awk '{ print $1 }'`
		 flagR=`ps -o "pid,args" | grep -e $pid_rating | grep -cv grep`
		 flagM=`ps -o "pid,args" | grep -e $pid_masterlist | grep -cv grep`
		  
# 7.a. Chequear si hay archivos en el directorio $PRECDIR - Lista de precios
		cantidad_lista_precios=`ls "$MAEDIR/precios/" -1 -F | grep -e "[^/]$" | wc -l`			
		if [ $cantidad_lista_precios -gt 0 ];then

# 7.b. Chequea que ningun proceso este en ejecución 
			if [ $flagM -eq 0 ]; then 
				if [ $flagR -eq 0 ]; then
					
					`"$BINDIR/Masterlist.sh"` &
#					pid_masterlist=`./GetPID.sh "Masterlist.sh"`
#					pid_masterlist=`ps -e | grep -e 'Masterlist.sh$' | awk '{ print $1 }'`
					pid_masterlist=$!
					mensaje="PID De MasterList Lanzado: $pid_masterlist"
					`"$BINDIR/Logging.sh" "Listener" "$mensaje" "INFO"`
				else
					mensaje="Masterlist.sh no se ejecutó. El proceso Rating.sh se esta ejecutando"										
					`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`
				fi
			else
				mensaje="El proceso MasterList.sh ya está ejecutándose"
				`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`
			fi

		fi

# 8. Invocacion Rating
# 8. Obtengo los PID de Masterlist y Rating				
#		pid_masterlist=`./GetPID.sh "Masterlist.sh"`
#		pid_rating=`./GetPID.sh "Rating.sh"`
 		#pid_masterlist=`ps -e | grep -e 'Masterlist.sh$' | awk '{ print $1 }'`
		#pid_rating=`ps -e | grep -e 'Rating.sh$' | awk '{ print $1 }'`
		
		flagR=`ps -o "pid,args" | grep -e $pid_rating | grep -cv grep`
		flagM=`ps -o "pid,args" | grep -e $pid_masterlist | grep -cv grep`

# 8.a. Chequear si hay archivos en el directorio $ACEPDIR - Lista de Compras
		cantidad_lista_compras=`ls "$ACEPDIR/" -1 -F | grep -e "[^/]$" | wc -l`			
		if [ $cantidad_lista_compras -gt 0 ];then

# 8.b. Chequea de que ningun proceso este en ejecución
			if [ $flagR -eq 0 ]; then
				if [ $flagM -eq 0 ]; then 
					`"$BINDIR/Rating.sh"` &
 					#pid_rating=`ps -e | grep -e 'Rating.sh$' | awk '{ print $1 }'`
 					pid_rating=$!
					mensaje="PID De Rating Lanzado: $pid_rating"
					`"$BINDIR/Logging.sh" "Listener" "$mensaje" "INFO"`
				else
					mensaje="Rating.sh no se ejecutó. El proceso Masterlist.sh se esta ejecutándo"
					`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`
				fi
			else
				mensaje="El proceso Rating.sh ya está ejecutándose"
				`"$BINDIR/Logging.sh" "Listener" "$mensaje" "ERR"`				
			fi									
		fi

		sleep $T_SLEEP # duermo T_SLEEP segundos
	done
fi

