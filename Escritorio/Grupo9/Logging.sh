# Variables que ya tendrian que estar seteadas
LOGSIZE=100
LOGDIR="$PWD"
LOGEXT='dat'
#
When=`date`
Who=`whoami`
Where=$1
Temp=$3
if [ $# -eq 3 ]
then
	if [ $3 == 'INFO' -o $3 == 'WAR' -o $3 == 'ERR' ] 
	then
		What=$3
	else
		What='INFO'
	fi
	Why=$2

#Armo la linea a imprimir en el log
Tab='        '
Linea="[$When] $Tab $Who $Tab $Where $Tab $What $Tab $Why"

#verifico la existencia del archivo de log

ArchLog=$LOGDIR/Logging.$LOGEXT

if [ -f $ArchLog ]
then
	#Cuento las que hay y dejo las ultimas 50 si hace falta
	NumLineas=`wc -l $ArchLog | cut -f1 -d' '`
	
	if [ $NumLineas -ge $LOGSIZE ] 
	then
		#Borro desde la linea 1 hasta la (NumLineas - 50)
		i=1	
		TopeBorrado=`expr $LOGSIZE - 50`
		while [ $i -le $TopeBorrado ]
		do
			sed -i '1d' $ArchLog
			i=`expr $i + 1`
		done
	echo "Log exedido para poder controlar que se está realizando este trabajo">>$ArchLog
	fi
	#Concateno mi linea
	echo $Linea>>$ArchLog
else
	echo $Linea>$ArchLog
fi

else
echo "Cantidad de argumentos invalida"
fi












