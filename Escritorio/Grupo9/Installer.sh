# TODO list:
#	- Optimize installed/missing components check.
#	- Optimize missing components promt to user.
#	- Complete moving all messages to variables.
#	- Complete documentation.

#System variables.
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

export LOGSIZE=15

#Other variables
minLogSizeInKb=15

maxLogSizeInKb=20

freeSpace=`df -m "$GRUPO" | tail -1 | awk '{print $4}'`

requiredDirs=("conf" "datos")

requiredScripts=("GetPID.sh" "Initializer.sh" "Listener.sh" "Logging.sh" "Masterlist.sh" "Mover.sh" "Rating.sh" "Reporting.pl" "Start.sh" "Stop.sh")

requiredDataFiles=("asociados.mae" "super.mae" "um.tab")

perlVersion=""

minPerlVersionAllowed=5

confirmInstall=false

#Global function variables
resp=""

dirName=""

size=""

prevInstallationExists=false

logBin="./Logging.sh"

moveBin="./Mover.sh"

installerLogFile="$GRUPO/$CONFDIR/Installer"

installerConfigFile="$GRUPO/$CONFDIR/Installer.conf"

installedComponents=

missingComponents=

directoryNamesTaken=

#Text format variables
boldRed="\e[1m\e[31m"
boldGreen="\e[1m\e[32m"
boldBlue="\e[1m\e[34m"
bold="\e[1m"
default="\e[0m"

#Messages
LABEL_INSTALLATION_LOG="Log de la instalación:"
LABEL_DEFAULT_CONFIG_DIR="Directorio predefinido de Configuración:"
INFO_dirName_CANNOT_BE_EMPTY="El nombre del directorio no puede ser vacío"
INFO_SIZE_MUST_BE_NUMERIC="El tamaño debe ser numérico"
INFO_INSTALLER_EXECUTION_STARTED="${bold} ============ Inicio de Ejecución de Installer ============ ${default}"
INFO_COPYRIGHT="TP SO7508 ${bold}Primer Cuatrimestre 2014${default}. Tema ${bold}C${default} Copyright © Grupo 09"
TITLE_MISSING_COMPONENTS="${boldRed}Componentes faltantes${default}:"
INFO_INSTALLATION_STATUS_READY="Estado de la instalación: ${boldBlue}LISTA${default}"
INFO_INSTALLATION_STATUS_INCOMPLETE="Estado de la instalación: ${boldRed}INCOMPLETA${default}"
INFO_INSTALLATION_STATUS_COMPLETE="Estado de la instalación: ${boldGreen}COMPLETA${default}"
INFO_INSTALLATION_CANCELED="Proceso de Instalación Cancelado"
QUESTION_COMPLETE_INSTALLATION="Desea completar la instalación? (${bold}Si${default} - ${bold}No${default}): "
INFO_INSTALLATION_CANCELED_BY_USER="Proceso de Instalación Cancelado por el usuario"
INFO_ANSWER_MUST_BE_YES_OR_NO="Por favor responda ${bold}Si${default} o ${bold}No${default}."
INFO_TERMS_AND_CONDITIONS="Al  instalar  TP  SO7508  ${bold}Primer  Cuatrimestre  2014${default} UD.  expresa  aceptar  los términos  y  condiciones  del  \"ACUERDO  DE  LICENCIA  DE  SOFTWARE\"  incluido  en este paquete."
QUESTION_ACCEPT_TERMS_AND_CONDITIONS="Acepta? (${bold}Si${default} - ${bold}No${default}): "
INFO_TERMS_AND_CONDS_NOT_ACCEPTED="El usuario no aceptó los términos y condiciones. Instalación cancelada"
INFO_PERL_VERSION="Perl version:\n`perl -v`"
QUESTION_CONFIRM_INSTALLATION="Confirma Instalación? (${bold}Si${default} - ${bold}No${default}): "
QUESTION_START_INSTALLATION="Iniciando Instalación. Esta Ud. seguro? (${bold}Si${default} -  ${bold}No${default}): "
TITLE_CREATING_DIRECTORY_STRUCTURE="Creando Estructuras de directorio. . . ."
TITLE_INSTALLING_MASTER_FILES_AND_TABLES="Instalando Archivos Maestros y Tablas"
TITLE_INSTALLING_PROGRAMS_AND_FUNCTIONS="Instalando Programas y Funciones"
TITLE_UPDATING_SYSTEM_CONFIG="Actualizando la configuración del sistema"
INFO_INSTALLATION_COMPLETE="Instalación ${boldGreen}CONCLUIDA${default}"
ERROR_REQUIRED_COMPONENTS_NOT_FOUND="${boldRed}Algunos de los componentes requeridos para la instalación no pudieron ser encontrados. Descomprimir nuevamente el archivo tar puede solucionar el problema${default}"
ERROR_INCORRECT_PERL_VERSION="$INFO_COPYRIGHT\n\nPara instalar el TP es necesario contar con Perl ${bold}$minPerlVersionAllowed o superior${default}. Efectúe su instalación e inténtelo nuevamente.\n\n$INFO_INSTALLATION_CANCELED"

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
	local found=false
	local searchFor="$1"

	for component in "${installedComponents[@]}"
	do
		if [ "$component" == "$searchFor" ]
			then
				found=true
				break
		fi
	done
	echo $found
}

function isMissing() {
	local found=false
	local searchFor="$1"

	for component in "${missingComponents[@]}"
	do
		if [ "$component" == "$searchFor" ]
			then
				found=true
				break
		fi
	done
	echo $found
}

function replaceInMissing() {
	local index=0
	local searchFor="$1"
	local replaceFor="$2"

	for component in "${missingComponents[@]}"
	do
		if [ "$component" == "$searchFor" ]
			then
				missingComponents[$index]="$replaceFor"
				break
			else
				index=$(($index + 1))
		fi
	done
}

function log() {
	local message="$1"
	local logType="$2"

	"$logBin" "$installerLogFile" "$message" "$logType"
	if [ "$3" == "doEcho" ]
		then
			echo -e $message
			echo ""
	fi
}

function askUser() {
	local message="$1"

	read -p "`echo -e -n "$message"`" resp
}

function isDirectoryNameTaken() {
	local found=false
	local dirName="$1"

	if [ -d "$GRUPO/$dirName" ]
		then
			found=true
		else
			for component in "${directoryNamesTaken[@]}"
			do
				if [ "$component" == "$dirName" ]
					then
						found=true
						break
				fi
			done
	fi
	echo $found
}

function askForDirectoryName() {
	local message="$1"
	local defaultDirName="$2"

	dirName=""
	while [ true ];
	do
		read -p "`echo -e -n "$message"`" dirName
		case $dirName in
			"$CONFDIR" | "$DATADIR" )
				echo -e "${boldBlue}$dirName${default} es un nombre de directorio reservado. Por favor elija otro nombre";;
			"" )
				dirName="$defaultDirName"
				break;;
			[[:word:][:punct:]]* )
				#if [ "$dirName" == "" ]
				#	then
				#		dirName="$defaultDirName"
				#fi
				if [ `isDirectoryNameTaken "$dirName"` == true ]
					then
						echo -e "El nombre ${boldBlue}$dirName${default} ya existe o fue seleccionado para otro directorio. Por favor elija otro nombre";
					else
						break
				fi;;
			* )
				echo -e "${boldRed}Datos ingresados invalidos, por favor intente de nuevo.${default}";;
		esac
	done
}

function askForSize() {
	local message="$1"
	local defaultSize=$2

	size=""
	while [ true ];
	do
		read -p "`echo -e -n "$message"`" size
		if [ "$size" == "" ]
			then
				size=$defaultSize
				break
			else
				if [ "$(echo $size | grep "^[ [:digit:] ]*$")" ] 
					then 
						break
					else
						echo "$INFO_SIZE_MUST_BE_NUMERIC"
				fi
		fi			
	done
}

function printFilesInDir() {
	local dirName="$1"

	for file in "$dirName"/*
	do
		if [ -f "$file" ]
			then
				echo "\n\t${file##*/}"
		fi
	done
}

function readConf() {
	local propertyName=""
	local propertyValue=""

	exec 3< "$installerConfigFile"
	while read line
	do
		propertyName=`echo $line | cut -f1 -d"="`
		propertyValue=`echo $line | cut -f2 -d"="`

		case "$propertyName" in
			"BINDIR")
				BINDIR="$propertyValue";;
			"MAEDIR")
				MAEDIR="$propertyValue";;
			"NOVEDIR")
				NOVEDIR="$propertyValue";;
			"DATASIZE")
				DATASIZE="$propertyValue";;
			"ACEPDIR")
				ACEPDIR="$propertyValue";;
			"INFODIR")
				INFODIR="$propertyValue";;
			"RECHDIR")
				RECHDIR="$propertyValue";;
			"LOGDIR")
				LOGDIR="$propertyValue";;
			"LOGEXT")
				LOGEXT="$propertyValue";;
			"LOGSIZE")
				LOGSIZE="$propertyValue";;
		esac
	done <&3

	exec 3<&-
}

function initialize() {
	local value=""

	#Checking for required dirs.
	for requiredDir in "${requiredDirs[@]}"
	do
		if [ ! -d "$requiredDir" ]
			then
				echo -e "$ERROR_REQUIRED_COMPONENTS_NOT_FOUND"
				exit $ERROR_CODE_REQUIRED_COMPONENTS_NOT_FOUND
		fi
	done

	#Checking if there is a previous installation of the system. 
	if [ -f "$installerConfigFile" ];
		then
			prevInstallationExists=true

			readConf
	fi

	#Checking for required scripts
	for requiredScript in "${requiredScripts[@]}"
	do
		if ! [[ -f "$requiredScript" || -f "$BINDIR/$requiredScript" ]]
			then
				echo -e "$ERROR_REQUIRED_COMPONENTS_NOT_FOUND"
				exit $ERROR_CODE_REQUIRED_COMPONENTS_NOT_FOUND
		fi
	done

	#Checking for required data files
	for requiredDataFile in "${requiredDataFiles[@]}"
	do
		if ! [[ -f "datos/$requiredDataFile" || -f "$MAEDIR/$requiredDataFile" ]]
			then
				echo -e "$ERROR_REQUIRED_COMPONENTS_NOT_FOUND"
				exit $ERROR_CODE_REQUIRED_COMPONENTS_NOT_FOUND
		fi
	done

	#Seting path and execution permissions for Logging and Move scripts. 
	if [ ! -f "$logBin" ]
		then
			logBin="$GRUPO/$BINDIR/Logging.sh"
	fi

	if [ ! -f "$moveBin" ]
		then
			moveBin="$GRUPO/$BINDIR/Mover.sh"
	fi

	chmod +x "$logBin"
	
	chmod +x "$moveBin"
}

function checkInstalledComponents() {
	unset installedComponents
	
	unset missingComponents
	
	if [ ! -d "$GRUPO/$BINDIR" ]
		then
			missingComponents=("${missingComponents[@]}" "$BINDIR")
		else
			installedComponents=("${installedComponents[@]}" "$BINDIR")
	fi
	for script in "${requiredScripts[@]}"
	do
		if [ ! -f "$GRUPO/$BINDIR/$script" ]
			then
				missingComponents=("${missingComponents[@]}" "$script")
		fi
	done

	if [ ! -d "$GRUPO/$MAEDIR" ]
		then
			missingComponents=("${missingComponents[@]}" "$MAEDIR")
		else
			installedComponents=("${installedComponents[@]}" "$MAEDIR")
	fi
	if [ ! -d "$GRUPO/$MAEDIR/precios" ]
		then
			missingComponents=("${missingComponents[@]}" "$MAEDIR/precios")
	fi
	if [ ! -d "$GRUPO/$MAEDIR/precios/proc" ]
		then
			missingComponents=("${missingComponents[@]}" "$MAEDIR/precios/proc")
	fi
	for dataFile in "${requiredDataFiles[@]}"
	do
		if [ ! -f "$GRUPO/$MAEDIR/$dataFile" ]
			then
		missingComponents=("${missingComponents[@]}" "$dataFile")
		fi
	done

	if [ ! -d "$GRUPO/$NOVEDIR" ]
		then
			missingComponents=("${missingComponents[@]}" "$NOVEDIR")
		else
			installedComponents=("${installedComponents[@]}" "$NOVEDIR")
	fi
	
	if [ ! -d "$GRUPO/$ACEPDIR" ]
		then
			missingComponents=("${missingComponents[@]}" "$ACEPDIR")
		else
			installedComponents=("${installedComponents[@]}" "$ACEPDIR")
	fi
	if [ ! -d "$GRUPO/$ACEPDIR/proc" ]
		then
			missingComponents=("${missingComponents[@]}" "$ACEPDIR/proc")
	fi

	if [ ! -d "$GRUPO/$INFODIR" ]
		then
			missingComponents=("${missingComponents[@]}" "$INFODIR")
		else
			installedComponents=("${installedComponents[@]}" "$INFODIR")
	fi
	if [ ! -d "$GRUPO/$INFODIR/pres" ]
		then
			missingComponents=("${missingComponents[@]}" "$INFODIR/pres")
	fi

	if [ ! -d "$GRUPO/$RECHDIR" ]
		then
			missingComponents=("${missingComponents[@]}" "$RECHDIR")
		else
			installedComponents=("${installedComponents[@]}" "$RECHDIR")
	fi
	
	if [ ! -d "$GRUPO/$LOGDIR" ]
		then
			missingComponents=("${missingComponents[@]}" "$LOGDIR")
		else
			installedComponents=("${installedComponents[@]}" "$LOGDIR")
	fi
}

function printInstallationStatus() {

	log "Direct. de Configuracion: ${boldGreen}$GRUPO/$CONFDIR${default}${bold}
	`printFilesInDir "$GRUPO/$CONFDIR"`
	${default}" "INFO" doEcho
	if [ `isInstalled "$BINDIR"` == true ]
		then
			log "Directorio  Ejecutables: ${boldGreen}$GRUPO/$BINDIR${default}${bold}
			`printFilesInDir "$GRUPO/$BINDIR"`
			${default}" "INFO" doEcho
	fi

	if [ `isInstalled "$MAEDIR"` == true ]
		then
			log "Direct Maestros y Tablas: ${boldGreen}$GRUPO/$MAEDIR${default}${bold}
			`printFilesInDir "$GRUPO/$MAEDIR"`
			${default}" "INFO" doEcho
	fi

	if [ `isInstalled "$NOVEDIR"` == true ]
		then
			log "Directorio de Novedades: ${boldGreen}$GRUPO/$NOVEDIR${default}" "INFO" doEcho
	fi

	if [ `isInstalled "$ACEPDIR"` == true ]
		then
			log "Dir. Novedades Aceptadas: ${boldGreen}$GRUPO/$ACEPDIR${default}" "INFO" doEcho
	fi

	if [ `isInstalled "$INFODIR"` == true ]
		then
			log "Dir. Informes de Salida: ${boldGreen}$GRUPO/$INFODIR${default}" "INFO" doEcho
	fi

	if [ `isInstalled "$RECHDIR"` == true ]
		then
			log "Dir. Archivos Rechazados: ${boldGreen}$GRUPO/$RECHDIR${default}" "INFO" doEcho
	fi

	if [ `isInstalled "$LOGDIR"` == true ]
		then
			log "Dir. de Logs de Comandos: ${boldGreen}$GRUPO/$LOGDIR${default}/<comando>.${boldGreen}$LOGEXT${default}" "INFO" doEcho
	fi

	if [ ! ${#missingComponents[@]} -eq 0 ]
		then

			log "$TITLE_MISSING_COMPONENTS" "INFO" doEcho

			if [ `isMissing "$BINDIR"` == true ]
				then
					log "Directorio Ejecutables: ${boldRed}$GRUPO/$BINDIR${default}" "INFO" doEcho
			fi

			for script in "${requiredScripts[@]}"
			do
				if [ `isMissing "$script"` == true ]
				then
					log "Programa o función: ${boldRed}$GRUPO/$BINDIR/$script${default}" "INFO" doEcho
				fi
			done

			if [ `isMissing "$MAEDIR"` == true ]
				then
					log "Direct Maestros y Tablas: ${boldRed}$GRUPO/$MAEDIR${default}" "INFO" doEcho
			fi

			if [ `isMissing "$MAEDIR/precios"` == true ]
				then
					log "Subdirectorio del Direct Maestros y Tablas: ${boldRed}$GRUPO/$MAEDIR/precios${default}" "INFO" doEcho
			fi

			if [ `isMissing "$MAEDIR/precios/proc"` == true ]
				then
					log "Subdirectorio del Direct Maestros y Tablas: ${boldRed}$GRUPO/$MAEDIR/precios/proc${default}" "INFO" doEcho
			fi

			for dataFile in "${requiredDataFiles[@]}"
			do
				if [ `isMissing "$dataFile"` == true ]
				then
					log "Archivo maestro o tabla: ${boldRed}$GRUPO/$MAEDIR/$dataFile${default}" "INFO" doEcho
				fi
			done

			if [ `isMissing "$NOVEDIR"` == true ]
				then
					log "Directorio de Novedades: ${boldRed}$GRUPO/$NOVEDIR${default}" "INFO" doEcho
			fi

			if [ `isMissing "$ACEPDIR"` == true ]
				then
					log "Dir. Novedades Aceptadas: ${boldRed}$GRUPO/$ACEPDIR${default}" "INFO" doEcho
			fi

			if [ `isMissing "$ACEPDIR/proc"` == true ]
				then
					log "Subdirectorio del Dir. Novedades Aceptadas: ${boldRed}$GRUPO/$ACEPDIR/proc${default}" "INFO" doEcho
			fi

			if [ `isMissing "$INFODIR"` == true ]
				then
					log "Dir. Informes de Salida: ${boldRed}$GRUPO/$INFODIR${default}" "INFO" doEcho
			fi

			if [ `isMissing "$INFODIR/pres"` == true ]
				then
					log "Subdirectorio del Dir. Informes de Salida: ${boldRed}$GRUPO/$INFODIR/pres${default}" "INFO" doEcho
			fi

			if [ `isMissing "$RECHDIR"` == true ]
				then
					log "Dir. Archivos Rechazados: ${boldRed}$GRUPO/$RECHDIR${default}" "INFO" doEcho
			fi

			if [ `isMissing "$LOGDIR"` == true ]
				then
					log "Dir. de Logs de Comandos: ${boldRed}$GRUPO/$LOGDIR/${default}" "INFO" doEcho
			fi

			log "$INFO_INSTALLATION_STATUS_INCOMPLETE" "INFO" doEcho

			while [ true ];
			do
				askUser "$QUESTION_COMPLETE_INSTALLATION"
				case $resp in
					"Si" )
						break;;
					"No" )
						log "$INFO_INSTALLATION_CANCELED_BY_USER" "INFO" doEcho
						exit $INFO_CODE_INSTALLATION_CANCELED_BY_USER;;
					* )
						echo -e "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
				esac
			done
		else
			log "$INFO_INSTALLATION_STATUS_COMPLETE" "INFO" doEcho

			log "$INFO_INSTALLATION_CANCELED" "INFO" doEcho

			exit $INFO_CODE_INSTALLATION_CANCELED
	fi
}

function checkTermsAndConditions() {
	echo -e "$INFO_TERMS_AND_CONDITIONS"
	echo ""

	while [ true ];
	do
		askUser "$QUESTION_ACCEPT_TERMS_AND_CONDITIONS"
		case $resp in
			"Si" )
				break;;
			"No" )
				log "$INFO_TERMS_AND_CONDS_NOT_ACCEPTED" "INFO"
				exit $INFO_CODE_TERMS_AND_CONDS_NOT_ACCEPTED;;
			* )
				echo -e "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
		esac
	done
}

function checkPerlVersion() {
	perlVersion=`perl --version | grep v`
	perlVersion=${perlVersion:15:1}
	
	if [ $perlVersion -lt $minPerlVersionAllowed ]
		then
			log "$ERROR_INCORRECT_PERL_VERSION" "ERR" doEcho
			exit $ERROR_CODE_INCORRECT_PERL_VERSION
		else
			log "$INFO_COPYRIGHT" "INFO" doEcho
			log "$INFO_PERL_VERSION" "INFO" doEcho
	fi
}

function getDirectoryNames() {
	local userEnteredDirNames=false

	while [ "$confirmInstall" == false ]
	do
		unset directoryNamesTaken
		if [ `isMissing "$BINDIR"` == true ]
			then
				userEnteredDirNames=true
				askForDirectoryName "Defina el directorio de instalación de los ejecutables ($GRUPO/${boldBlue}$BINDIR${default}): " "$BINDIR"
				replaceInMissing "$BINDIR" "$dirName"
				BINDIR=$dirName
				directoryNamesTaken=("${directoryNamesTaken[@]}" "$dirName")
				log "Defina el directorio de instalación de los ejecutables ($GRUPO/${boldBlue}$BINDIR${default}): ${bold}$GRUPO/$BINDIR${default}" "INFO"
		fi
		
		if [ `isMissing "$MAEDIR"` == true ]
			then
				userEnteredDirNames=true
				askForDirectoryName "Defina directorio para maestros y tablas ($GRUPO/${boldBlue}$MAEDIR${default}): " "$MAEDIR"
				replaceInMissing "$MAEDIR" "$dirName"
				replaceInMissing "$MAEDIR/precios" "$dirName/precios"
				replaceInMissing "$MAEDIR/precios/proc" "$dirName/precios/proc"
				MAEDIR=$dirName
				directoryNamesTaken=("${directoryNamesTaken[@]}" "$dirName")
				log "Defina directorio para maestros y tablas ($GRUPO/${boldBlue}$MAEDIR${default}): ${bold}$MAEDIR${default}" "INFO"
		fi
		
		if [ `isMissing "$NOVEDIR"` == true ]
			then
				userEnteredDirNames=true
				askForDirectoryName "Defina el Directorio de arribo de novedades ($GRUPO/${boldBlue}$NOVEDIR${default}): " "$NOVEDIR"
				replaceInMissing "$NOVEDIR" "$dirName"
				NOVEDIR=$dirName
				directoryNamesTaken=("${directoryNamesTaken[@]}" "$dirName")
				log "Defina el Directorio de arribo de novedades ($GRUPO/${boldBlue}$NOVEDIR${default}): ${bold}$NOVEDIR${default}" "INFO"
		
				askForSize "Defina espacio mínimo libre para el arribo de novedades en Mbytes (${boldBlue}$DATASIZE${default}): " "$DATASIZE"
				log "Defina espacio mínimo libre para el arribo de novedades en Mbytes (${boldBlue}$DATASIZE${default}): ${bold}$size${default}" "INFO"
				while [ true ]
				do
					if [ $freeSpace -lt $size ]
						then
							log "\nInsuficiente espacio en disco.\nEspacio disponible: ${boldGreen}$freeSpace${default} Mb.\nEspacio requerido: ${boldRed}$size${default} Mb.\nCancele la instalación o inténtelo nuevamente." "INFO" doEcho
							askForSize "Defina espacio mínimo libre para el arribo de novedades en Mbytes (${boldBlue}$DATASIZE${default}): " "$DATASIZE"
							log "Defina espacio mínimo libre para el arribo de novedades en Mbytes (${boldBlue}$DATASIZE${default}): ${bold}$size${default}" "INFO"
						else
							if [ $size -gt 0 ]
								then
									DATASIZE=$size
									break
								else
									log "\nEl tamaño elegido debe ser mayor que ${boldBlue}0${default} Mb.\nCancele la instalación o inténtelo nuevamente." "INFO" doEcho
									askForSize "Defina espacio mínimo libre para el arribo de novedades en Mbytes (${boldBlue}$DATASIZE${default}): " "$DATASIZE"
									log "Defina espacio mínimo libre para el arribo de novedades en Mbytes (${boldBlue}$DATASIZE${default}): ${bold}$size${default}" "INFO"
							fi
					fi
				done
		fi
		
		if [ `isMissing "$ACEPDIR"` == true ]
			then
				userEnteredDirNames=true
				askForDirectoryName "Defina el directorio de grabación de las Novedades aceptadas ($GRUPO/${boldBlue}$ACEPDIR${default}): " "$ACEPDIR"
				replaceInMissing "$ACEPDIR" "$dirName"
				replaceInMissing "$ACEPDIR/proc" "$dirName/proc"
				ACEPDIR=$dirName
				directoryNamesTaken=("${directoryNamesTaken[@]}" "$dirName")
				log "Defina el directorio de grabación de las Novedades aceptadas ($GRUPO/${boldBlue}$ACEPDIR${default}): ${bold}$ACEPDIR${default}" "INFO"
		fi
		
		if [ `isMissing "$INFODIR"` == true ]
			then
				userEnteredDirNames=true
				askForDirectoryName "Defina el directorio de grabación de los informes de salida ($GRUPO/${boldBlue}$INFODIR${default}): " "$INFODIR"
				replaceInMissing "$INFODIR" "$dirName"
				replaceInMissing "$INFODIR/pres" "$dirName/pres"
				INFODIR=$dirName
				directoryNamesTaken=("${directoryNamesTaken[@]}" "$dirName")
				log "Defina el directorio de grabación de los informes de salida ($GRUPO/${boldBlue}$INFODIR${default}): ${bold}$INFODIR${default}" "INFO"
		fi
		
		if [ `isMissing "$RECHDIR"` == true ]
			then
				userEnteredDirNames=true
				askForDirectoryName "Defina el directorio de grabación de Archivos rechazados ($GRUPO/${boldBlue}$RECHDIR${default}): " "$RECHDIR"
				replaceInMissing "$RECHDIR" "$dirName"
				RECHDIR=$dirName
				directoryNamesTaken=("${directoryNamesTaken[@]}" "$dirName")
				log "Defina el directorio de grabación de Archivos rechazados ($GRUPO/${boldBlue}$RECHDIR${default}): ${bold}$RECHDIR${default}" "INFO"
		fi
		
		if [ `isMissing "$LOGDIR"` == true ]
			then
				userEnteredDirNames=true
				askForDirectoryName "Defina el directorio de logs ($GRUPO/${boldBlue}$LOGDIR${default}): " "$LOGDIR"
				replaceInMissing "$LOGDIR" "$dirName"
				LOGDIR=$dirName
				directoryNamesTaken=("${directoryNamesTaken[@]}" "$dirName")
				log "Defina el directorio de logs ($GRUPO/${boldBlue}$LOGDIR${default}): ${bold}$LOGDIR${default}" "INFO"
	
				askUser "Ingrese la extensión para los archivos de log: (.${boldBlue}$LOGEXT${default}): "
				if [ "$resp" == "" ]
					then
						LOGEXT=$LOGEXT
					else
						LOGEXT=$resp
				fi
	
				log "Ingrese la extensión para los archivos de log: (.${boldBlue}$LOGEXT${default}): ${bold}$LOGEXT${default}" "INFO"
		
				askForSize "Defina el tamaño máximo para los archivos .${boldBlue}$LOGEXT${default} en Kbytes (${boldBlue}$LOGSIZE${default}): " "$LOGSIZE"
				log "Defina el tamaño máximo para los archivos .${boldBlue}$LOGEXT${default} en Kbytes (${boldBlue}$LOGSIZE${default}): ${bold}$size${default}" "INFO"
				while [ true ]
				do
					if [ $size -lt $minLogSizeInKb -o $size -gt $maxLogSizeInKb ]
						then
							log "\nEl tamaño máximo para los archivos .${boldBlue}$LOGEXT${default} debe estar entre ${boldGreen}$minLogSizeInKb${default}  y ${boldGreen}$maxLogSizeInKb${default}. Por favor ingrese un valor en dicho rango" "INFO" doEcho
							askForSize "Defina el tamaño máximo para los archivos .${boldBlue}$LOGEXT${default} en Kbytes (${boldBlue}$LOGSIZE${default}): " "$LOGSIZE"
							log "Defina el tamaño máximo para los archivos .${boldBlue}$LOGEXT${default} en Kbytes (${boldBlue}$LOGSIZE${default}): ${bold}$size${default}" "INFO"
						else
							LOGSIZE=$size
							break
					fi
				done
		fi
		echo ""
		log "$INFO_COPYRIGHT" "INFO" doEcho
	
		if [ ${#missingComponents[@]} -eq 0 ]
			then
				log "Direct. de Configuración: ${boldBlue}$CONFDIR${default}" "INFO" doEcho
		fi
	
		if [ `isMissing "$BINDIR"` == true ]
			then
				log "Directorio Ejecutables: ${boldBlue}$GRUPO/$BINDIR${default}" "INFO" doEcho
		fi

		if [ "$prevInstallationExists" == true ]
			then
				for script in "${requiredScripts[@]}"
				do
					if [ `isMissing "$script"` == true ]
						then
							log "Programa o función: ${boldBlue}$GRUPO/$BINDIR/$script${default}" "INFO" doEcho
					fi
				done
		fi
	
		if [ `isMissing "$MAEDIR"` == true ]
			then
				log "Direct Maestros y Tablas: ${boldBlue}$GRUPO/$MAEDIR${default}" "INFO" doEcho
		fi

		if [ "$prevInstallationExists" == true ]
			then
				if [ `isMissing "$MAEDIR/precios"` == true ]
					then
						log "Subdirectorio del Direct Maestros y Tablas: ${boldBlue}$GRUPO/$MAEDIR/precios${default}" "INFO" doEcho
				fi
		
				if [ `isMissing "$MAEDIR/precios/proc"` == true ]
					then
						log "Subdirectorio del Direct Maestros y Tablas: ${boldBlue}$GRUPO/$MAEDIR/precios/proc${default}" "INFO" doEcho
				fi
		
				for dataFile in "${requiredDataFiles[@]}"
				do
					if [ `isMissing "$dataFile"` == true ]
						then
							log "Archivo maestro o tabla: ${boldBlue}$GRUPO/$MAEDIR/$dataFile${default}" "INFO" doEcho
					fi
				done
		fi

		if [ `isMissing "$NOVEDIR"` == true ]
			then
				log "Directorio de Novedades: ${boldBlue}$GRUPO/$NOVEDIR${default}" "INFO" doEcho
				log "Espacio mínimo libre para arribos: ${boldBlue}$DATASIZE${default} Mb" "INFO" doEcho
		fi
	
		if [ `isMissing "$ACEPDIR"` == true ]
			then
				log "Dir. Novedades Aceptadas: ${boldBlue}$GRUPO/$ACEPDIR${default}" "INFO" doEcho
		fi

		if [ "$prevInstallationExists" == true ]
			then
				if [ `isMissing "$ACEPDIR/proc"` == true ]
					then
						log "Subdirectorio del Dir. Novedades Aceptadas: ${boldBlue}$GRUPO/$ACEPDIR/proc${default}" "INFO" doEcho
				fi
		fi

		if [ `isMissing "$INFODIR"` == true ]
			then
				log "Dir. Informes de Salida: ${boldBlue}$GRUPO/$INFODIR${default}" "INFO" doEcho
		fi

		if [ "$prevInstallationExists" == true ]
			then
				if [ `isMissing "$INFODIR/pres"` == true ]
					then
						log "Subdirectorio del Dir. Informes de Salida: ${boldBlue}$GRUPO/$INFODIR/pres${default}" "INFO" doEcho
				fi
		fi
	
		if [ `isMissing "$RECHDIR"` == true ]
			then
				log "Dir. Archivos Rechazados: ${boldBlue}$GRUPO/$RECHDIR${default}" "INFO" doEcho
		fi
	
		if [ `isMissing "$LOGDIR"` == true ]
			then
				log "Dir. de Logs de Comandos: ${boldBlue}$GRUPO/$LOGDIR${default}/<comando>.${boldBlue}$LOGEXT${default}" "INFO" doEcho
				log "Tamaño máximo para los archivos de log del sistema: ${boldBlue}$LOGSIZE${default} Kb" "INFO" doEcho
		fi
	
		log "$INFO_INSTALLATION_STATUS_READY" "INFO" doEcho
	
		while [ true ];
		do
			askUser "$QUESTION_CONFIRM_INSTALLATION"
			case $resp in
				"Si" )
					confirmInstall=true
					break;;
				"No" )
					if [ "$userEnteredDirNames" == false ]
						then
							log "$INFO_INSTALLATION_CANCELED_BY_USER" "INFO"
							exit $INFO_CODE_INSTALLATION_CANCELED_BY_USER
					fi
					log "El usuario decidió reingresar los nombres de directorios" "INFO"
					clear
					break;;
				* )
					echo -e "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
			esac
		done
	done
}

function confirmInstallation() {
	while [ true ];
	do
		askUser "$QUESTION_START_INSTALLATION"
		case $resp in
			"Si" )
				break;;
			"No" )
				log "$INFO_INSTALLATION_CANCELED_BY_USER" "INFO"
				exit $INFO_CODE_INSTALLATION_CANCELED_BY_USER;;
			* )
				echo -e "$INFO_ANSWER_MUST_BE_YES_OR_NO";;
			esac
	done
}

function createDirectories() {
	echo -e "$TITLE_CREATING_DIRECTORY_STRUCTURE\n"

	if [ `isMissing "$BINDIR"` == true ]
		then
			mkdir -p "$GRUPO/$BINDIR"
			echo -e "${boldBlue}$GRUPO/$BINDIR${default}"
	fi
	
	if [ `isMissing "$MAEDIR"` == true ]
		then
			mkdir -p "$GRUPO/$MAEDIR/precios/proc"
			echo -e "${boldBlue}$GRUPO/$MAEDIR${default}"
			echo -e "${boldBlue}$GRUPO/$MAEDIR/precios${default}"
			echo -e "${boldBlue}$GRUPO/$MAEDIR/precios/proc${default}"
		else
			if [ `isMissing "$MAEDIR/precios"` == true ]
				then
					mkdir -p "$GRUPO/$MAEDIR/precios/proc"
					echo -e "${boldBlue}$GRUPO/$MAEDIR/precios${default}"
					echo -e "${boldBlue}$GRUPO/$MAEDIR/precios/proc${default}"
				else
					if [ `isMissing "$MAEDIR/precios/proc"` == true ]
						then
							mkdir -p "$GRUPO/$MAEDIR/precios/proc"
							echo -e "${boldBlue}$GRUPO/$MAEDIR/precios/proc${default}"
					fi
			fi
	fi
	
	if [ `isMissing "$NOVEDIR"` == true ]
		then
			mkdir -p "$GRUPO/$NOVEDIR"
			echo -e "${boldBlue}$GRUPO/$NOVEDIR${default}"
	fi
	
	if [ `isMissing "$ACEPDIR"` == true ]
		then
			mkdir -p "$GRUPO/$ACEPDIR/proc"
			echo -e "${boldBlue}$GRUPO/$ACEPDIR${default}"
			echo -e "${boldBlue}$GRUPO/$ACEPDIR/proc${default}"
		else
			if [ `isMissing "$ACEPDIR/proc"` == true ]
				then
					mkdir -p "$GRUPO/$ACEPDIR/proc"
					echo -e "${boldBlue}$GRUPO/$ACEPDIR/proc${default}"
			fi
	fi
	
	if [ `isMissing "$INFODIR"` == true ]
		then
			mkdir -p "$GRUPO/$INFODIR/pres"
			echo -e "${boldBlue}$GRUPO/$INFODIR${default}"
			echo -e "${boldBlue}$GRUPO/$INFODIR/pres${default}"
		else
			if [ `isMissing "$INFODIR/pres"` == true ]
				then
					mkdir -p "$GRUPO/$INFODIR/pres"
					echo -e "${boldBlue}$GRUPO/$INFODIR/pres${default}"
			fi
	fi
	
	if [ `isMissing "$RECHDIR"` == true ]
		then
			mkdir -p "$GRUPO/$RECHDIR"
			echo -e "${boldBlue}$GRUPO/$RECHDIR${default}"
	fi
	
	if [ `isMissing "$LOGDIR"` == true ]
		then
			mkdir -p "$GRUPO/$LOGDIR"
			echo -e "${boldBlue}$GRUPO/$LOGDIR${default}"
	fi

	echo ""
}

function moveFiles() {
	echo -e "$TITLE_INSTALLING_MASTER_FILES_AND_TABLES\n"

	for dataFile in "${requiredDataFiles[@]}"
	do
		if [ -f "datos/$dataFile" ]
			then
				"$moveBin" "$GRUPO/datos/$dataFile" "$GRUPO/$MAEDIR"
		fi
	done

	echo -e "$TITLE_INSTALLING_PROGRAMS_AND_FUNCTIONS\n"

	for script in "${requiredScripts[@]}"
	do
		if [ -f "$script" -a "${script##*/}" != "Mover.sh" ]
			then
				"$moveBin" "$GRUPO/$script" "$GRUPO/$BINDIR"
		fi
	done

	"$moveBin" "$moveBin" "$GRUPO/$BINDIR"

	logBin="$GRUPO/$BINDIR/Logging.sh"
}

function updateConfig() {
	echo -e "$TITLE_UPDATING_SYSTEM_CONFIG\n"
	echo "GRUPO=$GRUPO=`timeStamp`" > "$installerConfigFile"
	echo "CONFDIR=$CONFDIR=$USER=`timeStamp`" >> "$installerConfigFile"
	echo "BINDIR=$BINDIR=$USER=`timeStamp`" >> "$installerConfigFile"
	echo "MAEDIR=$MAEDIR=$USER=`timeStamp`" >> "$installerConfigFile"
	echo "NOVEDIR=$NOVEDIR=$USER=`timeStamp`" >> "$installerConfigFile"
	echo "DATASIZE=$DATASIZE=$USER=`timeStamp`" >> "$installerConfigFile"
	echo "ACEPDIR=$ACEPDIR=$USER=`timeStamp`" >> "$installerConfigFile"
	echo "INFODIR=$INFODIR=$USER=`timeStamp`" >> "$installerConfigFile"
	echo "RECHDIR=$RECHDIR=$USER=`timeStamp`" >> "$installerConfigFile"
	echo "LOGDIR=$LOGDIR=$USER=`timeStamp`" >> "$installerConfigFile"
	echo "LOGEXT=$LOGEXT=$USER=`timeStamp`" >> "$installerConfigFile"
	echo "LOGSIZE=$LOGSIZE=$USER=`timeStamp`" >> "$installerConfigFile"
	echo "NUMSEC=0=$USER=`timeStamp`" >> "$installerConfigFile"
}

# ============================== Main ========================================
initialize

log "$INFO_INSTALLER_EXECUTION_STARTED" "INFO"

log "$LABEL_INSTALLATION_LOG ${boldGreen}$installerLogFile.log${default}" "INFO" doEcho

log "$LABEL_DEFAULT_CONFIG_DIR ${boldGreen}$GRUPO/$CONFDIR${default}" "INFO" doEcho

checkInstalledComponents

log "$INFO_COPYRIGHT" "INFO" doEcho

if [ "$prevInstallationExists" == true ]
	then
		printInstallationStatus
fi

checkTermsAndConditions

echo ""

checkPerlVersion

getDirectoryNames

echo ""

confirmInstallation

clear

createDirectories

moveFiles

updateConfig

log "$INFO_INSTALLATION_COMPLETE" "INFO" doEcho

chmod +x "$GRUPO/$BINDIR/Initializer.sh"

chmod +x "$GRUPO/ViewLog.sh"

exit $SUCCESS
