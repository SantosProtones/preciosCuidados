#!/bin/bash
# Comando Rating
# Autor: Cristian Delle Piane (86450)
# Fecha: 27 - 04 - 2014
# Version: 1.0
# Materia: 75.08 - Sistemas Operativos
# 
# Calculo de Presupuestos
# Input
# 	Archivo de listas de compras aceptadas en $ACEPDIR/usuario.xxx
# 	Lista maestra de precios $MAEDIR/precio.mae
# 	Tabla de equivalencias de unidades de medida $MAEDIR/um.tab
#
# Output
#	Archivos de listas presupuestadas $INFODIR/pres/usuario.xxx
#	Archivos de listas de compras procesadas $ACEPDIR/proc/usuario.xxx
#	Archivos rechazados $RECHDIR/usuario.xxx
# 	Log $LOGDIR/Rating.$LOGEXT
#
# -----------------------Definicion de constantes---------------------------
MLOGINI1="Inicio de Rating"
MLOGINI2="Cantidad de listas de compras a procesar: "
MLOGFIN="Fin de Rating"
MPROC="Archivo a procesar: "
MERRGEN="Se rechaza el archivo"
MERRDUP="por estar DUPLICADO"
MERRINV="por formato INVALIDO"
MERRVAC="por estar vacio"
FLPMAE="precios.mae"
TABEQU="um.tab"
COMANDO="Rating"

# -----------------------Declaracion de Funciones---------------------------
# Funcion. ValidarParametros
# Parametros. $1 (ruta de aceptados) $2 (ruta de maestro) 
# $3 (ruta de informacion) $4 (ruta de rechazados)
# Objetivo. Validar que los parametros necesarios esten informados y sean
# validos.
 
function ValidarParametros () {
    local RTA=0
    local MENSERR=""
    # Valido que los parametros esten informados
    if [ -z "$1" ]; then
        MENSERR="Parametro 1 no esta informado. Valor: $1"
        RTA=1 
    fi
    
    if [ -z "$2" ]; then
        MENSERR="Parametro 2 no esta informado. Valor: $2"
        RTA=1 
    fi

    if [ -z "$3" ]; then
        MENSERR="Parametro 3 no esta informado. Valor: $3"
        RTA=1 
    fi

    if [ -z "$4" ]; then
        MENSERR="Parametro 4 no esta informado. Valor: $4"
        RTA=1 
    fi

    # Valido que los directorios sean validos
    if ! [ -d "$1" ]; then 
        MENSERR="Parametro 1 no es un directorio valido. Valor: $1"
        RTA=2 
    fi
    
    if ! [ -d "$1/proc" ]; then 
        MENSERR="Directorio "$1/proc" inexistente"
        RTA=2 
    fi
    
    if ! [ -d "$2" ]; then 
        MENSERR="Parametro 2 no es un directorio valido. Valor: $2"
        RTA=2 
    fi
    
    if ! [ -d "$3" ]; then 
        MENSERR="Parametro 3 no es un directorio valido. Valor: $3"
        RTA=2 
    fi
    
    if ! [ -d "$3/pres" ]; then 
        MENSERR="Directorio "$3/pres" inexistente"
        RTA=2 
    fi
    
    if ! [ -d "$4" ]; then 
        MENSERR="Parametro 4 no es un directorio valido. Valor: $4"
        RTA=2 
    fi
    
    echo $MENSERR
    return $RTA
}

# Funcion. ContarArchivos
# Parametros. $1 (directorio)
# Objetivo. Contar la cantidad de archivos existentes en el directorio 
# indicado para la extension indicada
 
function ContarArchivos () {
    local NUMACEP=0
    NUMACEP=`ls "$1/" -1 -F | grep -e "[^/]$" | wc -l`
    echo $NUMACEP
}

# Funcion. ExisteArchivo
# Parametros. $1 (nombre archivo) $2 (directorio a verificar)
# Objetivo. Verificar la existencia del archivo en el directorio indicado
 
function ExisteArchivo () {
    # Tomo el nombre del archivo de la ruta actual
    local NUMARCH=`find "$2" -name "$1" | wc -l`
    if [ $NUMARCH -eq 0 ]; then
       return 1
    fi
    return 0
}

# Funcion. ExisteUnidad
# Parametros. $1 (unidad)
# Objetivo. Verificar la existencia de la unidad indicada en el archivo de
# equivalencias y devuelve el numero de linea donde esta la unidad y sus
# equivalencias.
 
function ExisteUnidad () {
    local NUMREG=0
    local EXISTE=0
    # busco la unidad en el fichero de equivalencias
    for REG in ${VREGUNIDS[*]}
    do	
	    NUMREG=`expr $NUMREG + 1`
	    local COUNT=`echo $REG | grep -i -w -c "$1"`
        if [ $COUNT -ne 0 ]; then
	        EXISTE=$NUMREG
	        break
        fi
    done
    return $EXISTE
}

# Funcion. PresupuestarPedido
# Parametros. $1 (item-produto a comprar) $2 (archivo lista de precios) 
# $3 (archivo donde se almacenan) $4 (unidad a comprar)
# $5 (posicion de la unidad a comprar en equivalencias) 
# Objetivo. Obtener los precios y nombres de productos que se corresponden  
# con el producto indicado, almacenando los datos en $3
 
function PresupuestarPedido () {
    # Del registro tomo el producto y separo las palabras
    local VWORDS=(${1##*;})
        
    # Creo el comando para filtrar los registros
    # solo los que contengan todas las palabras
    local GREP="| grep -n -w -i"
    local COMAND="cat \"$2\""
    for PALABRA in ${VWORDS[*]}
    do
        local ULTPOS=${VWORDS[${#VWORDS[@]} - 1]}
        if [ $PALABRA != $ULTPOS ]; then
            COMAND="$COMAND $GREP $PALABRA"
        fi
    done
    
    COMAND="$COMAND | sed -e \"s/^\([^;][^;]*\):\([0-9][0-9]*;\)\([^;][^;]*;\)\([^;][^;]*;\)\([^;][^;]*;\)\([^;][^;]*\)/\$1;\2\5\6/\""
    
    # Chequeo que las unidades sean correctas y agrego los presupuestos
    local SAVE=$IFS
    IFS=$'\x0A'$'\x0D'
    FLAG=0
    for REG in $(eval $COMAND)
    do
      FLAG=1
      IFS=$';'
      local VFIELDS=($REG)
      IFS=$' '  
      local VWORDSP=(${VFIELDS[3]})
      if [ ${VWORDS[${#VWORDS[@]} - 2]} == ${VWORDSP[${#VWORDSP[@]} - 2]} ]; then
          if [ $4 == `echo ${VWORDS[${#VWORDS[@]} - 1]} | tr '[:upper:]' '[:lower:]'` ]; then
            echo $REG >> "$3"
          else
            local POSUNID=`ExisteUnidad ${VWORDS[${#VWORDS[@]} - 1]}`
            if [ $POSUNID -eq $5 ]; then
                echo $REG >> "$3"
            fi   
          fi
      fi
      
      IFS=$'\x0A'$'\x0D' 
    done
    IFS=$SAVE

    if [ $FLAG -eq 0 ]; then
      echo "$1" >> "$3" 
    fi
}

#
#--------------------------------------------------------------------------
#                       Programa Principal Rating
#--------------------------------------------------------------------------
#
# Valida que los parametros esten informados y sean consistentes
ERROR=`ValidarParametros "$ACEPDIR" "$MAEDIR" "$INFODIR" "$RECHDIR"`
if [ $? -ne 0 ]; then
    `"$BINDIR/Logging.sh" "$COMANDO" "$ERROR" "ERR"`
    `"$BINDIR/Logging.sh" "$COMANDO" "$MLOGFIN" "INFO"`
    exit 1
fi

# Logueo mensaje inicial de Rating
`"$BINDIR/Logging.sh" "$COMANDO" "$MLOGINI1" "INFO"`

NUMACEP=`ContarArchivos "$ACEPDIR"`

# Logueo el numero de archivos a presupuestar
`"$BINDIR/Logging.sh" "$COMANDO" "$MLOGINI2 $NUMACEP" "INFO"`

# Sino hay listas de compras por procesar termine
if [ $NUMACEP -eq 0 ]; then
    ERRORLP="No hay listas a presupuestar en $ACEPDIR"
    `"$BINDIR/Logging.sh" "$COMANDO" "$ERRORLP" "ERR"`
    `"$BINDIR/Logging.sh" "$COMANDO" "$MLOGFIN" "INFO"`
    exit 2
else	    
    `ExisteArchivo "$FLPMAE" "$MAEDIR/"`
        
    # Si no existe la lista maestra de precios finalizo
    if [ $? -ne 0 ]; then
	    ERRORLPRE="En $MAEDIR no existe lista de precios maestra $FLPMAE"
	    `"$BINDIR/Logging.sh" "$COMANDO" "$ERRORLPRE" "ERR"`
        `"$BINDIR/Logging.sh" "$COMANDO" "$MLOGFIN" "INFO"`
	    exit 3
    fi
    
    `ExisteArchivo "$TABEQU" "$MAEDIR/"`
        
    # Si no existe el archivo de equivalencias finalizo
    if [ $? -ne 0 ]; then
	    ERRORLEQ="En $MAEDIR no existe el archivo de equivalencias $TABEQU"
	    `"$BINDIR/Logging.sh" "$COMANDO" "$ERRORLEQ" "ERR"`
        `"$BINDIR/Logging.sh" "$COMANDO" "$MLOGFIN" "INFO"`
	    exit 4
    fi
    
    # Creo un vector con los registros de unidades
    for REG in `cat "$MAEDIR/$TABEQU"`
    do	
	    LOWREG=`echo $REG | tr [:upper:] [:lower:]`
        VREGUNIDS[${#VREGUNIDS[@]}]="$LOWREG;"
    done

    # Recupero las listas de comparas a procesar
    SAVEIFS=$IFS
    IFS=$'\n'
    for ARCHIVO in `find "$ACEPDIR" -maxdepth 1 -type f`
    do
        IFS=$SAVEIFS
        # Logueo la lista a presupuestar
        `"$BINDIR/Logging.sh" "$COMANDO" "$MPROC $ARCHIVO" "INFO"`
        
        # Chequeo que no se haya procesado aun el archivo
        `ExisteArchivo "${ARCHIVO##*/}" "$ACEPDIR/proc/"`
	    
	    if [ $? -eq 0 ]; then
            `"$BINDIR/Logging.sh" "$COMANDO" "$MERRGEN $ARCHIVO $MERRDUP" "ERR"`
            `"$BINDIR/Mover.sh" "$ARCHIVO" "$RECHDIR/" "$COMANDO"`
        else	 
            # Valida que el archivo lista de compra sea valido
	        if ! [ -s "$ARCHIVO" ]; then
		        # Error de validacion se mueve archivo a rechazados
		        `"$BINDIR/Logging.sh" "$COMANDO" "$MERRGEN $ARCHIVO $MERRVAC" "ERR"`
                `"$BINDIR/Mover.sh" "$ARCHIVO" "$RECHDIR/" "$COMANDO"`
            else
		        INFOTEMP="$INFODIR/pres/${ARCHIVO##*/}"
		        HAYERROR=0
	            # Recorro los productos solicitados en la lista de compras
	            IFS=$'\n'
	            for REGPROD in `< "$ARCHIVO"`
		        do
		            IFS=$SAVEIFS
		            # Verifica la validez del registro
		            NUMTAGP=`echo "$REGPROD" | grep -e "^[0-9][0-9]*;[^;]*$" -c`
                    # Valida numero de delimitadores
                    if [ $NUMTAGP -ne 1 ]; then 
                        HAYERROR=1	
                    else
                        # Checkeo que la unidad sea valida
                        UNIDP=${REGPROD##*" "}
                        POSUNID=`ExisteUnidad $UNIDP`
                        if [ $? -eq 0 ]; then
                            HAYERROR=1
                        fi
                    fi
		            
		            # Si no hay errores en el registro a procesar busco precio
		            if [ $HAYERROR -ne 1 ]; then
		                `PresupuestarPedido "$REGPROD" "$MAEDIR/$FLPMAE" "$INFOTEMP" $UNIDP $POSUNID`
		            else		                
		                break
		            fi
		        done
		        IFS=$SAVEIFS
                
                if [ $HAYERROR -eq 0 ]; then
		            # Procesado el archivo lo muevo a INFODIR
		            `"$BINDIR/Mover.sh" "$ARCHIVO" "$ACEPDIR/proc/" "$COMANDO"`
		        else
		            `rm "$INFOTEMP"`
		            `"$BINDIR/Logging.sh" "$COMANDO" "$MERRGEN $ARCHIVO $MERRINV" "ERR"`
                    `"$BINDIR/Mover.sh" "$ARCHIVO" "$RECHDIR/" "$COMANDO"` 	
		        fi
            fi            
        fi
    done
fi

`"$BINDIR/Logging.sh" "$COMANDO" "$MLOGFIN" "INFO"`
# Fin Rating
