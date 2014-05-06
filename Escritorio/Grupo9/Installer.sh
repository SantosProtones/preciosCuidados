#Variables initialization. Default values.
GRUPO="$(dirname "$(readlink -f "$0")")"
CONFDIR=conf
DATADIR=datos
BINDIR=bin
MAEDIR=mae
NOVEDIR=arribos
DATASIZE=100
ACEPDIR=aceptadas
INFODIR=informes
RECHDIR=rechazado
LOGDIR=log
LOGEXT=log
MINLOGSIZEINKB=15
MAXLOGSIZEINKB=20
export LOGSIZE=$MAXLOGSIZEINKB
PERLVER=""
MINPERLVER=5
DIRNAME=""
SIZE=""
FREESPACE=`df -m "$GRUPO" | tail -1 | awk '{print $4}'`
LOGBIN=./Logging.sh
MOVEBIN=./Mover.sh
CONFIRMINSTALL="false"


#Messages
INFO_DIRNAME_CANNOT_BE_EMPTY="El nombre del directorio no puede ser vacío"
INFO_SIZE_MUST_BE_NUMERIC="El tamaño debe ser numérico"
INFO_INSTALLER_EXECUTION_STARTED="Inicio de Ejecución de Installer"
INFO_COPYRIGHT="TP SO7508 Primer Cuatrimestre 2014. Tema C Copyright © Grupo 09\n"
TITLE_MISSING_COMPONENTS="Componentes faltantes:"
INFO_INSTALLATION_STATUS_READY="Estado de la instalación: LISTA"
INFO_INSTALLATION_STATUS_INCOMPLETE="Estado de la instalación: INCOMPLETA"
INFO_INSTALLATION_STATUS_COMPLETE="Estado de la instalación: COMPLETA"
INFO_INSTALLATION_CANCELED="Proceso de Instalación Cancelado"
QUESTION_COMPLETE_INSTALLATION="Desea completar la instalación? (Si-No): "
INFO_INSTALLATION_CANCELED_BY_USER="Proceso de Instalación Cancelado por el usuario"
INFO_ANSWER_MUST_BE_YES_OR_NO="Por favor responda Si o No."
INFO_TERMS_AND_CONDITIONS="Al  instalar  TP  SO7508  Primer  Cuatrimestre  2014  UD.  expresa  aceptar  los\ntérminos  y  condiciones  del  \"ACUERDO  DE  LICENCIA  DE  SOFTWARE\"  incluido  en\neste paquete."
QUESTION_ACCEPT_TERMS_AND_CONDITIONS="Acepta? Si - No: "
INFO_TERMS_AND_CONDS_NOT_ACCEPTED="El usuario no aceptó los términos y condiciones. Instalación cancelada"
INFO_PERL_VERSION="Perl version:\n`perl -v`"
QUESTION_CONFIRM_INSTALLATION="Condirma Instalación? (Si-No): "
QUESTION_START_INSTALLATION="Iniciando Instalación. Esta Ud. seguro? (Si-No): "
TITLE_CREATING_DIRECTORY_STRUCTURE="Creando Estructuras de directorio. . . ."
TITLE_INSTALLING_MASTER_FILES_AND_TABLES="Instalando Archivos Maestros y Tablas"
TITLE_INSTALLING_PROGRAMS_AND_FUNCTIONS="Instalando Programas y Funciones"
TITLE_UPDATING_SYSTEM_CONFIG="Actualizando la configuración del sistema"
INFO_INSTALLATION_COMPLETE="Instalación CONCLUIDA"
ERROR_REQUIRED_COMPONENTS_NOT_FOUND="Algunos de los componentes requeridos para la instalación no pudieron ser encontrados. Descomprimir nuevamente el archivo tar puede solucionar el problema"
ERROR_INCORRECT_PERL_VERSION="TP SO7508 Primer Cuatrimestre 2014. Tema C Copyright © Grupo 09\nPara instalar el TP es necesario contar con Perl $MINPERLVER o superior. Efectúe su\ninstalación e inténtelo nuevamente.\nProceso de Instalación Cancelado"

#Exit codes
SUCCESS=0
INFO_CODE_INSTALLATION_CANCELED=1
INFO_CODE_INSTALLATION_CANCELED_BY_USER=2
ERROR_CODE_REQUIRED_COMPONENTS_NOT_FOUND=3
INFO_CODE_TERMS_AND_CONDS_NOT_ACCEPTED=4
ERROR_CODE_INCORRECT_PERL_VERSION=5

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
	"$LOGBIN" "$2" "$1" "$3"
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

function isDirectoryNameTaken() {
	local FOUND="false"

	if [ -d "$GRUPO/$1" ]
		then
			FOUND="true"
		else
			for i in "${DIRECTORYNAMESTAKEN[@]}"
			do
				if [ "$i" == "$1" ]
					then
						FOUND="true"
						break
				fi
			done
	fi
	echo $FOUND
}

function askForDirectoryName() {
	DIRNAME=""
	while [ true ];
	do
		read -p "$1" DIRNAME
		case $DIRNAME in
			"$CONFDIR" | "$DATADIR" )	echo "\"$DIRNAME\" es un nombre de directorio reservado";;
			"" )								echo "$INFO_DIRNAME_CANNOT_BE_EMPTY";;
			* )								if [ `isDirectoryNameTaken "$DIRNAME"` == "true" ]
												then
													echo "El nombre \"$DIRNAME\" ya fue seleccionado para otro directorio";
												else
													break
											fi;;
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
				echo "$INFO_SIZE_MUST_BE_NUMERIC"
		fi
	done
}

if [ ! -d "$GRUPO/$CONFDIR" -o ! -d "$GRUPO/$DATADIR" ];
	then
		echo "$ERROR_REQUIRED_COMPONENTS_NOT_FOUND"
		exit $ERROR_CODE_REQUIRED_COMPONENTS_NOT_FOUND
fi

if [ -f "$GRUPO/$CONFDIR/installer.conf" ];
	then
		#PACKAGE INSTALLED:
		if [ "`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'BINDIR' | cut -f2 -d'='`" != "" ]
			then
				BINDIR=`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'BINDIR' | cut -f2 -d'='`
		fi
		if [ "`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'MAEDIR' | cut -f2 -d'='`" != "" ]
			then
				MAEDIR=`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'MAEDIR' | cut -f2 -d'='`
		fi
		if [ "`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'NOVEDIR' | cut -f2 -d'='`" != "" ]
			then
				NOVEDIR=`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'NOVEDIR' | cut -f2 -d'='`
		fi
		if [ "`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'DATASIZE' | cut -f2 -d'='`" != "" ]
			then
				DATASIZE=`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'DATASIZE' | cut -f2 -d'='`
		fi
		if [ "`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'ACEPDIR' | cut -f2 -d'='`" != "" ]
			then
				ACEPDIR=`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'ACEPDIR' | cut -f2 -d'='`
		fi
		if [ "`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'INFODIR' | cut -f2 -d'='`" != "" ]
			then
				INFODIR=`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'INFODIR' | cut -f2 -d'='`
		fi
		if [ "`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'RECHDIR' | cut -f2 -d'='`" != "" ]
			then
				RECHDIR=`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'RECHDIR' | cut -f2 -d'='`
		fi
		if [ "`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'LOGDIR' | cut -f2 -d'='`" != "" ]
			then
				LOGDIR=`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'LOGDIR' | cut -f2 -d'='`
		fi
		if [ "`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'LOGEXT' | cut -f2 -d'='`" != "" ]
			then
				LOGEXT=`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'LOGEXT' | cut -f2 -d'='`
		fi
		if [ "`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'LOGSIZE' | cut -f2 -d'='`" != "" ]
			then
				LOGSIZE=`cat "$GRUPO/$CONFDIR/installer.conf" | fgrep 'LOGSIZE' | cut -f2 -d'='`
		fi
		LOGBIN="$GRUPO/$BINDIR/Logging.sh"
		MOVEBIN="$GRUPO/$BINDIR/Mover.sh"
fi

if [ ! -f "$LOGBIN" -o ! -f "$MOVEBIN" ]
	then
		echo "$ERROR_REQUIRED_COMPONENTS_NOT_FOUND"
		exit $ERROR_CODE_REQUIRED_COMPONENTS_NOT_FOUND
fi


log "$INFO_INSTALLER_EXECUTION_STARTED" "$GRUPO/$CONFDIR/installer" "INFO"

log "Log de la instalación: $GRUPO/$CONFDIR/Installer.log" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

log "Directorio predefinido de Configuración: $GRUPO/$CONFDIR" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

if [ ! -d "$GRUPO/$BINDIR" ];
	then
		MISSING=("${MISSING[@]}" "$BINDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$BINDIR")
fi

if [ ! -d "$GRUPO/$MAEDIR" ];
	then
		MISSING=("${MISSING[@]}" "$MAEDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$MAEDIR")
		if [ ! -d "$GRUPO/$MAEDIR/precios" ]
			then
				MISSING=("${MISSING[@]}" "$MAEDIR/precios")
		fi
		if [ ! -d "$GRUPO/$MAEDIR/precios/proc" ]
			then
				MISSING=("${MISSING[@]}" "$MAEDIR/precios/proc")
		fi
fi

if [ ! -d "$GRUPO/$NOVEDIR" ];
	then
		MISSING=("${MISSING[@]}" "$NOVEDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$NOVEDIR")
fi

if [ ! -d "$GRUPO/$ACEPDIR" ];
	then
		MISSING=("${MISSING[@]}" "$ACEPDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$ACEPDIR")
		if [ ! -d "$GRUPO/$ACEPDIR/proc" ]
			then
				MISSING=("${MISSING[@]}" "$ACEPDIR/proc")
		fi
fi

if [ ! -d "$GRUPO/$INFODIR" ];
	then
		MISSING=("${MISSING[@]}" "$INFODIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$INFODIR")
		if [ ! -d "$GRUPO/$INFODIR/pres" ]
			then
				MISSING=("${MISSING[@]}" "$INFODIR/pres")
		fi
fi

if [ ! -d "$GRUPO/$RECHDIR" ];
	then
		MISSING=("${MISSING[@]}" "$RECHDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$RECHDIR")
fi

if [ ! -d "$GRUPO/$LOGDIR" ];
	then
		MISSING=("${MISSING[@]}" "$LOGDIR")
	else
		INSTALLED=("${INSTALLED[@]}" "$LOGDIR")
fi

if [ ! ${#INSTALLED[@]} -eq 0 ]
	then
		log "$INFO_COPYRIGHT" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		log "Direct. de Configuracion: $CONFDIR\n
			`for FILE in "$GRUPO"/"$CONFDIR"/*
			do
				echo ${FILE##*/}
			done`" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		if [ `isInstalled "$BINDIR"` == "true" ]
			then
				log "Directorio  Ejecutables: $BINDIR\n
				`for FILE in "$GRUPO"/"$BINDIR"/*
				do
					echo ${FILE##*/}
				done`" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$MAEDIR"` == "true" ]
			then
				log "Direct Maestros y Tablas: $MAEDIR\n
				`for FILE in "$GRUPO"/"$MAEDIR/"*
				do
					echo ${FILE##*/}
				done`" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$NOVEDIR"` == "true" ]
			then
				log "Directorio de Novedades: $NOVEDIR" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$ACEPDIR"` == "true" ]
			then
				log "Dir. Novedades Aceptadas: $ACEPDIR" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$INFODIR"` == "true" ]
			then
				log "Dir. Informes de Salida: $INFODIR" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$RECHDIR"` == "true" ]
			then
				log "Dir. Archivos Rechazados: $RECHDIR" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$LOGDIR"` == "true" ]
			then
				log "Dir. de Logs de Comandos: $LOGDIR/<comando>.$LOGEXT" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ ! ${#MISSING[@]} -eq 0 ]
			then

				log "$TITLE_MISSING_COMPONENTS" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

				if [ `isMissing "$BINDIR"` == "true" ]
					then
						log "Directorio  Ejecutables: $BINDIR\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$MAEDIR"` == "true" ]
					then
						log "Direct Maestros y Tablas: $MAEDIR" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$MAEDIR/precios"` == "true" ]
					then
						log "Subdirectorio del Direct Maestros y Tablas: $MAEDIR/precios" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$MAEDIR/precios/proc"` == "true" ]
					then
						log "Subdirectorio del Direct Maestros y Tablas: $MAEDIR/precios/proc" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$NOVEDIR"` == "true" ]
					then
						log "Directorio de Novedades: $NOVEDIR" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$ACEPDIR"` == "true" ]
					then
						log "Dir. Novedades Aceptadas: $ACEPDIR" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$ACEPDIR/proc"` == "true" ]
					then
						log "Subdirectorio del Dir. Novedades Aceptadas: $ACEPDIR/proc" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$INFODIR"` == "true" ]
					then
						log "Dir. Informes de Salida: $INFODIR" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$INFODIR/pres"` == "true" ]
					then
						log "Subdirectorio del Dir. Informes de Salida: $INFODIR/pres" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$RECHDIR"` == "true" ]
					then
						log "Dir. Archivos Rechazados: $RECHDIR" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$LOGDIR"` == "true" ]
					then
						log "Dir. de Logs de Comandos: $LOGDIR/<comando>.$LOGEXT" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				log "$INFO_INSTALLATION_STATUS_INCOMPLETE" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

				while [ true ];
				do
					case `askUser "$QUESTION_COMPLETE_INSTALLATION"` in
						"Si" )	break;;
						"No" )	log "$INFO_INSTALLATION_CANCELED_BY_USER" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
								exit $INFO_CODE_INSTALLATION_CANCELED_BY_USER;;
						* )		echo "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
					esac
				done
			else
				log "$INFO_INSTALLATION_STATUS_COMPLETE" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

				log "$INFO_INSTALLATION_CANCELED" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				exit $INFO_CODE_INSTALLATION_CANCELED
		fi
fi

echo -e "$INFO_COPYRIGHT\n$INFO_TERMS_AND_CONDITIONS"
while [ true ];
do
	case `askUser "$QUESTION_ACCEPT_TERMS_AND_CONDITIONS"` in
		"Si" )	break;;
		"No" )	log "$INFO_TERMS_AND_CONDS_NOT_ACCEPTED" "$GRUPO/$CONFDIR/installer" "INFO"
				exit $INFO_CODE_TERMS_AND_CONDS_NOT_ACCEPTED;;
		* )		echo "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
	esac
done

PERLVER=`perl --version | grep \(v`
#A BIT HARCODED BUT BASH INDEX OPERATOR SUCKS
PERLVER=${PERLVER:43:1}

if [ $PERLVER -lt $MINPERLVER ]
	then
		log "$ERROR_INCORRECT_PERL_VERSION" "$GRUPO/$CONFDIR/installer" "ERR" doEcho
		exit $ERROR_CODE_INCORRECT_PERL_VERSION
	else
		log "$INFO_COPYRIGHT\n$INFO_PERL_VERSION" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
fi

while [ "$CONFIRMINSTALL" == "false" ];
do
	unset DIRECTORYNAMESTAKEN

	#HAS TO BE DONE THIS WAY BECAUSE SHELL SCRIPTING SUCKS
	if [ `isMissing "$BINDIR"` == "true" ]
		then
			askForDirectoryName "Defina el directorio de instalación de los ejecutables ($BINDIR): "
			replaceInMissing "$BINDIR" "$DIRNAME"
			BINDIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el directorio de instalación de los ejecutables ($BINDIR): $BINDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	fi
	
	if [ `isMissing "$MAEDIR"` == "true" ]
		then
			askForDirectoryName "Defina directorio para maestros y tablas ($MAEDIR): "
			replaceInMissing "$MAEDIR" "$DIRNAME"
			MAEDIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina directorio para maestros y tablas ($MAEDIR): $MAEDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	fi
	
	if [ `isMissing "$NOVEDIR"` == "true" ]
		then
			askForDirectoryName "Defina el Directorio de arribo de novedades ($NOVEDIR): "
			replaceInMissing "$NOVEDIR" "$DIRNAME"
			NOVEDIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el Directorio de arribo de novedades ($NOVEDIR): $NOVEDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	
			askForSize "Defina espacio mínimo libre para el arribo de novedades en Mbytes ($DATASIZE): "
			DATASIZE=$SIZE
			log "Defina espacio mínimo libre para el arribo de novedades en Mbytes ($DATASIZE): $DATASIZE" "$GRUPO/$CONFDIR/installer" "INFO"
			while [ true ]
			do
				if [ $FREESPACE -lt $DATASIZE ]
					then
						log "Insuficiente espacio en disco.\nEspacio disponible: $FREESPACE Mb.\nEspacio requerido: $DATASIZE Mb.\nCancele la instalación o inténtelo nuevamente." "$GRUPO/$CONFDIR/installer" "INFO" doEcho
						askForSize "Defina espacio mínimo libre para el arribo de novedades en Mbytes ($DATASIZE): "
						DATASIZE=$SIZE
						log "Defina espacio mínimo libre para el arribo de novedades en Mbytes ($DATASIZE): $DATASIZE" "$GRUPO/$CONFDIR/installer" "INFO"
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
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el directorio de grabación de las Novedades aceptadas ($ACEPDIR): $ACEPDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	fi
	
	if [ `isMissing "$INFODIR"` == "true" ]
		then
			askForDirectoryName "Defina el directorio de grabación de los informes de salida ($INFODIR): "
			replaceInMissing "$INFODIR" "$DIRNAME"
			INFODIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el directorio de grabación de los informes de salida ($INFODIR): $INFODIR" "$GRUPO/$CONFDIR/installer" "INFO"
	fi
	
	if [ `isMissing "$RECHDIR"` == "true" ]
		then
			askForDirectoryName "Defina el directorio de grabación de Archivos rechazados ($RECHDIR): "
			replaceInMissing "$RECHDIR" "$DIRNAME"
			RECHDIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el directorio de grabación de Archivos rechazados ($RECHDIR): $RECHDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	fi
	
	if [ `isMissing "$LOGDIR"` == "true" ]
		then
			askForDirectoryName "Defina el directorio de logs ($LOGDIR): "
			replaceInMissing "$LOGDIR" "$DIRNAME"
			LOGDIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el directorio de logs ($LOGDIR): $LOGDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	
			LOGEXT=`askUser "Ingrese la extensión para los archivos de log: (.$LOGEXT): "`
			log "Ingrese la extensión para los archivos de log: (.$LOGEXT): $LOGEXT" "$GRUPO/$CONFDIR/installer" "INFO"
	
			askForSize "Defina el tamaño máximo para los archivos $LOGEXT en Kbytes ($LOGSIZE): "
			LOGSIZE=$SIZE
			log "Defina el tamaño máximo para los archivos $LOGEXT en Kbytes ($LOGSIZE): $LOGSIZE" "$GRUPO/$CONFDIR/installer" "INFO"
			while [ true ]
			do
				if [ $LOGSIZE -lt $MINLOGSIZEINKB -o $LOGSIZE -gt $MAXLOGSIZEINKB ]
					then
						log "El tamaño máximo para los archivo $LOGEXT debe estar entre $MINLOGSIZEINKB  y $MAXLOGSIZEINKB. Por favor ingrese un valor en dicho rango" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
						askForSize "Defina el tamaño máximo para los archivos $LOGEXT en Kbytes ($LOGSIZE): "
						LOGSIZE=$SIZE
						log "Defina el tamaño máximo para los archivos $LOGEXT en Kbytes ($LOGSIZE): $LOGSIZE" "$GRUPO/$CONFDIR/installer" "INFO"
					else
						break
				fi
			done
	fi

	log "$INFO_COPYRIGHT" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	log "Direct. de Configuración: $CONFDIR.\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

	if [ `isMissing "$BINDIR"` == "true" ]
		then
			log "Directorio Ejecutables: $BINDIR.\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$MAEDIR"` == "true" ]
		then
			log "Direct Maestros y Tablas: $MAEDIR.\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$NOVEDIR"` == "true" ]
		then
			log "Directorio de Novedades: $NOVEDIR.\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
			log "Espacio mínimo libre para arribos: $DATASIZE Mb." "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$ACEPDIR"` == "true" ]
		then
			log "Dir. Novedades Aceptadas: $ACEPDIR.\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$INFODIR"` == "true" ]
		then
			log "Dir. Informes de Salida: $INFODIR.\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$RECHDIR"` == "true" ]
		then
			log "Dir. Archivos Rechazados: $RECHDIR.\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$LOGDIR"` == "true" ]
		then
			log "Dir. de Logs de Comandos: $LOGDIR/<comando>.$LOGEXT.\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
			log "Tamaño máximo para los archivos de log del sistema: $LOGSIZE Kb.\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	log "Estado de la instalación: LISTA.\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

	while [ true ];
	do
		case `askUser "$QUESTION_CONFIRM_INSTALLATION"` in
			"Si" )	CONFIRMINSTALL="true"
					break;;
			"No" )	log "El usuario decidió reingresar los nombres de directorios" "$GRUPO/$CONFDIR/installer" "INFO"
					break;;
			* )		echo "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
		esac
	done
done

#UNCOMMENT FOR FINAL RELEASE
#clear

while [ true ];
do
	case `askUser "$QUESTION_START_INSTALLATION"` in
		"Si" ) 	break;;
		"No" )	log "$INFO_INSTALLATION_CANCELED_BY_USER" "$GRUPO/$CONFDIR/installer" "INFO";
				exit $INFO_CODE_INSTALLATION_CANCELED_BY_USER;;
		* ) 		echo "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
	esac
done

echo "$TITLE_CREATING_DIRECTORY_STRUCTURE"
if [ `isMissing "$BINDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$BINDIR"
		echo "$BINDIR"
fi

if [ `isMissing "$MAEDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$MAEDIR/precios/proc"
		echo "$MAEDIR"
		echo "$MAEDIR/precios"
		echo "$MAEDIR/precios/proc"
	else
		if [ `isMissing "$MAEDIR/precios"` == "true" ]
			then
				mkdir -p "$GRUPO/$MAEDIR/precios/proc"
				echo "$MAEDIR/precios"
				echo "$MAEDIR/precios/proc"
			else
				if [ `isMissing "$MAEDIR/precios/proc"` == "true" ]
					then
						mkdir -p "$GRUPO/$MAEDIR/precios/proc"
						echo "$MAEDIR/precios/proc"
				fi
		fi
fi

if [ `isMissing "$NOVEDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$NOVEDIR"
		echo "$NOVEDIR"
fi

if [ `isMissing "$ACEPDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$ACEPDIR/proc"
		echo "$ACEPDIR"
		echo "$ACEPDIR/proc"
	else
		if [ `isMissing "$ACEPDIR/proc"` == "true" ]
			then
				mkdir -p "$GRUPO/$ACEPDIR/proc"
				echo "$ACEPDIR/proc"
		fi
fi

if [ `isMissing "$INFODIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$INFODIR/pres"
		echo "$INFODIR"
		echo "$INFODIR/pres"
	else
		if [ `isMissing "$INFODIR/pres"` == "true" ]
			then
				mkdir -p "$GRUPO/$INFODIR/pres"
				echo "$INFODIR/pres"
		fi
fi

if [ `isMissing "$RECHDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$RECHDIR"
		echo "$RECHDIR"
fi

if [ `isMissing "$LOGDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$LOGDIR"
		echo "$LOGDIR"
fi

echo "$TITLE_INSTALLING_MASTER_FILES_AND_TABLES"
for FILE in "$GRUPO"/datos/*.mae "$GRUPO"/datos/*.tab
do
	if [ -f "$FILE" ]
		then
			"$MOVEBIN" "$FILE" "$GRUPO/$MAEDIR"
	fi
done

echo "$TITLE_INSTALLING_PROGRAMS_AND_FUNCTIONS"
for FILE in "$GRUPO"/*.sh "$GRUPO"/*.pl
do
	if [ -f "$FILE" -a "${FILE##*/}" != "Installer.sh" -a "${FILE##*/}" != "Mover.sh" ]
		then
			"$MOVEBIN" "$FILE" "$GRUPO/$BINDIR"
	fi
done

if [ -f "$GRUPO/Mover.sh" ]
	then
		"$MOVEBIN" "$GRUPO/Mover.sh" "$GRUPO/$BINDIR"
fi

echo "$TITLE_UPDATING_SYSTEM_CONFIG"
echo "GRUPO=$GRUPO=`timeStamp`" > "$CONFDIR/installer.conf"
echo "CONFDIR=$CONFDIR=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"
echo "BINDIR=$BINDIR=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"
echo "MAEDIR=$MAEDIR=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"
echo "NOVEDIR=$NOVEDIR=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"
echo "DATASIZE=$DATASIZE=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"
echo "ACEPDIR=$ACEPDIR=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"
echo "INFODIR=$INFODIR=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"
echo "RECHDIR=$RECHDIR=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"
echo "LOGDIR=$LOGDIR=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"
echo "LOGEXT=$LOGEXT=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"
echo "LOGSIZE=$LOGSIZE=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"
echo "NUMSEC=0=$USER=`timeStamp`" >> "$CONFDIR/installer.conf"

LOGBIN="$GRUPO/$BINDIR/Logging.sh"

log "$INFO_INSTALLATION_COMPLETE" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

exit $SUCCESS
