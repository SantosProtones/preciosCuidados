#Variables initialization. Default values.
GRUPO=$PWD
CONFDIR=conf
BINDIR=bin
MAEDIR=mae
NOVEDIR=arribos
DATASIZE=100
ACEPDIR=aceptadas
INFODIR=informes
RECHDIR=rechazado
LOGDIR=log
export LOGEXT=log
export LOGSIZE=400
PERLVER=""
MINPERLVER=5
DIRNAME=""
SIZE=""
FREESPACE=`df -m $GRUPO | tail -1 | awk '{print $4}'`
LOGBIN=./Logging.sh
MOVEBIN=./Mover.sh
STATUS=COMPLETA

#Error messages
ERROR_REQUIRED_FOLDERS_NOT_FOUND="Algunas de las carpetas requeridas para la instalación no pudieron ser encontradas. Descomprimir nuevamente el archivo tar puede solucionar el problema"
ERROR_INCORRECT_PERL_VERSION="TP SO7508 Primer Cuatrimestre 2014. Tema C Copyright © Grupo 09\nPara instalar el TP es necesario contar con Perl 5 o superior. Efectúe su\ninstalación e inténtelo nuevamente.\nProceso de Instalación Cancelado"

#Error codes
ERROR_CODE_REQUIRED_FOLDERS_NOT_FOUND=2
ERROR_CODE_TERMS_AND_CONDS_NOT_ACCEPTED=3
ERROR_CODE_INCORRECT_PERL_VERSION=4

function timeStamp() {
	date +"%d/%m/%Y  %r"
}

function isInstalled() {
	local FOUND="false"
	for i in "${INSTALLED[@]}"
	do
		if [ "$i" == "$1" ]
			then
				FOUND="true"
				break
		fi
	done
	echo $FOUND
}

function isMissing() {
	local FOUND="false"
	for i in "${MISSING[@]}"
	do
		if [ "$i" == "$1" ]
			then
				FOUND="true"
				break
		fi
	done
	echo $FOUND
}

function replaceInMissing() {
	local INDEX=0
	for i in "${MISSING[@]}"
	do
		if [ "$i" == "$1" ]
			then
				MISSING[$INDEX]="$2"
				break
			else
				INDEX=$(($INDEX + 1))
		fi
	done
}

function log() {
	#$1 The message
	#$2 The file to append to.
	#$3 Log type
	$LOGBIN $2 "$1" "$3"
	if [ "$4" == "doEcho" ]
		then
			echo -e $1
	fi
}

function askUser() {
	#TODO: CHECK PARAMETERSS
	local RESP=""
	while [ "$RESP" == "" ]
	do
		#$1 is the question to the user
		read -p "$1" RESP
	done
	echo $RESP
}

function askForDirectoryName() {
	DIRNAME=""
	while [ true ];
	do
		read -p "$1" DIRNAME
		case $DIRNAME in
			"conf" ) echo "$DIRNAME es un nombre de directorio reservado";;
			"datos" ) echo "$DIRNAME es un nombre de directorio reservado";;
			"" ) echo "El nombre del directorio no puede ser vacío";;
			* ) break;;
		esac
	done
}

function askForSize() {
	SIZE=""
	while [ true ];
	do
		read -p "$1" SIZE
		if [ "$(echo $SIZE | grep "^[ [:digit:] ]*$")" ] 
			then 
				break
			else
				echo "El tamaño debe ser numérico"
		fi
	done
}

if [ ! -d conf -o ! -d datos ];
	then
		echo $ERROR_REQUIRED_FOLDERS_NOT_FOUND
		exit $ERROR_CODE_REQUIRED_FOLDERS_NOT_FOUND
fi

if [ -f $GRUPO/$CONFDIR/installer.conf ];
	then
		#PACKAGE INSTALLED:

		if [ `cat $GRUPO/$CONFDIR/installer.conf | fgrep 'BINDIR' | cut -f2 -d'='` != "" ]
			then
				BINDIR=`cat $GRUPO/$CONFDIR/installer.conf | fgrep 'BINDIR' | cut -f2 -d'='`
		fi
		if [ `cat $GRUPO/$CONFDIR/installer.conf | fgrep 'MAEDIR' | cut -f2 -d'='` != "" ]
			then
				MAEDIR=`cat $GRUPO/$CONFDIR/installer.conf | fgrep 'MAEDIR' | cut -f2 -d'='`
		fi
		if [ `cat $GRUPO/$CONFDIR/installer.conf | fgrep 'NOVEDIR' | cut -f2 -d'='` != "" ]
			then
				NOVEDIR=`cat $GRUPO/$CONFDIR/installer.conf | fgrep 'NOVEDIR' | cut -f2 -d'='`
		fi
		if [ `cat $GRUPO/$CONFDIR/installer.conf | fgrep 'DATASIZE' | cut -f2 -d'='` != "" ]
			then
				DATASIZE=`cat $GRUPO/$CONFDIR/installer.conf | fgrep 'DATASIZE' | cut -f2 -d'='`
		fi
		if [ `cat $GRUPO/$CONFDIR/installer.conf | fgrep 'ACEPDIR' | cut -f2 -d'='` != "" ]
			then
				ACEPDIR=`cat $GRUPO/$CONFDIR/installer.conf | fgrep 'ACEPDIR' | cut -f2 -d'='`
		fi
		if [ `cat $GRUPO/$CONFDIR/installer.conf | fgrep 'INFODIR' | cut -f2 -d'='` != "" ]
			then
				INFODIR=`cat $GRUPO/$CONFDIR/installer.conf | fgrep 'INFODIR' | cut -f2 -d'='`
		fi
		if [ `cat $GRUPO/$CONFDIR/installer.conf | fgrep 'RECHDIR' | cut -f2 -d'='` != "" ]
			then
				RECHDIR=`cat $GRUPO/$CONFDIR/installer.conf | fgrep 'RECHDIR' | cut -f2 -d'='`
		fi
		if [ `cat $GRUPO/$CONFDIR/installer.conf | fgrep 'LOGDIR' | cut -f2 -d'='` != "" ]
			then
				LOGDIR=`cat $GRUPO/$CONFDIR/installer.conf | fgrep 'LOGDIR' | cut -f2 -d'='`
		fi
		if [ `cat $GRUPO/$CONFDIR/installer.conf | fgrep 'LOGEXT' | cut -f2 -d'='` != "" ]
			then
				LOGEXT=`cat $GRUPO/$CONFDIR/installer.conf | fgrep 'LOGEXT' | cut -f2 -d'='`
		fi
		if [ `cat $GRUPO/$CONFDIR/installer.conf | fgrep 'LOGSIZE' | cut -f2 -d'='` != "" ]
			then
				LOGSIZE=`cat $GRUPO/$CONFDIR/installer.conf | fgrep 'LOGSIZE' | cut -f2 -d'='`
		fi
		LOGBIN=$GRUPO/$BINDIR/Logging.sh
		MOVEBIN=$GRUPO/$BINDIR/Mover.sh
fi

log "Inicio de Ejecución de Installer" $GRUPO/$CONFDIR/installer "INFO"

log "Log de la instalación: $GRUPO/$CONFDIR/Installer.log" $GRUPO/$CONFDIR/installer "INFO" doEcho

log "Directorio predefinido de Configuración: $GRUPO/$CONFDIR" $GRUPO/$CONFDIR/installer "INFO" doEcho

log "TP SO7508 Primer Cuatrimestre 2014. Tema C Copyright © Grupo 09" $GRUPO/$CONFDIR/installer "INFO" doEcho

if [ ! -d $GRUPO/$BINDIR ];
	then
		MISSING=("${MISSING[@]}" "$BINDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$BINDIR")
fi

if [ ! -d $GRUPO/$MAEDIR ];
	then
		MISSING=("${MISSING[@]}" "$MAEDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$MAEDIR")
fi

if [ ! -d $GRUPO/$NOVEDIR ];
	then
		MISSING=("${MISSING[@]}" "$NOVEDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$NOVEDIR")
fi

if [ ! -d $GRUPO/$ACEPDIR ];
	then
		MISSING=("${MISSING[@]}" "$ACEPDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$ACEPDIR")
fi

if [ ! -d $GRUPO/$INFODIR ];
	then
		MISSING=("${MISSING[@]}" "$INFODIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$INFODIR")
fi

if [ ! -d $GRUPO/$RECHDIR ];
	then
		MISSING=("${MISSING[@]}" "$RECHDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$RECHDIR")
fi

if [ ! -d $GRUPO/$LOGDIR ];
	then
		MISSING=("${MISSING[@]}" "$LOGDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$LOGDIR")
fi

if [ ! ${#INSTALLED[@]} -eq 0 ]
	then
		log "Direct. de Configuracion: $CONFDIR\n
			`for FILE in $GRUPO/$CONFDIR/*
			do
				echo ${FILE##*/}
			done`" $GRUPO/$CONFDIR/installer "INFO" doEcho
		if [ `isInstalled "$BINDIR"` == "true" ]
			then
				log "Directorio  Ejecutables: $BINDIR\n
				`for FILE in $GRUPO/$BINDIR/*
				do
					echo ${FILE##*/}
				done`" $GRUPO/$CONFDIR/installer "INFO" doEcho
		fi

		if [ `isInstalled "$MAEDIR"` == "true" ]
			then
				log "Direct Maestros y Tablas: $MAEDIR\n
				`for FILE in $GRUPO/$MAEDIR/*
				do
					echo ${FILE##*/}
				done`" $GRUPO/$CONFDIR/installer "INFO" doEcho
		fi

		if [ `isInstalled "$NOVEDIR"` == "true" ]
			then
				log "Directorio de Novedades: $NOVEDIR" $GRUPO/$CONFDIR/installer "INFO" doEcho
		fi

		if [ `isInstalled "$ACEPDIR"` == "true" ]
			then
				log "Dir. Novedades Aceptadas: $ACEPDIR" $GRUPO/$CONFDIR/installer "INFO" doEcho
		fi

		if [ `isInstalled "$INFODIR"` == "true" ]
			then
				log "Dir. Informes de Salida: $INFODIR" $GRUPO/$CONFDIR/installer "INFO" doEcho
		fi

		if [ `isInstalled "$RECHDIR"` == "true" ]
			then
				log "Dir. Archivos Rechazados: $RECHDIR" $GRUPO/$CONFDIR/installer "INFO" doEcho
		fi

		if [ `isInstalled "$LOGDIR"` == "true" ]
			then
				log "Dir. de Logs de Comandos: $LOGDIR/<comando>.$LOGEXT" $GRUPO/$CONFDIR/installer "INFO" doEcho
		fi

		if [ ! ${#MISSING[@]} -eq 0 ]
			then

				log "Componentes faltantes:" $GRUPO/$CONFDIR/installer "INFO" doEcho

				if [ `isMissing "$BINDIR"` == "true" ]
					then
						log "Directorio  Ejecutables: $BINDIR" $GRUPO/$CONFDIR/installer "INFO" doEcho
				fi

				if [ `isMissing "$MAEDIR"` == "true" ]
					then
						log "Direct Maestros y Tablas: $MAEDIR" $GRUPO/$CONFDIR/installer "INFO" doEcho
				fi

				if [ `isMissing "$NOVEDIR"` == "true" ]
					then
						log "Directorio de Novedades: $NOVEDIR" $GRUPO/$CONFDIR/installer "INFO" doEcho
				fi

				if [ `isMissing "$ACEPDIR"` == "true" ]
					then
						log "Dir. Novedades Aceptadas: $ACEPDIR" $GRUPO/$CONFDIR/installer "INFO" doEcho
				fi

				if [ `isMissing "$INFODIR"` == "true" ]
					then
						log "Dir. Informes de Salida: $INFODIR" $GRUPO/$CONFDIR/installer "INFO" doEcho
				fi

				if [ `isMissing "$RECHDIR"` == "true" ]
					then
						log "Dir. Archivos Rechazados: $RECHDIR" $GRUPO/$CONFDIR/installer "INFO" doEcho
				fi

				if [ `isMissing "$LOGDIR"` == "true" ]
					then
						log "Dir. de Logs de Comandos: $LOGDIR/<comando>.$LOGEXT" $GRUPO/$CONFDIR/installer "INFO" doEcho
				fi

				while [ true ];
				do
					case `askUser "Desea completar la instalación? (Si-No):"` in
						"Si" )	break;;
						"No" )	echo "Cancelo instalacion"
								exit;;
						* ) echo "Por favor respona Si o No.";;
					esac
				done
			else
				log "Estado de la instalación: COMPLETA" $GRUPO/$CONFDIR/installer "INFO" doEcho

				log "Proceso de Instalación Cancelado" $GRUPO/$CONFDIR/installer "INFO" doEcho
				exit 0
		fi
fi

echo -e "Al  instalar  TP  SO7508  Primer  Cuatrimestre  2014  UD.  expresa  aceptar  los\ntérminos  y  condiciones  del  "ACUERDO  DE  LICENCIA  DE  SOFTWARE"  incluido  en\neste paquete."
while [ true ];
do
	case `askUser "Acepta? Si - No: "` in
		"Si" )	break;;
		"No" )	exit $ERROR_CODE_TERMS_AND_CONDS_NOT_ACCEPTED;;
		* )		echo "Por favor respona Si o No.";;
	esac
done

PERLVER=`perl --version | grep \(v`
#A BIT HARCODED BUT BASH INDEX OPERATOR SUCKS
PERLVER=${PERLVER:43:1}

if [ $PERLVER -lt $MINPERLVER ]
	then
		log $ERROR_INCORRECT_PERL_VERSION $GRUPO/$CONFDIR/installer "ERR" doEcho
		exit $ERROR_CODE_INCORRECT_PERL_VERSION
	else
		log "Perl version:\n`perl -v`" $GRUPO/$CONFDIR/installer "INFO" doEcho
fi

#HAS TO BE DONE THIS WAY BECAUSE SHELL SCRIPTING SUCKS
if [ `isMissing "$BINDIR"` == "true" ]
	then
		askForDirectoryName "Defina el directorio de instalación de los ejecutables ($BINDIR): "
		replaceInMissing "$BINDIR" "$DIRNAME"
		BINDIR=$DIRNAME
		log "Defina el directorio de instalación de los ejecutables ($BINDIR): $BINDIR" $GRUPO/$CONFDIR/installer "INFO"
fi

if [ `isMissing "$MAEDIR"` == "true" ]
	then
		askForDirectoryName "Defina directorio para maestros y tablas ($MAEDIR): "
		replaceInMissing "$MAEDIR" "$DIRNAME"
		MAEDIR=$DIRNAME
		log "Defina directorio para maestros y tablas ($MAEDIR): $MAEDIR" $GRUPO/$CONFDIR/installer "INFO"
fi

if [ `isMissing "$NOVEDIR"` == "true" ]
	then
		askForDirectoryName "Defina el Directorio de arribo de novedades ($NOVEDIR): "
		replaceInMissing "$NOVEDIR" "$DIRNAME"
		NOVEDIR=$DIRNAME
		log "Defina el Directorio de arribo de novedades ($NOVEDIR): $NOVEDIR" $GRUPO/$CONFDIR/installer "INFO"

		askForSize "Defina espacio mínimo libre para el arribo de novedades en Mbytes ($DATASIZE): "
		DATASIZE=$SIZE
		log "Defina espacio mínimo libre para el arribo de novedades en Mbytes ($DATASIZE): $DATASIZE" $GRUPO/$CONFDIR/installer "INFO"
		while [ true ]
		do
			if [ $FREESPACE -lt $DATASIZE ]
				then
					log "Espacio libre insuficiente. Por favor seleccione un valor menor" $GRUPO/$CONFDIR/installer "WAR" doEcho
					askForSize "Defina espacio mínimo libre para el arribo de novedades en Mbytes ($DATASIZE): "
					DATASIZE=$SIZE
					log "Defina espacio mínimo libre para el arribo de novedades en Mbytes ($DATASIZE): $DATASIZE" $GRUPO/$CONFDIR/installer "INFO"
				else
					break
			fi
		done
fi

if [ `isMissing "$ACEPDIR"` == "true" ]
	then
		askForDirectoryName "Defina el directorio de grabación de las Novedades aceptadas ($ACEPDIR): "
		replaceInMissing "$ACEPDIR" "$DIRNAME"
		ACEPDIR=$DIRNAME
		log "Defina el directorio de grabación de las Novedades aceptadas ($ACEPDIR): $ACEPDIR" $GRUPO/$CONFDIR/installer "INFO"
fi

if [ `isMissing "$INFODIR"` == "true" ]
	then
		askForDirectoryName "Defina el directorio de grabación de los informes de salida ($INFODIR): "
		replaceInMissing "$INFODIR" "$DIRNAME"
		INFODIR=$DIRNAME
		log "Defina el directorio de grabación de los informes de salida ($INFODIR): $INFODIR" $GRUPO/$CONFDIR/installer "INFO"
fi

if [ `isMissing "$RECHDIR"` == "true" ]
	then
		askForDirectoryName "Defina el directorio de grabación de Archivos rechazados ($RECHDIR): "
		replaceInMissing "$RECHDIR" "$DIRNAME"
		RECHDIR=$DIRNAME
		log "Defina el directorio de grabación de Archivos rechazados ($RECHDIR): $RECHDIR" $GRUPO/$CONFDIR/installer "INFO"
fi

if [ `isMissing "$LOGDIR"` == "true" ]
	then
		askForDirectoryName "Defina el directorio de logs ($LOGDIR): "
		replaceInMissing "$LOGDIR" "$DIRNAME"
		LOGDIR=$DIRNAME
		log "Defina el directorio de logs ($LOGDIR): $LOGDIR" $GRUPO/$CONFDIR/installer "INFO"

		LOGEXT=`askUser "Ingrese la extensión para los archivos de log: ($LOGEXT): "`
		log "Ingrese la extensión para los archivos de log: ($LOGEXT): $LOGEXT" $GRUPO/$CONFDIR/installer "INFO"

		askForSize "Defina el tamaño máximo para los archivos $LOGEXT en Kbytes ($LOGSIZE): "
		LOGSIZE=$SIZE
		log "Defina el tamaño máximo para los archivos $LOGEXT en Kbytes ($LOGSIZE): $LOGSIZE" $GRUPO/$CONFDIR/installer "INFO"
fi

#UNCOMMENT FOR FINAL RELEASE
#clear

log "TP SO7508 Primer Cuatrimestre 2014. Tema C Copyright © Grupo 09\nDirect. de Configuración: $CONFDIR.\nDirectorio Ejecutables: $BINDIR.\nDirect Maestros y Tablas: $MAEDIR.\nDirectorio de Novedades: $NOVEDIR.\nEspacio mínimo libre para arribos: $DATASIZE Mb.\nDir. Novedades Aceptadas: $ACEPDIR.\nDir. Informes de Salida: $INFODIR.\nDir. Archivos Rechazados: $RECHDIR.\nDir. de Logs de Comandos: $LOGDIR/<comando>.$LOGEXT.\nTamaño máximo para los archivos de log del sistema: $LOGSIZE Kb.\nEstado de la instalación: LISTA." $GRUPO/$CONFDIR/installer "INFO" doEcho

while [ true ];
do
	case `askUser "Iniciando Instalación. Esta Ud. seguro? (Si-No)"` in
		"Si" ) 	break;;
		"No" ) 	echo "Canceló instalación"
				exit 5;;
		* ) 		echo "Por favor respona Si o No.";;
	esac
done

echo "Creando Estructuras de directorio. . . ."
if [ `isMissing "$BINDIR"` == "true" ]
	then
		mkdir -p $BINDIR
		echo "$BINDIR"
fi

if [ `isMissing "$MAEDIR"` == "true" ]
	then
		mkdir -p $MAEDIR/precios/proc
		echo "$MAEDIR"
		echo "$MAEDIR/precios"
		echo "$MAEDIR/precios/proc"
fi

if [ `isMissing "$NOVEDIR"` == "true" ]
	then
		mkdir -p $NOVEDIR
		echo "$NOVEDIR"
fi

if [ `isMissing "$ACEPDIR"` == "true" ]
	then
		mkdir -p $ACEPDIR/proc
		echo "$ACEPDIR"
		echo "$ACEPDIR/proc"
fi

if [ `isMissing "$INFODIR"` == "true" ]
	then
		mkdir -p $INFODIR/pres
		echo "$INFODIR"
		echo "$INFODIR/pres"
fi

if [ `isMissing "$RECHDIR"` == "true" ]
	then
		mkdir -p $RECHDIR
		echo "$RECHDIR"
fi

if [ `isMissing "$LOGDIR"` == "true" ]
	then
		mkdir -p $LOGDIR
		echo "$LOGDIR"
fi

echo "Instalando Archivos Maestros y Tablas"
for FILE in $GRUPO/datos/*.mae $GRUPO/datos/*.tab
do
	if [ -f "$FILE" ]
		then
			$MOVEBIN $FILE $GRUPO/$MAEDIR
	fi
done

for FILE in $GRUPO/*.sh $GRUPO/*.pl
do
	if [ -f "$FILE" -a ${FILE##*/} != "Installer.sh" -a ${FILE##*/} != "Mover.sh" ]
		then
			$MOVEBIN $FILE $GRUPO/$BINDIR
	fi
done

if [ -f "$GRUPO/Mover.sh" ]
	then
		$MOVEBIN $GRUPO/Mover.sh $GRUPO/$BINDIR
fi

echo "Actualizando la configuración del sistema"
echo "GRUPO=$GRUPO=$USER=`timeStamp`" > $CONFDIR/installer.conf
echo "CONFDIR=$CONFDIR=$USER=`timeStamp`" >> $CONFDIR/installer.conf
echo "BINDIR=$BINDIR=$USER=`timeStamp`" >> $CONFDIR/installer.conf
echo "MAEDIR=$MAEDIR=$USER=`timeStamp`" >> $CONFDIR/installer.conf
echo "NOVEDIR=$NOVEDIR=$USER=`timeStamp`" >> $CONFDIR/installer.conf
echo "DATASIZE=$DATASIZE=$USER=`timeStamp`" >> $CONFDIR/installer.conf
echo "ACEPDIR=$ACEPDIR=$USER=`timeStamp`" >> $CONFDIR/installer.conf
echo "INFODIR=$INFODIR=$USER=`timeStamp`" >> $CONFDIR/installer.conf
echo "RECHDIR=$RECHDIR=$USER=`timeStamp`" >> $CONFDIR/installer.conf
echo "LOGDIR=$LOGDIR=$USER=`timeStamp`" >> $CONFDIR/installer.conf
echo "LOGEXT=$LOGEXT=$USER=`timeStamp`" >> $CONFDIR/installer.conf
echo "LOGSIZE=$LOGSIZE=$USER=`timeStamp`" >> $CONFDIR/installer.conf
echo "NUMSEC=0=$USER=`timeStamp`" >> $CONFDIR/installer.conf

echo "Instalación CONCLUIDA"

exit 0