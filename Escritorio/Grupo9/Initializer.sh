#!/bin/bash


#
actual=`pwd`
export PATH="$PATH":"$actual"
grupo=${actual%/*}
CONFDIR="$grupo/conf"
#

#INIT=0 
#Esta variable indica si el ambiente ya se inicializo antes
#INIT = 0 -->No inicializado
#INIT = 1 -->Inicializado

ERRINST=0 
#En esta variable controlo los errores de instalacion encontrados
#ERRINST = 0 --> no hay errores
#ERRINST = 1 --> Hay errores que se ven en el log
#ERRINST = 2 --> Hay errores que involucran el mecanismo de logging. No se podran loguear




if [ ! -d "$CONFDIR" ]
then
	ERRINST=2 #Nunca es alcanzado por la ejecucion
	echo "No se encontro el directorio de configuracion. Revise su instalacion"
else
	if [ ! -r "$CONFDIR/Installer.conf" ]
	then 
		ERRINST=2 
		echo "No se encontro archivo de configuracion de la instalacion. Instale nuevamente"
	else
	#Setear todas las variables que no hayan sido seteadas antes (una sola vez por cada sesion)

		if [ -z "$GRUPO" ]
		then
			GRUPO=`cat "$CONFDIR/Installer.conf" | grep '^GRUPO=' | cut -f2 -d'='`
			
			if [ "$GRUPO" != "$grupo" ]
			then

				echo "La variable GRUPO no coincide con el directorio de la instalacion"
				echo "Ajuste el valor de GRUPO o el directorio de la instalacion para continuar"			
				#exit 1
				return

				fi
		fi	

		#CONFDIR=`cat "$CONFDIR/installer.conf" | grep '^CONFDIR=' | cut -f2 -d'='`

		if [ -z "$BINDIR" ]
		then
			BINDIR=$GRUPO/`cat "$CONFDIR/Installer.conf" | grep '^BINDIR=' | cut -f2 -d'='`
			#export BINDIR
		fi

		if [ -z "$MAEDIR" ]
		then
			MAEDIR=$GRUPO/`cat "$CONFDIR/Installer.conf" | grep '^MAEDIR=' | cut -f2 -d'='`
			#export MAEDIR
		fi

		if [ -z "$NOVEDIR" ]
		then
			NOVEDIR=$GRUPO/`cat "$CONFDIR/Installer.conf" | grep '^NOVEDIR=' | cut -f2 -d'='`
			#export NOVEDIR	
		fi
	
		if [ -z "$DATASIZE" ]
		then
			DATASIZE=`cat "$CONFDIR/Installer.conf" | grep '^DATASIZE=' | cut -f2 -d'='`
			#export DATASIZE	
		fi
		if [ -z "$ACEPDIR" ]
		then
			ACEPDIR=$GRUPO/`cat "$CONFDIR/Installer.conf" | grep '^ACEPDIR=' | cut -f2 -d'='`
			#export ACEPDIR		
		fi

		if [ -z "$RECHDIR" ]
		then
			RECHDIR=$GRUPO/`cat "$CONFDIR/Installer.conf" | grep '^RECHDIR=' | cut -f2 -d'='`
			#export RECHDIR	
		fi

		if [ -z "$INFODIR" ]
		then
			INFODIR=$GRUPO/`cat "$CONFDIR/Installer.conf" | grep '^INFODIR=' | cut -f2 -d'='`
			#export INFODIR	
		fi

		if [ -z "$LOGDIR" ]
		then
			LOGDIR=$GRUPO/`cat "$CONFDIR/Installer.conf" | grep '^LOGDIR=' | cut -f2 -d'='`
			#export LOGDIR
		fi
	
		if [ -z "$LOGEXT" ]
		then
			LOGEXT=`cat "$CONFDIR/Installer.conf" | grep '^LOGEXT=' | cut -f2 -d'='`
			#export LOGEXT	
		fi

		if [ -z "$LOGSIZE" ]
		then	
			LOGSIZE=`cat "$CONFDIR/Installer.conf" | grep '^LOGSIZE=' | cut -f2 -d'='`	
			#export LOGSIZE
		fi

		

		#export CONFDIR


		#-----------------------------------------------------
		#fin de seteo de variables desde el archivo de config
		#-----------------------------------------------------


		#Verifico que existan las carpetas. En algunas (anidado) miro que esten los maestros o los ejecutables
		#if [ ! -d "$GRUPO" ]
		#then 
		#	ERRINST=1
		#	./Logging.sh Initializer "No existe el directorio $GRUPO" ERR
		#fi

		#if [ ! -d $CONFDIR ]; then ./Logging.sh Initializer "No existe el directorio $CONFDIR" ERR; fi
		#Linea borrada porque esta tarea la hago arriba de todo



		#if [ ! -d "$LOGDIR" ]
		#then
		#	ERRINST=2
		#	#./Logging.sh Initializer "No existe el directorio $LOGDIR" ERR
		#fi



		if [ ! -d "$BINDIR"  -o ! -d "$LOGDIR" ]
		then
			ERRINST=2
			#./Logging.sh Initializer "No existe el directorio $BINDIR" ERR

		else
				#Verifico que se encuentren los comandos y se tenga permiso de ejecución

				#-----------
				if [ ! -f  "$BINDIR/Logging.sh" ]
				then
					ERRINST=2
				else
					
					if [ ! -x "$BINDIR/Logging.sh" ]
					then 
						chmod +x "$BINDIR/Logging.sh"	
					fi

					. ./Logging.sh Initializer "Comando Initializer Inicio de ejecución" INFO
				fi
				#-----------
				if [ ! -f  "$BINDIR/Listener.sh" ]
				then
					ERRINST=1
					. ./Logging.sh Initializer "No se encuentra script Listener" ERR
				elif [ ! -x "$BINDIR/Listener.sh" ]
				then 
					chmod +x "$BINDIR/Listener.sh"
					. ./Logging.sh Initializer "Se han otorgado permisos de ejecución sobre Listener.sh" INFO
				 fi

				#------------
				if [ ! -f  "$BINDIR/Masterlist.sh" ]
				then
					ERRINST=1
					. ./Logging.sh Initializer "No se encuentra script Masterlist" ERR

				elif [ ! -x "$BINDIR/Masterlist.sh" ]
				then
					chmod +x "$BINDIR/Masterlist.sh"
					. ./Logging.sh Initializer "Se han otorgado permisos de ejecución sobre Masterlist.sh" INFO

				fi
				#------------
				if [ ! -f "$BINDIR/Rating.sh" ]
				then
					ERRINST=1
					. ./Logging.sh Initializer "No se encuentra script Rating" ERR

				elif [ ! -x "$BINDIR/Rating.sh" ]
				then
					chmod +x "$BINDIR/Rating.sh"
					. ./Logging.sh Initializer "Se han otorgado permisos de ejecución sobre Rating.sh" INFO

				fi
				#--------------

				if [ ! -f  "$BINDIR/Reporting.pl" ]
				then
					ERRINST=1
					. ./Logging.sh Initializer "No se encuentra Reporting" ERR

				elif [  ! -x  "$BINDIR/Reporting.pl"  ]
				then
					chmod +x "$BINDIR/Reporting.pl"
					. ./Logging.sh Initializer "Se han otorgado permisos de ejecución sobre Reporting.pl" INFO

				fi
				#---------------
				if [ ! -f  "$BINDIR/Mover.sh" ]
				then
					ERRINST=1
					. ./Logging.sh Initializer "No se encuentra Mover" ERR
				elif [ ! -x  "$BINDIR/Mover.sh" ]
				then
					chmod +x "$BINDIR/Mover.sh"
					. ./Logging.sh Initializer "Se han otorgado permisos de ejecución sobre Mover.sh" INFO
	
				fi
				#----------------

				if [ ! -f  "$BINDIR/Start.sh" ]
				then
					ERRINST=1
					. ./Logging.sh Initializer "No se encuentra Start" ERR
				elif [ ! -x  "$BINDIR/Start.sh" ]
				then
					chmod +x "$BINDIR/Start.sh"
					. ./Logging.sh Initializer "Se han otorgado permisos de ejecución sobre Start.sh" INFO
				fi
				#----------------

				if [ ! -f  "$BINDIR/Stop.sh" ]
				then
					ERRINST=1
					. ./Logging.sh Initializer "No se encuentra Stop" ERR
				elif [ ! -x  "$BINDIR/Stop.sh" ]
				then
					chmod +x "$BINDIR/Stop.sh"
					. ./Logging.sh Initializer "Se han otorgado permisos de ejecución sobre Stop.sh" INFO
				fi
				#----------------
				
				if [ ! -f  "$BINDIR/GetPID.sh" ]
				then
					ERRINST=1
					. ./Logging.sh Initializer "No se encuentra GetPID" ERR
				elif [ ! -x  "$BINDIR/GetPID.sh" ]
				then
					chmod +x "$BINDIR/GetPID.sh"
					. ./Logging.sh Initializer "Se han otorgado permisos de ejecución sobre GetPID.sh" INFO
				fi
				

		fi #Fin de cosas de bindir





		if [ ! -d "$MAEDIR" ]
		then 
			ERRINST=1
			. ./Logging.sh Initializer "No existe el directorio $MAEDIR" ERR

		else
				# Verifico la existencia de los archivos maestros y tablas con permisos adecuados

				if [ ! -f "$MAEDIR/asociados.mae" ]
				then 
					ERRINST=1
					. ./Logging.sh Initializer "No se encontro maestro de asociados y colaboradores en el directorio $MAEDIR"  ERR

				elif [ ! -r "$MAEDIR/asociados.mae" ]	
				then
					chmod +r "$MAEDIR/asociados.mae"
					. ./Logging.sh Initializer "Se otorgaron permisos de lectura sobre asociados.mae"  INFO
				fi
				#--------------------------------------------
				if [ ! -f "$MAEDIR/super.mae" ]
				then
					ERRINST=1
					. ./Logging.sh Initializer "No se encontró maestro de supermercados en el directorio $MAEDIR" ERR
				elif [ ! -r "$MAEDIR/super.mae" ]
				then 
					chmod +r "$MAEDIR/super.mae"
					. ./Logging.sh Initializer "Se otorgaron permisos de lectura sobre super.mae"  INFO
				fi
				#--------------------------------------------
				if [ ! -f "$MAEDIR/um.tab" ]
				then
					ERRINST=1
					. ./Logging.sh Initializer "No se encontró la tabla de equivalencias de unidades de medida en el directorio $MAEDIR" ERR
	
				elif [ ! -r "$MAEDIR/um.tab" ]
				then
					chmod +r "$MAEDIR/um.tab"
					. ./Logging.sh Initializer "Se otorgaron permisos de lectura sobre um.tab"  INFO
				fi
				#---------------------------------------------


		fi # fin de cosas de MAEDIR



		if [ ! -d "$NOVEDIR"  ]
		then
			if [ $ERRINST -ne 2 ]
			then
				ERRINST=1
				. ./Logging.sh Initializer "No existe el directorio $NOVEDIR" ERR
			fi
		fi

		if [ ! -d "$ACEPDIR" ]
		then

			if [ $ERRINST -ne 2 ]
			then
				ERRINST=1
				. ./Logging.sh Initializer "No existe el directorio $ACEPDIR" ERR
			fi
		fi

		if [ ! -d "$RECHDIR" ]
		then
			if [ $ERRINST -ne 2 ]
			then		
				ERRINST=1
				. ./Logging.sh Initializer "No existe el directorio $RECHDIR" ERR
			fi		
		fi

		if [ ! -d "$INFODIR" ]
		then
			if [ $ERRINST -ne 2 ]
			then	
				ERRINST=1
				. ./Logging.sh Initializer "No existe el directorio $INFODIR" ERR
			fi		
		fi








	fi #  fin del if [-r "$CONFDIR/installer.conf"]





	if [ $ERRINST -eq 0 ] # si no hay errores en la instalacion
	then
		#exportacion de todas las variables si no fueron exportadas antes
		if [ -z "$INIT" ] || [ $INIT -eq 0 ]
		then
			export BINDIR

			export MAEDIR

			export NOVEDIR

			export DATASIZE
			export ACEPDIR
			export RECHDIR
			export INFODIR
			export LOGDIR
			export LOGEXT
			export LOGSIZE
			export CONFDIR


export GRUPO
			INIT=1
			export INIT

		else
			MsgYaInit="Ambiente ya inicializado. Si quiere reiniciar termine su sesión e inicie nuevamente"
			echo "$MsgYaInit"
			. ./Logging.sh Initializer "$MsgYaInit" INFO
		fi
		#fin exportacion
		#Inicio del demonio Listener y muestra el resumen
		Respuesta=''
		PID=''
		sigue=0
		while [ $sigue -eq 0 ]
		do 

			read -n 1 -p "Desea efectuar la activacion de Listener? (S/N): " Respuesta 
			echo ''
			if [ $Respuesta == 'S' ]
			then
				sigue=1
				#PID=`ps -o "pid,args" | grep 'Listener.sh$' | cut -f1 -d' '`
				PID=`ps -o "pid,args" | grep -m 1 'Listener.sh$' | sed "s/[^0-9]*\([0-9][0-9]*\).*/\1/"`
				
				if [ -z "$PID" ]
				then
					./Start.sh Listener.sh
					echo "Demonio iniciado. Puede detenerlo manualmente escribiendo \"./Stop.sh Listener.sh \" y presionando Enter"
				else 
					yaEstaba="Listener ya estaba iniciado. PID: $PID"
					echo $yaEstaba
					. ./Logging.sh Initializer "$yaEstaba" INFO

				fi
	

			elif [ $Respuesta == 'N' ] 
			then
				sigue=1
				echo "No se arrancará Listener. Para ejecutarlo manualmente escriba \"./Start.sh Listener.sh\" y presione Enter"
		
			else
			echo "Respuesta inválida"
			fi
		done

		


		#AL FINALIZAR MUESTRA EL CONTENIDO DE LAS VARIABLES Y EL PROCESS ID DEL DEMONIO SI ESTA ANDANDO

		echo -e "\E[4;92m TP SO7508 Primer cuatrimestre 2014. Tema C Copyright @ Grupo 09 \033[4m\e[0m"
		echo ''
		echo -e "Directorio de configuración: \e[34m $CONFDIR \e[0m"
		echo ''
		echo -e "Directorio de ejecutables:  \e[34m $BINDIR \e[0m"
		echo ''
		echo -e "Directorio de maestros y tablas: \e[34m $MAEDIR \e[0m"
		echo ''
		echo -e "Directorio de novedades: \e[34m $NOVEDIR \e[0m"
		echo ''
		echo -e "Directorio de aceptados: \e[34m $ACEPDIR \e[0m"
		echo ''
		echo -e "Directorio de informes de salida: \e[34m $INFODIR \e[0m"
		echo ''
		echo -e "Directorio de archivos rechazados: \e[34m $RECHDIR \e[0m"
		echo ''
		echo -e "Directorio de logs de comandos: \e[34m $LOGDIR/<comando>.$LOGEXT \e[0m"
		echo ''
		echo "Estado del sistema: INICIALIZADO"
		echo ''
	
		#	PID=`ps -o "pid,args" | grep 'Listener.sh$' | cut -f1 -d' '`
		PID=`ps -o "pid,args" | grep -m 1 'Listener.sh$' | sed "s/[^0-9]*\([0-9][0-9]*\).*/\1/"`
		if [ -n "$PID" ]
		then 
			echo "Demonio corriendo bajo el PID: $PID"
		fi
		. ./Logging.sh Initializer "Comando Initializer - Fin de ejecucion - Inicializacion correcta" INFO
	elif [ $ERRINST -eq 1 ] 
	then
		echo "Se han encontrado errores en la instalacion. Verifique el log Initializer.$LOGEXT para mas información"
		. ./Logging.sh Initializer "Comando Initializer - Fin de ejecucion - Inicializacion incorrecta" INFO
	elif  [ $ERRINST -eq 2 ]
	then
		echo "Se encontraron errores en la instalacion. Los mismos no serán logueados"
		echo "Para poder loguear los errores, verifique la existencia de:"
		echo "	1) Directorio de log"
		echo "	2) Directorio de herramientas de RETAILC"
		echo "	3) Herramienta de loggin de RETAILC"
		echo "	4) Archivo de configuracion de la instalacion de RETAILC"	

	
	fi





fi # fin del if [ -d $CONFDIR ]

