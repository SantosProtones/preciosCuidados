Error=1
OK=0

if [ $# -lt 2 -o $# -gt 3 ]
then
    exit $Error
else
    if  [ $# -eq 3 ]
    then
        Comando=$3
    fi
    Archivo=${1##*/}
    Origen=${1%/*}
    Destino=$2

    #Si el origen o el destino no existen retornar error
    if [ ! -d "$Origen" -o  ! -d "$Destino" ]
    then
        exit $Error

    #Si el origen es igual al destino no mover
    elif [ "$Origen" == "$Destino" ]
    then
        exit $Ok

    #Si el Archivo ya existe en el Destino generer un duplicado
    elif [ -f "$Destino/$Archivo" ]
    then
        #Si no existe un subdirectorio /dup en Destino
        if [ ! -d "$Destino/dup" ]
        then
	     #Creo el subdirectorio
            `mkdir "$Destino/dup"`
        fi
                
        #Obtengo el numero de secuencia
        NumSec=`cat "$CONFDIR/Installer.conf" | fgrep 'NUMSEC' | cut -f2 -d'='`
	
	#Incremento el numero de secuencia        
        NumSec=`expr $NumSec + 1`
        
        #Obtengo el usuario
        Usuario=`whoami`

	#Obtengo la fecha
	Fecha=`date`
        
	#Copio el original a un auxiliar
	cp "$CONFDIR/Installer.conf" "$CONFDIR/Installer.conf.bak"

	#Grabo el numero de secuencia actualizado
        cat "$CONFDIR/Installer.conf.bak" | sed "s-^NUMSEC=[0-9]*=.*-NUMSEC=$NumSec=$Usuario=$Fecha-" > "$CONFDIR/Installer.conf"

        #Borro el auxiliar
	rm "$CONFDIR/Installer.conf.bak"

	#Copio el archivo a Destino/dup
        cp "$Origen/$Archivo" "$Destino/dup/$Archivo.$NumSec"
	
        #Borro el archivo
	rm "$Origen/$Archivo"
	
	exit $Ok
        
    else
	#Realizo el move a Destino
	`mv "$Origen/$Archivo" "$Destino"`
	
 	exit $Ok
    fi
fi
