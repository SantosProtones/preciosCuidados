#!/bin/bash
#Masterlist: Proceso que actualiza la lista maestra de precios

#Obtengo la cantidad de listas de precios a procesar
Cant_Listas=`find "$MAEDIR/precios" -maxdepth 1 -type f | wc -l`

`"$BINDIR/Logging.sh" Masterlist "Inicio de Masterlist" INFO`
`"$BINDIR/Logging.sh" Masterlist "Cantidad de Listas de precios a procesar: $Cant_Listas" INFO`

#Si la lista maestra de precios no existe la creo
if [ ! -f "$MAEDIR/precios.mae" ]
then
    touch "$MAEDIR/precios.mae"
fi

#Recorro las listas de precios
IFS=$'\n'
for PathListaDePrecios in `find "$MAEDIR/precios" -maxdepth 1 -type f`
do
	ListaDePrecios=${PathListaDePrecios##*/}
    `"$BINDIR/Logging.sh" Masterlist "Archivo a procesar: $ListaDePrecios" INFO`
     
    #Verifico que no exista el archivo
    if [ -f "$MAEDIR/precios/proc/$ListaDePrecios" ]
    then
        #Si esta duplicado lo muevo a RECHDIR
        `"$BINDIR/Mover.sh" "$MAEDIR/precios/$ListaDePrecios" "$RECHDIR"`
        #Logueo la causa del archivo rechazado
        `"$BINDIR/Logging.sh" Masterlist "Se rechaza el archivo por estar duplicado" WAR`
    else
        #Valido el registro cabecera
        #Me fijo que tenga 6 campos
	Cant_Campos_Cabecera=`head -1 "$MAEDIR/precios/$ListaDePrecios" | grep -e "^[^;]*;[^;]*;[0-9]*;[0-9]*;[0-9]*;.*$"`
	if [ -z "$Cant_Campos_Cabecera" ]
        then
            #Muevo el archivo a RECHDIR
            `"$BINDIR/Mover.sh" "$MAEDIR/precios/$ListaDePrecios" "$RECHDIR"`
            #Logueo la causa el archivo rechazado
            `"$BINDIR/Logging.sh" Masterlist "Se rechaza el archivo por registro cabecera inválido" WAR`
            continue
        fi
        
        Nombre_Super=`head -1 "$MAEDIR/precios/$ListaDePrecios" | cut -f1 -d';'`
        Provincia=`head -1 "$MAEDIR/precios/$ListaDePrecios" | cut -f2 -d';'`
        Cant_Campos=`head -1 "$MAEDIR/precios/$ListaDePrecios" | cut -f3 -d';'`
        Ubic_Producto=`head -1 "$MAEDIR/precios/$ListaDePrecios" | cut -f4 -d';'`
        Ubic_Precio=`head -1 "$MAEDIR/precios/$ListaDePrecios" | cut -f5 -d';'`
        Email_Colab=`head -1 "$MAEDIR/precios/$ListaDePrecios" | cut -f6 -d';'`

        #Obtengo el Super_Id del Maestro de Supermercados
        Super_Id=`grep "^[^;]*;$Provincia;$Nombre_Super;.*" "$MAEDIR/super.mae" | cut -f1 -d';'`

        #Obtengo el registro que contiene el email del colaborador en el Maestro de Asociados y Colaboradores
        Registro_Email_Colab=`grep "^[^;]*;[^;]*;[^;]*;[^;]*;$Email_Colab" "$MAEDIR/asociados.mae"`

        #Verifico que el super_id no este vacio
        if [ -z $Super_Id ]
        then
            #Muevo el archivo a RECHDIR
            `"$BINDIR/Mover.sh" "$MAEDIR/precios/$ListaDePrecios" "$RECHDIR"`
            #Logueola causa el archivo rechazado
            `"$BINDIR/Logging.sh" Masterlist "Se rechaza el archivo por Supermercado inexistente" WAR`

        #Verifico que no este vacio y que la cantidad de campos no sea menor a 1
        elif [ -z "$Cant_Campos" ] || [ $Cant_Campos -le 1 ]
        then
            #Muevo el archivo a RECHDIR
            `"$BINDIR/Mover.sh" "$MAEDIR/precios/$ListaDePrecios" "$RECHDIR"`
            #Logueo la causa del archivo rechazado
            `"$BINDIR/Logging.sh" Masterlist "Se rechaza el archivo por Cantidad de campos inválida" WAR`

        #Verifico que no este vacio y que la ubicacion del producto no sea menor o igual a cero y mayor que la cantidad de campos
        elif [ -z "$Ubic_Producto" ] || [ $Ubic_Producto -le 0 -o $Ubic_Producto -gt $Cant_Campos ]
        then
            #Muevo el archivo a RECHDIR
            `"$BINDIR/Mover.sh" "$MAEDIR/precios/$ListaDePrecios" "$RECHDIR"`
            #Logueo la causa del archivo rechazado
            `"$BINDIR/Logging.sh" Masterlist "Se rechaza el archivo por Posición producto inválida" WAR`
        
        #Verifico que no este vacio y que la ubicacion del precio no sea menor o igual a cero,
        #mayor que la cantidad de campos y distinto de la ubicacion del producto
        elif [ -z "$Ubic_Precio" ] || [ $Ubic_Precio -le 0 -o $Ubic_Precio -gt $Cant_Campos -o $Ubic_Precio -eq $Ubic_Producto ]
        then
            #Muevo el archivo a RECHDIR
            `"$BINDIR/Mover.sh" "$MAEDIR/precios/$ListaDePrecios" "$RECHDIR"`
            #Logueo la causa del archivo rechazado
            `"$BINDIR/Logging.sh" Masterlist "Se rechaza el archivo por Posición precio inválida" WAR`

        #Verifico que el registro email colaborador no este vacio
        elif [ -z "$Registro_Email_Colab" ]
        then
           #Muevo el archivo a RECHDIR
           `"$BINDIR/Mover.sh" "$MAEDIR/precios/$ListaDePrecios" "$RECHDIR"`
           #Logueo la causa del archivo rechazado
           `"$BINDIR/Logging.sh" Masterlist "Se rechaza el archivo por Correo electrónico del colaborador inválido" WAR`
        
        else
            #Si llego hasta aca paso todas las validaciones

            #Inicializo variables
            Reg_ok=0
            Reg_nok=0
            Reg_eliminados=0

            #Obtengo el usuario desde el nombre del archivo
            Usuario=`echo $ListaDePrecios | rev | cut -f1 -d'.' | rev`

            #Obtengo un registro de la lista maestra de precios con el super_id y el usuario
            Reg_Precio_Maestro=`grep "^$Super_Id;$Usuario;.*" "$MAEDIR/precios.mae" | head -1`

            #Obtengo la fecha de la lista de precios a procesar
            Fecha_Lista_Novedad=`echo $ListaDePrecios | sed "s#^[^-]*-\([^\.]*\)\..*#\1#"`

            #Si la cadena no esta vacia, existen registros para el super con el usuario
            if [ ! -z $Reg_Precio_Maestro ]
            then
                #Obtengo la fecha de la lista maestra de precios
                Fecha_Lista_Maestra=`echo $Reg_Precio_Maestro | cut -f3 -d';'`

                #Si la fecha del archivo novedad es mas reciente que de la lista maestra de precios
                if [ $Fecha_Lista_Novedad -gt $Fecha_Lista_Maestra ]
                then
                    #Cuento los registros que se van a borrar
                    Reg_eliminados=`grep "^$Super_Id;$Usuario;$Fecha_Lista_Maestra;.*" "$MAEDIR/precios.mae" | wc -l`

                    #Copio el original a un auxiliar
                    cp "$MAEDIR/precios.mae" "$MAEDIR/precios.mae.bak"	

                    #Borro los archivos de la lista maestra de precios
                    sed "/^$Super_Id;$Usuario;$Fecha_Lista_Maestra;.*/d" "$MAEDIR/precios.mae.bak" > "$MAEDIR/precios.mae"

                    #Borro el auxiliar
                    rm "$MAEDIR/precios.mae.bak"

                    #Logueo los registros eliminados
                    `"$BINDIR/Logging.sh" "Masterlist" "Cantidad de registro eliminados: $Reg_eliminados" INFO`

                else
                    #Si la fecha no es mas reciente se rechaza el archivo

                    #Muevo el archivo a RECHDIR
                    `"$BINDIR/Mover.sh" "$MAEDIR/precios/$ListaDePrecios" "$RECHDIR"`
                    #Logueo la causa del archivo rechazado
                    `"$BINDIR/Logging.sh" Masterlist "Se rechaza el archivo por fecha anterior a la existente" WAR`
                    #Salteo a la proxima lista de precios
                    continue
                fi
            fi

            #Grabo los nuevos registros
            sed 1d "$MAEDIR/precios/$ListaDePrecios" | ( while read -r Reg_Precio
            do	
                #Obtengo el producto
                Producto=`echo $Reg_Precio | cut -f$Ubic_Producto -d';'`

                #Obtengo el precio
                Precio=`echo $Reg_Precio | cut -f$Ubic_Precio -d';'`

                Producto_vacio=`echo $Producto | sed "s-^ *--"`
                Precio_vacio=`echo $Precio | sed "s-^ *--"`               

                if [ -z $Producto ]
                then
                    #Incremento la cantidad de registros nok
                    Reg_nok=`expr $Reg_nok + 1`
                    continue

                elif [ -z $Producto_vacio ]
                then
                    #Incremento la cantidad de registros nok
                    Reg_nok=`expr $Reg_nok + 1`
                    continue
        
                elif [ -z $Precio ] || ( ! [[ $Precio =~ ^[0-9]+(\.[0-9]+)?$ ]])
                then
                    #Incremento la cantidad de registros nok
                    Reg_nok=`expr $Reg_nok + 1`
                    continue

		elif [ -z $Precio_vacio ]
                then
                    #Incremento la cantidad de registros nok
                    Reg_nok=`expr $Reg_nok + 1`
                    continue
        
                else
                    #Armo el registro de salida para grabar en la lista maestra de precios
                    Reg_Maestro="$Super_Id;$Usuario;$Fecha_Lista_Novedad;$Producto;$Precio"

                    #Grabo el registro
                    echo "$Reg_Maestro" >> "$MAEDIR/precios.mae"

                    #Incremento la cantidad de registros ok
                    Reg_ok=`expr $Reg_ok + 1`

                fi
            done

            #Muevo el archivo que se acabo de procesar
            `"$BINDIR/Mover.sh" "$MAEDIR/precios/$ListaDePrecios" "$MAEDIR/precios/proc"`

            #Logueo la cantidad de registros ok
            `"$BINDIR/Logging.sh" "Masterlist" "Cantidad de registros ok: $Reg_ok" INFO`
            #Logueo la cantidad de registros nok
            `"$BINDIR/Logging.sh" "Masterlist" "Cantidad de registros nok: $Reg_nok" INFO` )
        fi
    fi
done

#Logueo el fin
`"$BINDIR/Logging.sh" "Masterlist" "Fin de Masterlist" INFO`
