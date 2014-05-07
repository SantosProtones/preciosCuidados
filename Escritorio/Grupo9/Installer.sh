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
FORMAT_BOLD_RED="\e[1m\e[31m"
FORMAT_BOLD_GREEN="\e[1m\e[32m"
FORMAT_BOLD_BLUE="\e[1m\e[34m"
FORMAT_BOLD="\e[1m"
FORMAT_DEFAULT="\e[0m"

#Messages
INFO_DIRNAME_CANNOT_BE_EMPTY="El nombre del directorio no puede ser vacío"
INFO_SIZE_MUST_BE_NUMERIC="El tamaño debe ser numérico"
INFO_INSTALLER_EXECUTION_STARTED="Inicio de Ejecución de Installer"
INFO_COPYRIGHT="TP SO7508 ${FORMAT_BOLD}Primer Cuatrimestre 2014${FORMAT_DEFAULT}. Tema ${FORMAT_BOLD}C${FORMAT_DEFAULT} Copyright © Grupo 09\n"
TITLE_MISSING_COMPONENTS="Componentes faltantes:"
INFO_INSTALLATION_STATUS_READY="Estado de la instalación: ${FORMAT_BOLD_BLUE}LISTA${FORMAT_DEFAULT}\n"
INFO_INSTALLATION_STATUS_INCOMPLETE="Estado de la instalación: ${FORMAT_BOLD_RED}INCOMPLETA${FORMAT_DEFAULT}\n"
INFO_INSTALLATION_STATUS_COMPLETE="Estado de la instalación: ${FORMAT_BOLD_GREEN}COMPLETA${FORMAT_DEFAULT}\n"
INFO_INSTALLATION_CANCELED="Proceso de Instalación Cancelado"
QUESTION_COMPLETE_INSTALLATION="Desea completar la instalación? (${FORMAT_BOLD}Si${FORMAT_DEFAULT} - ${FORMAT_BOLD}No${FORMAT_DEFAULT}): "
INFO_INSTALLATION_CANCELED_BY_USER="Proceso de Instalación Cancelado por el usuario"
INFO_ANSWER_MUST_BE_YES_OR_NO="Por favor responda ${FORMAT_BOLD}Si${FORMAT_DEFAULT} o ${FORMAT_BOLD}No${FORMAT_DEFAULT}."
INFO_TERMS_AND_CONDITIONS="Al  instalar  TP  SO7508  ${FORMAT_BOLD}Primer  Cuatrimestre  2014${FORMAT_DEFAULT} UD.  expresa  aceptar  los términos  y  condiciones  del  \"ACUERDO  DE  LICENCIA  DE  SOFTWARE\"  incluido  en este paquete.\n"
QUESTION_ACCEPT_TERMS_AND_CONDITIONS="Acepta? (${FORMAT_BOLD}Si${FORMAT_DEFAULT} - ${FORMAT_BOLD}No${FORMAT_DEFAULT}): "
INFO_TERMS_AND_CONDS_NOT_ACCEPTED="El usuario no aceptó los términos y condiciones. Instalación cancelada"
INFO_PERL_VERSION="Perl version:\n`perl -v`"
QUESTION_CONFIRM_INSTALLATION="Confirma Instalación? (${FORMAT_BOLD}Si${FORMAT_DEFAULT} - ${FORMAT_BOLD}No${FORMAT_DEFAULT}): "
QUESTION_START_INSTALLATION="Iniciando Instalación. Esta Ud. seguro? (${FORMAT_BOLD}Si${FORMAT_DEFAULT} -  ${FORMAT_BOLD}No${FORMAT_DEFAULT}): "
TITLE_CREATING_DIRECTORY_STRUCTURE="Creando Estructuras de directorio. . . .\n"
TITLE_INSTALLING_MASTER_FILES_AND_TABLES="Instalando Archivos Maestros y Tablas\n"
TITLE_INSTALLING_PROGRAMS_AND_FUNCTIONS="Instalando Programas y Funciones\n"
TITLE_UPDATING_SYSTEM_CONFIG="Actualizando la configuración del sistema\n"
INFO_INSTALLATION_COMPLETE="Instalación ${FORMAT_BOLD_GREEN}CONCLUIDA${FORMAT_DEFAULT}"
ERROR_REQUIRED_COMPONENTS_NOT_FOUND="Algunos de los componentes requeridos para la instalación no pudieron ser encontrados. Descomprimir nuevamente el archivo tar puede solucionar el problema"
ERROR_INCORRECT_PERL_VERSION="$INFO_COPYRIGHT\nPara instalar el TP es necesario contar con Perl $MINPERLVER o superior. Efectúe su instalación e inténtelo nuevamente.\n\n$INFO_INSTALLATION_CANCELED"

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
		read -p "`echo -e -n "$1"`" RESP
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
		echo -e -n "$1"
		read DIRNAME
		case $DIRNAME in
			"$CONFDIR" | "$DATADIR" )	echo -e "${FORMAT_BOLD_BLUE}$DIRNAME${FORMAT_DEFAULT} es un nombre de directorio reservado. Por favor elija otro nombre";;
			"" )								echo "$INFO_DIRNAME_CANNOT_BE_EMPTY";;
			* )								if [ `isDirectoryNameTaken "$DIRNAME"` == "true" ]
												then
													echo -e "El nombre ${FORMAT_BOLD_BLUE}$DIRNAME${FORMAT_DEFAULT} ya fue seleccionado para otro directorio. Por favor elija otro nombre";
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
		echo -e -n "$1"
		read SIZE
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

if [ ! -f "$LOGBIN" ]
	then
		LOGBIN="$GRUPO/Logging.sh"
		if [ ! -f "$LOGBIN" ]
			then
				echo "$ERROR_REQUIRED_COMPONENTS_NOT_FOUND"
				exit $ERROR_CODE_REQUIRED_COMPONENTS_NOT_FOUND
		fi
fi
if [ ! -f "$MOVEBIN" ]
	then
		MOVEBIN="$GRUPO/Mover.sh"
		if [ ! -f "$MOVEBIN" ]
			then
				echo "$ERROR_REQUIRED_COMPONENTS_NOT_FOUND"
				exit $ERROR_CODE_REQUIRED_COMPONENTS_NOT_FOUND
		fi
fi


log "$INFO_INSTALLER_EXECUTION_STARTED" "$GRUPO/$CONFDIR/installer" "INFO"

log "\nLog de la instalación: ${FORMAT_BOLD_GREEN}$GRUPO/$CONFDIR/Installer.log${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

log "Directorio predefinido de Configuración: ${FORMAT_BOLD_GREEN}$GRUPO/$CONFDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

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
		log "Direct. de Configuracion: ${FORMAT_BOLD_GREEN}$GRUPO/$CONFDIR${FORMAT_DEFAULT}${FORMAT_BOLD}\n
			`for FILE in "$GRUPO"/"$CONFDIR"/*
			do
				echo "${FILE##*/}"
			done`${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		if [ `isInstalled "$BINDIR"` == "true" ]
			then
				log "Directorio  Ejecutables: ${FORMAT_BOLD_GREEN}$GRUPO/$BINDIR${FORMAT_DEFAULT}${FORMAT_BOLD}\n
				`for FILE in "$GRUPO"/"$BINDIR"/*
				do
					echo "${FILE##*/}"
				done`${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$MAEDIR"` == "true" ]
			then
				log "Direct Maestros y Tablas: ${FORMAT_BOLD_GREEN}$GRUPO/$MAEDIR${FORMAT_DEFAULT}${FORMAT_BOLD}\n
				`for FILE in "$GRUPO"/"$MAEDIR/"*
				do
					echo "${FILE##*/}"
				done`${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$NOVEDIR"` == "true" ]
			then
				log "Directorio de Novedades: ${FORMAT_BOLD_GREEN}$GRUPO/$NOVEDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$ACEPDIR"` == "true" ]
			then
				log "Dir. Novedades Aceptadas: ${FORMAT_BOLD_GREEN}$GRUPO/$ACEPDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$INFODIR"` == "true" ]
			then
				log "Dir. Informes de Salida: ${FORMAT_BOLD_GREEN}$GRUPO/$INFODIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$RECHDIR"` == "true" ]
			then
				log "Dir. Archivos Rechazados: ${FORMAT_BOLD_GREEN}$GRUPO/$RECHDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ `isInstalled "$LOGDIR"` == "true" ]
			then
				log "Dir. de Logs de Comandos: ${FORMAT_BOLD_GREEN}$GRUPO/$LOGDIR${FORMAT_DEFAULT}/<comando>.${FORMAT_BOLD_GREEN}$LOGEXT${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
		fi

		if [ ! ${#MISSING[@]} -eq 0 ]
			then

				log "$TITLE_MISSING_COMPONENTS" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

				if [ `isMissing "$BINDIR"` == "true" ]
					then
						log "Directorio  Ejecutables: ${FORMAT_BOLD_RED}$GRUPO/$BINDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$MAEDIR"` == "true" ]
					then
						log "Direct Maestros y Tablas: ${FORMAT_BOLD_RED}$GRUPO/$MAEDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$MAEDIR/precios"` == "true" ]
					then
						log "Subdirectorio del Direct Maestros y Tablas: ${FORMAT_BOLD_RED}$GRUPO/$MAEDIR/precios${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$MAEDIR/precios/proc"` == "true" ]
					then
						log "Subdirectorio del Direct Maestros y Tablas: ${FORMAT_BOLD_RED}$GRUPO/$MAEDIR/precios/proc${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$NOVEDIR"` == "true" ]
					then
						log "Directorio de Novedades: ${FORMAT_BOLD_RED}$GRUPO/$NOVEDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$ACEPDIR"` == "true" ]
					then
						log "Dir. Novedades Aceptadas: ${FORMAT_BOLD_RED}$GRUPO/$ACEPDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$ACEPDIR/proc"` == "true" ]
					then
						log "Subdirectorio del Dir. Novedades Aceptadas: ${FORMAT_BOLD_RED}$GRUPO/$ACEPDIR/proc${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$INFODIR"` == "true" ]
					then
						log "Dir. Informes de Salida: ${FORMAT_BOLD_RED}$GRUPO/$INFODIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$INFODIR/pres"` == "true" ]
					then
						log "Subdirectorio del Dir. Informes de Salida: ${FORMAT_BOLD_RED}$GRUPO/$INFODIR/pres${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$RECHDIR"` == "true" ]
					then
						log "Dir. Archivos Rechazados: ${FORMAT_BOLD_RED}$GRUPO/$RECHDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				if [ `isMissing "$LOGDIR"` == "true" ]
					then
						log "Dir. de Logs de Comandos: ${FORMAT_BOLD_RED}$GRUPO/$LOGDIR/${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				fi

				log "$INFO_INSTALLATION_STATUS_INCOMPLETE" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

				while [ true ];
				do
					case `askUser "$QUESTION_COMPLETE_INSTALLATION"` in
						"Si" )	break;;
						"No" )	log "$INFO_INSTALLATION_CANCELED_BY_USER" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
								exit $INFO_CODE_INSTALLATION_CANCELED_BY_USER;;
						* )		echo -e "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
					esac
				done
			else
				log "$INFO_INSTALLATION_STATUS_COMPLETE" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

				log "$INFO_INSTALLATION_CANCELED" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
				exit $INFO_CODE_INSTALLATION_CANCELED
		fi
		echo ""
fi

echo -e "$INFO_COPYRIGHT\n$INFO_TERMS_AND_CONDITIONS"
while [ true ];
do
	case `askUser "$QUESTION_ACCEPT_TERMS_AND_CONDITIONS"` in
		"Si" )	break;;
		"No" )	log "$INFO_TERMS_AND_CONDS_NOT_ACCEPTED" "$GRUPO/$CONFDIR/installer" "INFO"
				exit $INFO_CODE_TERMS_AND_CONDS_NOT_ACCEPTED;;
		* )		echo -e "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
	esac
done
echo ""

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
	echo ""
	#HAS TO BE DONE THIS WAY BECAUSE SHELL SCRIPTING SUCKS
	if [ `isMissing "$BINDIR"` == "true" ]
		then
			askForDirectoryName "Defina el directorio de instalación de los ejecutables ($GRUPO/${FORMAT_BOLD_BLUE}$BINDIR${FORMAT_DEFAULT}): "
			replaceInMissing "$BINDIR" "$DIRNAME"
			BINDIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el directorio de instalación de los ejecutables ($GRUPO/$BINDIR): $GRUPO/$BINDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	fi
	
	if [ `isMissing "$MAEDIR"` == "true" ]
		then
			askForDirectoryName "Defina directorio para maestros y tablas ($GRUPO/${FORMAT_BOLD_BLUE}$MAEDIR${FORMAT_DEFAULT}): "
			replaceInMissing "$MAEDIR" "$DIRNAME"
			MAEDIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina directorio para maestros y tablas ($MAEDIR): $MAEDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	fi
	
	if [ `isMissing "$NOVEDIR"` == "true" ]
		then
			askForDirectoryName "Defina el Directorio de arribo de novedades ($GRUPO/${FORMAT_BOLD_BLUE}$NOVEDIR${FORMAT_DEFAULT}): "
			replaceInMissing "$NOVEDIR" "$DIRNAME"
			NOVEDIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el Directorio de arribo de novedades ($NOVEDIR): $NOVEDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	
			askForSize "Defina espacio mínimo libre para el arribo de novedades en Mbytes (${FORMAT_BOLD_BLUE}$DATASIZE${FORMAT_DEFAULT}): "
			DATASIZE=$SIZE
			log "Defina espacio mínimo libre para el arribo de novedades en Mbytes ($DATASIZE): $DATASIZE" "$GRUPO/$CONFDIR/installer" "INFO"
			while [ true ]
			do
				if [ $FREESPACE -lt $DATASIZE ]
					then
						log "Insuficiente espacio en disco.\nEspacio disponible: ${FORMAT_BOLD_GREEN}$FREESPACE${FORMAT_DEFAULT} Mb.\nEspacio requerido: ${FORMAT_BOLD_RED}$DATASIZE${FORMAT_DEFAULT} Mb.\nCancele la instalación o inténtelo nuevamente." "$GRUPO/$CONFDIR/installer" "INFO" doEcho
						askForSize "Defina espacio mínimo libre para el arribo de novedades en Mbytes (${FORMAT_BOLD_BLUE}$DATASIZE${FORMAT_DEFAULT}): "
						DATASIZE=$SIZE
						log "Defina espacio mínimo libre para el arribo de novedades en Mbytes ($DATASIZE): $DATASIZE" "$GRUPO/$CONFDIR/installer" "INFO"
					else
						break
				fi
			done
	fi
	
	if [ `isMissing "$ACEPDIR"` == "true" ]
		then
			askForDirectoryName "Defina el directorio de grabación de las Novedades aceptadas ($GRUPO/${FORMAT_BOLD_BLUE}$ACEPDIR${FORMAT_DEFAULT}): "
			replaceInMissing "$ACEPDIR" "$DIRNAME"
			ACEPDIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el directorio de grabación de las Novedades aceptadas ($ACEPDIR): $ACEPDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	fi
	
	if [ `isMissing "$INFODIR"` == "true" ]
		then
			askForDirectoryName "Defina el directorio de grabación de los informes de salida ($GRUPO/${FORMAT_BOLD_BLUE}$INFODIR${FORMAT_DEFAULT}): "
			replaceInMissing "$INFODIR" "$DIRNAME"
			INFODIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el directorio de grabación de los informes de salida ($INFODIR): $INFODIR" "$GRUPO/$CONFDIR/installer" "INFO"
	fi
	
	if [ `isMissing "$RECHDIR"` == "true" ]
		then
			askForDirectoryName "Defina el directorio de grabación de Archivos rechazados ($GRUPO/${FORMAT_BOLD_BLUE}$RECHDIR${FORMAT_DEFAULT}): "
			replaceInMissing "$RECHDIR" "$DIRNAME"
			RECHDIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el directorio de grabación de Archivos rechazados ($RECHDIR): $RECHDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	fi
	
	if [ `isMissing "$LOGDIR"` == "true" ]
		then
			askForDirectoryName "Defina el directorio de logs ($GRUPO/${FORMAT_BOLD_BLUE}$LOGDIR${FORMAT_DEFAULT}): "
			replaceInMissing "$LOGDIR" "$DIRNAME"
			LOGDIR=$DIRNAME
			DIRECTORYNAMESTAKEN=("${DIRECTORYNAMESTAKEN[@]}" "$DIRNAME")
			log "Defina el directorio de logs ($LOGDIR): $LOGDIR" "$GRUPO/$CONFDIR/installer" "INFO"
	
			LOGEXT=`askUser "Ingrese la extensión para los archivos de log: (.${FORMAT_BOLD_BLUE}$LOGEXT${FORMAT_DEFAULT}): "`
			log "Ingrese la extensión para los archivos de log: (.$LOGEXT): $LOGEXT" "$GRUPO/$CONFDIR/installer" "INFO"
	
			askForSize "Defina el tamaño máximo para los archivos .${FORMAT_BOLD_BLUE}$LOGEXT${FORMAT_DEFAULT} en Kbytes (${FORMAT_BOLD_BLUE}$LOGSIZE${FORMAT_DEFAULT}): "
			LOGSIZE=$SIZE
			log "Defina el tamaño máximo para los archivos $LOGEXT en Kbytes ($LOGSIZE): $LOGSIZE" "$GRUPO/$CONFDIR/installer" "INFO"
			while [ true ]
			do
				if [ $LOGSIZE -lt $MINLOGSIZEINKB -o $LOGSIZE -gt $MAXLOGSIZEINKB ]
					then
						log "El tamaño máximo para los archivos .${FORMAT_BOLD_BLUE}$LOGEXT${FORMAT_DEFAULT} debe estar entre ${FORMAT_BOLD_GREEN}$MINLOGSIZEINKB${FORMAT_DEFAULT}  y ${FORMAT_BOLD_GREEN}$MAXLOGSIZEINKB${FORMAT_DEFAULT}. Por favor ingrese un valor en dicho rango" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
						askForSize "Defina el tamaño máximo para los archivos .${FORMAT_BOLD_BLUE}$LOGEXT${FORMAT_DEFAULT} en Kbytes (${FORMAT_BOLD_BLUE}$LOGSIZE${FORMAT_DEFAULT}): "
						LOGSIZE=$SIZE
						log "Defina el tamaño máximo para los archivos $LOGEXT en Kbytes ($LOGSIZE): $LOGSIZE" "$GRUPO/$CONFDIR/installer" "INFO"
					else
						break
				fi
			done
	fi
	echo ""
	log "$INFO_COPYRIGHT" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

	if [ ${#MISSING[@]} -eq 0 ]
		then
			log "Direct. de Configuración: ${FORMAT_BOLD_BLUE}$CONFDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$BINDIR"` == "true" ]
		then
			log "Directorio Ejecutables: ${FORMAT_BOLD_BLUE}$GRUPO/$BINDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$MAEDIR"` == "true" ]
		then
			log "Direct Maestros y Tablas: ${FORMAT_BOLD_BLUE}$GRUPO/$MAEDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$NOVEDIR"` == "true" ]
		then
			log "Directorio de Novedades: ${FORMAT_BOLD_BLUE}$GRUPO/$NOVEDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
			log "Espacio mínimo libre para arribos: ${FORMAT_BOLD_BLUE}$DATASIZE${FORMAT_DEFAULT} Mb\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$ACEPDIR"` == "true" ]
		then
			log "Dir. Novedades Aceptadas: ${FORMAT_BOLD_BLUE}$GRUPO/$ACEPDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$INFODIR"` == "true" ]
		then
			log "Dir. Informes de Salida: ${FORMAT_BOLD_BLUE}$GRUPO/$INFODIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$RECHDIR"` == "true" ]
		then
			log "Dir. Archivos Rechazados: ${FORMAT_BOLD_BLUE}$GRUPO/$RECHDIR${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	if [ `isMissing "$LOGDIR"` == "true" ]
		then
			log "Dir. de Logs de Comandos: ${FORMAT_BOLD_BLUE}$GRUPO/$LOGDIR${FORMAT_DEFAULT}/<comando>.${FORMAT_BOLD_BLUE}$LOGEXT${FORMAT_DEFAULT}\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
			log "Tamaño máximo para los archivos de log del sistema: ${FORMAT_BOLD_BLUE}$LOGSIZE${FORMAT_DEFAULT} Kb\n" "$GRUPO/$CONFDIR/installer" "INFO" doEcho
	fi

	log "$INFO_INSTALLATION_STATUS_READY" "$GRUPO/$CONFDIR/installer" "INFO" doEcho

	while [ true ];
	do
		case `askUser "$QUESTION_CONFIRM_INSTALLATION"` in
			"Si" )	CONFIRMINSTALL="true"
					break;;
			"No" )	log "El usuario decidió reingresar los nombres de directorios" "$GRUPO/$CONFDIR/installer" "INFO"
					break;;
			* )		echo -e "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
		esac
	done
done
echo ""

#UNCOMMENT FOR FINAL RELEASE
#clear

while [ true ];
do
	case `askUser "$QUESTION_START_INSTALLATION"` in
		"Si" ) 	break;;
		"No" )	log "$INFO_INSTALLATION_CANCELED_BY_USER" "$GRUPO/$CONFDIR/installer" "INFO";
				exit $INFO_CODE_INSTALLATION_CANCELED_BY_USER;;
		* ) 		echo -e "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
	esac
done
echo ""

echo -e "$TITLE_CREATING_DIRECTORY_STRUCTURE"
if [ `isMissing "$BINDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$BINDIR"
		echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$BINDIR${FORMAT_DEFAULT}"
fi

if [ `isMissing "$MAEDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$MAEDIR/precios/proc"
		echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$MAEDIR${FORMAT_DEFAULT}"
		echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$MAEDIR/precios${FORMAT_DEFAULT}"
		echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$MAEDIR/precios/proc${FORMAT_DEFAULT}"
	else
		if [ `isMissing "$MAEDIR/precios"` == "true" ]
			then
				mkdir -p "$GRUPO/$MAEDIR/precios/proc"
				echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$MAEDIR/precios${FORMAT_DEFAULT}"
				echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$MAEDIR/precios/proc${FORMAT_DEFAULT}"
			else
				if [ `isMissing "$MAEDIR/precios/proc"` == "true" ]
					then
						mkdir -p "$GRUPO/$MAEDIR/precios/proc"
						echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$MAEDIR/precios/proc${FORMAT_DEFAULT}"
				fi
		fi
fi

if [ `isMissing "$NOVEDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$NOVEDIR"
		echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$NOVEDIR${FORMAT_DEFAULT}"
fi

if [ `isMissing "$ACEPDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$ACEPDIR/proc"
		echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$ACEPDIR${FORMAT_DEFAULT}"
		echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$ACEPDIR/proc${FORMAT_DEFAULT}"
	else
		if [ `isMissing "$ACEPDIR/proc"` == "true" ]
			then
				mkdir -p "$GRUPO/$ACEPDIR/proc"
				echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$ACEPDIR/proc${FORMAT_DEFAULT}"
		fi
fi

if [ `isMissing "$INFODIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$INFODIR/pres"
		echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$INFODIR${FORMAT_DEFAULT}"
		echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$INFODIR/pres${FORMAT_DEFAULT}"
	else
		if [ `isMissing "$INFODIR/pres"` == "true" ]
			then
				mkdir -p "$GRUPO/$INFODIR/pres"
				echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$INFODIR/pres${FORMAT_DEFAULT}"
		fi
fi

if [ `isMissing "$RECHDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$RECHDIR"
		echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$RECHDIR${FORMAT_DEFAULT}"
fi

if [ `isMissing "$LOGDIR"` == "true" ]
	then
		mkdir -p "$GRUPO/$LOGDIR"
		echo -e "${FORMAT_BOLD_BLUE}$GRUPO/$LOGDIR${FORMAT_DEFAULT}"
fi
echo ""

echo -e "$TITLE_INSTALLING_MASTER_FILES_AND_TABLES"
for FILE in "$GRUPO"/datos/*.mae "$GRUPO"/datos/*.tab
do
	if [ -f "$FILE" ]
		then
			"$MOVEBIN" "$FILE" "$GRUPO/$MAEDIR"
	fi
done

echo -e "$TITLE_INSTALLING_PROGRAMS_AND_FUNCTIONS"
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

echo -e "$TITLE_UPDATING_SYSTEM_CONFIG"
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
