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
# Parametros
#       $ACEPDIR=$1
#       $MAEDIR=$2
#       $INFODIR=$3
#       $RECHDIR=$4
#
# -----------------------Definicion de variables----------------------------
ACEPDIR=$1
MAEDIR=$2
INFODIR=$3
RECHDIR=$4

# -----------------------Definicion de constantes---------------------------
MLOGINI1="Inicio de Rating"
MLOGINI2="Cantidad de listas de compras a procesar: "
MLOGFIN="Fin de Rating"
MPROC="Archivo a procesar: "
MERRDUP="Se rechaza el archivo por estar DUPLICADO"
MERRINV="Se rechaza el archivo por formato INVALIDO"
MERRVAC="Se rechaza el archivo por estar vacio"
FLPMAE="precios.mae"
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
        $RTA=1 
    fi
    
    if [ -z "$2" ]; then
        MENSERR="Parametro 2 no esta informado. Valor: $2"
        $RTA=1 
    fi

    if [ -z "$3" ]; then
        MENSERR="Parametro 3 no esta informado. Valor: $3"
        $RTA=1 
    fi

    if [ -z "$4" ]; then
        MENSERR="Parametro 4 no esta informado. Valor: $4"
        $RTA=1 
    fi

    # Valido que los directorios sean validos
    if ! [ -d $1 ]; then 
        MENSERR="Parametro 1 no es un directorio valido. Valor: $1"
        $RTA=2 
    fi
    
    if ! [ -d "$1/proc" ]; then 
        MENSERR="Directorio "$1/proc" inexistente"
        $RTA=2 
    fi
    
    if ! [ -d $2 ]; then 
        MENSERR="Parametro 2 no es un directorio valido. Valor: $2"
        $RTA=2 
    fi
    
    if ! [ -d $3 ]; then 
        MENSERR="Parametro 3 no es un directorio valido. Valor: $3"
        $RTA=2 
    fi
    
    if ! [ -d "$3/pres" ]; then 
        MENSERR="Directorio "$3/pres" inexistente"
        $RTA=2 
    fi
    
    if ! [ -d $4 ]; then 
        MENSERR="Parametro 4 no es un directorio valido. Valor: $4"
        $RTA=2 
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
    NUMACEP=`ls $1*.* | wc -l`
    echo $NUMACEP
}

# Funcion. ExisteArchivo
# Parametros. $1 (nombre archivo) $2 (directorio a verificar)
# Objetivo. Verificar la existencia del archivo en el directorio indicado
 
function ExisteArchivo () {
    # Tomo el nombre del archivo de la ruta actual
    local NUMARCH=`find $2 -name $1 | wc -l`
    if [ $NUMARCH = 0 ]; then
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
    while read REG
    do
        NUMREG=`expr $NUMREG + 1`
        local REGLOW=`echo $REG | tr [:upper:] [:lower:]`
        IFS=';'
        local VUNIDS=(`echo "$REGLOW;"`)
        IFS=' '            
        for VUNID in ${VUNIDS[*]}
        do
            local UNID=`echo $1 | tr [:upper:] [:lower:]`
            if [ "$VUNID" = "$UNID" ]; then
                EXISTE="$NUMREG"
                break
            fi
        done
        if [ $EXISTE != 0 ]; then
            break
        fi       
    done < "$MAEDIR/um.tab"
    echo $EXISTE
}

# Funcion. ValidarArchivoCompra
# Parametros. $1 (ruta archivo) 
# Objetivo. Verificar la validez del archivo lista de compra a presupuestar
 
function ValidarArchivoCompra () {     
    if ! [ -s "$1" ]; then
	    # Valido archivo vacio
	    echo "$MERRVAC"
	    return 1
    fi
    
    # Verifico el formato de cada uno de los registros
    while read LINEA
    do
	    local NUMTAG=`echo "$LINEA" | grep -c ";"`
	    if [ $? = 0 ]; then
	        # Valido lista de compra
	        if [ $NUMTAG != 1 ]; then 
	            echo "$MERRINV" 
	            return 1	
	        fi
	
	        # Checkeo que la unidad sea valida
	        local UNID=${LINEA##*" "}
	        local POSUNID=`ExisteUnidad $UNID`
	        if [ $POSUNID = 0 ]; then
	            echo "$MERRINV"
	            return 1
	        fi
	    else
	        echo "$MERRINV"
	        return 1
	    fi
    done < "$1"
    
    echo ""
    return 0
}

# Funcion. CompararProductos
# Parametros. $1 (produto a comprar) $2 (producto en lista de precios) 
# Objetivo. Verificar que ambos productos son iguales realizando una 
# comparacion por palabra sin importar el orden (no case sensitive)
 
function CompararProductos () {
    # Resguardo la cadena en ficheros auxiliares
    echo $1 > "$PWD/FT1"
    echo $2 > "$PWD/FT2"
    
    # Busco cada palabra en el registro de la lista de precios
    local RTA=0
    while read -d " " PALABRA
    do
        # Por cada palabra de producto 1 busco match
        local MATCH=0
        MATCH=`egrep -i -w -c $PALABRA "$PWD/FT2"`
        if [ $MATCH = 0 ]; then
            RTA=1
            break
        fi
    done < "$PWD/FT1"
    
    `rm "$PWD/FT1"` 
    `rm "$PWD/FT2"`

    # Verifico las unidades
    if [ $RTA = 0 ]; then
        local UNID1=${1##*" "}
        local UNID2=${2##*" "}
	    if [ "$UNID1" != "$UNID2" ]; then
	        # Debo buscar equivalencia de unidades	        
	        local POSUNID1=`ExisteUnidad "$UNID1"`
	        local POSUNID2=`ExisteUnidad "$UNID2"`
	        if [ "$POSUNID1" != "$POSUNID2" ]; then
		        RTA=1
	        fi
        fi 
    fi
    
    return $RTA
}

# Funcion. ObtenerPrecios
# Parametros. $1 (item-produto a comprar) $2 (archivo lista de precios) 
# $3 (archivo donde se almacenan)
# Objetivo. Obtener los precios y nombres de productos que se corresponden  
# con el producto indicado, almacenando los datos en $3
 
function ObtenerPrecio () {
    # Proceso cada uno de los productos del super
    # buscando coincidencias con el producto a comprar
    IFS=';'
    local VCOM=(`echo "$1;"`)
    IFS=' '
    local IGUALDAD=0

    while read REGSUP
    do 
	    IFS=';'
	    local VSUP=(`echo "$REGSUP;"`)
	    IFS=' '
	    `CompararProductos "${VCOM[1]}" "${VSUP[3]}"`
	    if [ $? = 0 ]; then	
	        echo "${VCOM[0]};${VCOM[1]};${VSUP[0]};${VSUP[3]};${VSUP[4]}" >> $3
	        IGUALDAD=1
	    fi
    done < $2
    return $IGUALDAD
}

#
#--------------------------------------------------------------------------
#                       Programa Principal Rating
#--------------------------------------------------------------------------
#
# Valida que los parametros esten informados y sean consistentes
ERROR=`ValidarParametros "$ACEPDIR" "$MAEDIR" "$INFODIR" "$RECHDIR"`
if [ $? != 0 ]; then
    echo "$ERROR"
    exit 1
fi

# Logueo mensaje inicial de Rating
`$PWD/Logging.sh "$COMANDO" "$MLOGINI1" "INFO"`

NUMACEP=`ContarArchivos "$ACEPDIR"`

# Logueo el numero de archivos a presupuestar
`$PWD/Logging.sh "$COMANDO" "$MLOGINI2 $NUMACEP" "INFO"`

# Sino hay listas de compras por procesar termine
if [ $NUMACEP = 0 ]; then
    echo "No hay listas a presupuestar en $ACEPDIR"
    exit 2
else	    
    `ExisteArchivo "$FLPMAE" "$MAEDIR"`
        
    # Si no existe la lista maestra de precios finalizo
    if [ $? != 0 ]; then
	    echo "En $MAEDIR no existe lista de precios maestra $FLPMAE"
	    exit 3
    fi

    # Recupero las listas de comparas a procesar
    `ls "$ACEPDIR"*.* -1 > "$PWD/LISTTEMP"`
    
    while read ARCHIVO
    do
        # Logueo la lista a presupuestar
        `$PWD/Logging.sh "$COMANDO" "$MPROC $ARCHIVO" "INFO"`
        
        # Chequeo que no se haya procesado aun el archivo
        `ExisteArchivo "${ARCHIVO##*/}" "${ACEPDIR}proc/"`
        
	    if [ $? = 0 ]; then
            `$PWD/Logging.sh "$COMANDO" "$MERRDUP" "ERR"`
            `$PWD/Mover.sh "$ARCHIVO" "$RECHDIR" "$COMANDO"`
        else 
            # Valida que el archivo lista de compra sea valido
            MENSERR=`ValidarArchivoCompra "$ARCHIVO"`
            
	        if ! [ -z "$MENSERR" ]; then
		        # Error de validacion se mueve archivo a rechazados
		        `$PWD/Logging.sh "$COMANDO" "$MENSERR" "ERR"`
                `$PWD/Mover.sh "$ARCHIVO" "$RECHDIR" "$COMANDO"`
            else
		        INFOTEMP="$PWD/${ARCHIVO##*/}"		
		
	            while read REGPROD
		        do
		            `ObtenerPrecio "$REGPROD" "${MAEDIR}$FLPMAE" "$INFOTEMP"`
		            if [ $? != 1 ]; then
                        # Si no encontro precio grabo el producto pedido
		                echo "$REGPROD" >> "$INFOTEMP"
		            fi
		        done < $ARCHIVO

		        # Procesado el archivo lo muevo a INFODIR
		        `$PWD/Mover.sh "$INFOTEMP" "${INFODIR}pres/" "$COMANDO"` 	
            fi
            `$PWD/Mover.sh "$ARCHIVO" "${ACEPDIR}proc/" "$COMANDO"`
        fi
    done < "$PWD/LISTTEMP"

    # Elimino el archivo temporal creado 
    `rm "$PWD/LISTTEMP"` 
fi

`$PWD/Logging.sh "$COMANDO" "$MLOGFIN" "INFO"`
# Fin Rating
