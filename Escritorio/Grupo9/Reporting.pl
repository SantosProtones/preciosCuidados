#!/usr/local/bin/perl

#validar si la inicializacion de ambiente fue realizada
#validar que no existe otro comando Reporting en ejecucion
#limpiar de caracteres raros las opciones

#-----------------variables inicializadas minimas
#$INFODIR="/home/flavio/Escritorio/TpSis/Grupo09/Informes";

#$MAEDIR="/home/flavio/Escritorio/TpSis/Grupo09/Mestros";
#-----------------

if(!initialize()){
	print "Error: La inicializacion de ambiente no fue realizada\n";	
	exit;
}
if(!onlyReporting()){
	print "Error: ya hay otro proceso de reporting corriendo\n";
	exit;
}

%opciones=loadParams();
reportingMain();


sub initialize{
	if((defined $ENV{"INFODIR"}) and (defined $ENV{"MAEDIR"})){
		$INFODIR=$ENV{"INFODIR"};
		$PRESDIR=$INFODIR."/pres";
		$MAEDIR=$ENV{"MAEDIR"};		
		return 1;
	}
	return 0;
}

sub onlyReporting{
	open(FILE, "ps -Af|");
	$cont=0;
	while (<FILE>)
	{
	$linea=$_;
	#print "valida no haya otro Reporting corriendo\n";
	#print "$linea\n";	
	if($linea=~m/^.*(perl[\s][\s]*Reporting\.pl.*)$/){
		$cont++;
	};
	if($cont>1){
		return 0;
	}
	#($uid,$pid,$ppid,$restofline) = split;
	#print "the process id is :$pid";
	}
	return 1;
}

sub reportingMain{
	if(invalidParams()){
		print "\nLos parametros ingresados para hacer el reporte son inválidos.\n";
		print "A continuación le presentamos el manual del comando para que despeje sus dudas de utilización\n\n";
		printReportingHelp();
	}else{
		if($opciones{"a"}){
			printReportingHelp();
		}else{		
			%filtroSupers=();
			if($opciones{"x"}){
				%filtroSupers=getFiltroSupers();
			}
			@filtroUsuarios=();
			if($opciones{"u"}){
				@filtroUsuarios=getFiltroUsuarios();
			}
			
			printFullReport();
			
		}
	}
	print "Reporte Finalizado. Desea realizar uno nuevo(s/n)\n";
	my $respuesta=<STDIN>;
	if($respuesta=~m/([a-zA-Z][a-zA-Z]*)/){
		if((lc($1) eq "s") or (lc($1) eq "si") or (lc($1) eq "y") or (lc($1) eq "yes")){
			print "\033[2J";   #clear the screen
			print "\033[0;0H"; #jump to 0,0
			print "\nIngrese los parametros deseados para el nuevo reporte\n";
			$respuesta=<STDIN>;
			if($respuesta=~m/([a-zA-Z][a-zA-Z]*)/){
				%opciones=loadParams($1);
			}else{
				%opciones=loadParams("");
			}
			reportingMain();
		}
	}	
	return;	
}

sub invalidParams{
	if($opciones{"a"}){
		return 0;
	}
	if($opciones{"m"} and $opciones{"r"} and !$opciones{"d"} and !$opciones{"f"}){
		return 0;
	}
	if(!$opciones{"m"} and $opciones{"r"} and $opciones{"d"} and !$opciones{"f"}){
		return 0;	
	}
	if($opciones{"m"} and !$opciones{"r"} and !$opciones{"d"} and !$opciones{"f"}){
		return 0;
	}
	if(!$opciones{"m"} and $opciones{"r"} and !$opciones{"d"} and !$opciones{"f"}){
		return 0;
	}
	if(!$opciones{"m"} and !$opciones{"r"} and $opciones{"d"} and !$opciones{"f"}){
		return 0;
	}
	if(!$opciones{"m"} and !$opciones{"r"} and !$opciones{"d"} and $opciones{"f"}){
		return 0;
	}
	return 1;	
} 

sub loadParams{
	%opciones=( "a"=> 0,"w"=>0,"r" => 0,"m" => 0, "d" => 0,"f" => 0,"x" => 0,"u" => 0);
	$opciones="";
	$cantParams=$#_+1;
	#print "numero de argumentos $cantParams\n";
	if($cantParams==0){
		$cantParams=$#ARGV+1;
		if($cantParams>0){	
			$opciones=$ARGV[0];
		}
	}else{
		$opciones=$_[0];
	}

	@opciones=split("",$opciones);
	$cantOpciones=$#opciones+1;
	#print "cant de letras opciones $cantOpciones\n";	
	for($i=0;$i<$cantOpciones;$i++){
		if (exists $opciones{lc($opciones[$i])}){
			$opciones{lc($opciones[$i])}=1;
		}
		#print "key " . lc($opciones[$i]) . " valor " . $opciones{lc($opciones[$i])} ."\n";
	}
	#print "opciones $opciones\n"; 
	return %opciones; 
}

sub printReportingHelp{
	print "Manual del comando Reporting\n\n";
	print "Este comando permite realizar reportes en base a los archivos de listas de compras presupuestadas.\n\n";
	print "Posee un único parámetro, y sus opciones son:\n\n";
	print "-a\tPresenta el manual de ayuda del comando Reporting\n\n";
	print "-w\tGrabar a disco el reporte solicitado.\n\n";
	print "-r\tMuestra los precios de referencia o precios cuidados. Combinable con m y d\n\n";
	print "-m\tMuestra los precios menores por cada item que no sean precios cuidados\n\n";
	print "-d\tMuestra los precios menores por cada item pero agrupados por lugar de compra\n\n";
	print "-f\tMuestra unicamente los los items para los que no se encontro precio\n\n";	
	print "-x\tMuestra un menu para elegir porque provincias-supermercados filtrar\n\n";
	print "-u\tMuestra un menu para filtrar los usuarios con presupuestos disponibles para realizar reportes\n\n";
	print "Las opciones [-w -x -u] son combinables con todas las demas opciones\n\n";
	return;
}

sub printReport{
	
	$cantParams=@_;
	if($cantParams==1){
		print ($_[0]);
		if($opciones{"w"}){
			print INFORME ($_[0]);
		}
		return;
	}
	
	if($cantParams==2){
		
		$format=$_[1];
		#print ("entra donde debe \n");
		printf ($format,$_[0]);
		if($opciones{"w"}){
			printf INFORME ($format,$_[0]);
		}
	}
	
	return;
}

sub pritnOnlyScreen{
	$cantParams=@_;
	if($cantParams==1){
		print ($_[0]);
		return;
	}
	
	if($cantParams==2){
		$format=$_[1];
		#print ("entra donde debe \n");
		printf ($format,$_[0]);
	}
	return;
}

sub printOnlyInfo{
	$cantParams=@_;
	if($cantParams==1){

		if($opciones{"w"}){
			print INFORME ($_[0]);
		}
		return;
	}
	
	if($cantParams==2){
		
		$format=$_[1];
		#print ("entra donde debe \n");

		if($opciones{"w"}){
			printf INFORME ($format,$_[0]);
		}
	}
	
	return;
}

sub nuevoInforme{
	if($opciones{"w"}){
	  $numInfo=getNumInfo();
	  open(INFORME,">> $INFODIR/info_$numInfo") || die "No pudo crearse: $!";
	}
	return;
}

sub cerrarInforme{
	if($opciones{"w"}){
	  close (INFORME);
	}
	return;
}

sub getNumInfo{
	opendir(DIR, $INFODIR);
	
	@FILES= readdir(DIR);
	$cantFiles=@FILES;	
	if($cantFiles==0){
		closedir(DIR);
		return 1;
	}
	$maxNum=0;
	foreach $file(@FILES){
		#print "file $file\n";
		if($file=~m/info_([0-9][0-9]*)$/){
			#print "entro $1\n";
			$newNum=$1;
			if($maxNum<$newNum){
				$maxNum=$newNum;
			}
		}
	}
	$maxNum++;
	#print "archivo " . $maxNum . "\n";
	closedir(DIR);
	#print "numero de informe$maxNum";
	return $maxNum;
}

sub getFiltroSupers{
	%filtroSupers=();
	my %supers=getAllRealSupers();
	printMenuSupers(2);
	my $opciones=<STDIN>;
	my @opciones=split(" ",$opciones);
	foreach $opcion(@opciones){
		if (defined $supers{$opcion}){
			$filtroSupers{$opcion}=$supers{$opcion};
			#print "opcion valida $opcion\n";		
		}
	}
	print "\n";
	#$cantSupers=@filtroSupers;
	#print "cant de supers filtrados @filtroSupers\n"; 
	return %filtroSupers;
}

sub getAllRealSupers{
	%supers=();
	open(SUPERMAE,"$MAEDIR/super.mae") || die "No pudo abrirse: $!";
	while(<SUPERMAE>){
		my $linea=$_;		
		my @campos=split(";",$linea);
		my $campos=@campos;		
		if($campos<3){		
			next;
		}
		my $idSuper=$campos[0];my $provincia=$campos[1];my $nombreSuper=$campos[2];
		if($idSuper<100){
			next;
		}
		$supers{$idSuper}="$provincia-$nombreSuper";
	}
	close(SUPERMAE);
	return %supers;
}

sub getAllSupers{
	%supers=();
	open(SUPERMAE,"$MAEDIR/super.mae") || die "No pudo abrirse: $!";
	while(<SUPERMAE>){
		my $linea=$_;		
		my @campos=split(";",$linea);
		my $campos=@campos;		
		if($campos<3){		
			next;
		}
		my $idSuper=$campos[0];my $provincia=$campos[1];my $nombreSuper=$campos[2];
		$supers{$idSuper}="$nombreSuper-$provincia";
	}
	close(SUPERMAE);
	return %supers;
}

sub printMenuSupers{
	pritnOnlyScreen("Escriba los ids separados por espacio de las opciones que desea.");
	pritnOnlyScreen("Presione enter al finalizar la eleccion.\n");
	pritnOnlyScreen("En caso de querer todas las opciones, no ponga ningun id ");
	pritnOnlyScreen("y simplemente presione enter.\n\n");
	my $cantCols=$_[0];
	my $cont=0;
	foreach $key( keys %supers){
		pritnOnlyScreen($key . "_" . $supers{$key},"%-50s ");
		#printf ("%-32s ",$key . "_" . $supers{$key});
		$cont++;
		my $resto=$cont % $cantCols;
		if($resto==0){
			pritnOnlyScreen("\n");			
			#printf("\n","");
		}
	}
	my $resto=$cont % $cantCols;
	if($resto!=0){
		pritnOnlyScreen("\n");
		#printf("\n","");
	}
	return;	
}

sub getFiltroUsuarios{
	@filtroUsuarios=();
	my @usuarios=getUsuariosPres();
	printMenuUsuarios(3);
	my $opciones=<STDIN>;
	my @opciones=split(" ",$opciones);
	my $cantUsuarios=@usuarios;	
	foreach $opcion(@opciones){
		if($opcion=~m/^[0-9][0-9]*$/){
			if($opcion<$cantUsuarios){
				push(@filtroUsuarios,$usuarios[$opcion]);
			}
		}
	}
	print "\n";
	#print "opcion valida @filtroUsuarios\n";
	return @filtroUsuarios;
}

sub getUsuariosPres{
	opendir(PRESDIR,$PRESDIR) || die "No pudo abrirse: $!";
	my @files=readdir(PRESDIR);
	@usuarios=();
	foreach $fileName(@files){
		#print "prest file $fileName\n";
		if($fileName=~m/(..*)\.[^.][^.]*$/){
			#print "usuario $1\n";
			if(!($1 ~~ @usuarios)){
				push(@usuarios,$1);
			}
		}
	}
	#print "usuarios @usuarios\n";
	return @usuarios;
}

sub printMenuUsuarios{
	pritnOnlyScreen("Escriba los ids separados por espacio de los usuarios que desea.");
	pritnOnlyScreen("Presione enter al finalizar la eleccion.\n");
	pritnOnlyScreen("En caso de querer todos los usuarios, no ponga ningun id ");
	pritnOnlyScreen("y simplemente presione enter.\n\n");
	my $cantCols=$_[0];
	my $cont=0;
	foreach $usuario(@usuarios){
		pritnOnlyScreen($cont . "_" . $usuario,"%-32s ");
		#printf ("%-32s ",$key . "_" . $supers{$key});
		$cont++;
		my $resto=$cont % $cantCols;
		if($resto==0){
			pritnOnlyScreen("\n");			
			#printf("\n","");
		}
	}
	my $resto=$cont % $cantCols;
	if($resto!=0){
		pritnOnlyScreen("\n");
		#printf("\n","");
	}
	return;	
}

sub printWithRefLegend{
	if($opciones{"m"} and $opciones{"r"}){
		printReport("(*)Precio menor o igual a PC.\t");
		printReport("(**)Precio mayor al PC.\t");
		printReport("(***)PC no encontrado.\n\n");
		return;
	}
	if($opciones{"d"} and $opciones{"r"}){
		printReport("(*)Precio menor o igual a PC.\t");
		printReport("(**)Precio mayor al PC.\t");
		printReport("(***)PC no encontrado.\n\n");
		return;
	}
}

sub printFullReport{
	nuevoInforme();
	printHeaderReport();
	printWithRefLegend();
	opendir(PRESDIR,"$PRESDIR") || die "No pudo abrirse: $!";
	my @files=readdir(PRESDIR);
	my $cantFilter=@filtroUsuarios;
	my $hayPres=0;
	foreach $fileName(@files){
		if($fileName=~m/(..*)\.[^~.][^~.]*$/){
			$hayPres=1;
			if($cantFilter==0){
				printPresReport($fileName);
			}else{
				if($1 ~~ @filtroUsuarios){
					printPresReport($fileName);
				}			
			}
		}
	}
	if(!$hayPres){
	  printReport("\nNo se encontraron presupuestos en la carpeta $INFODIR/pres al realizar el informe\n\n");
	}
	cerrarInforme();
	if($opciones{"w"}){
	  my $numInfo=getNumInfo()-1;
	  print "Se genero el informe: $INFODIR/info_$numInfo\n\n";
	}
	return;
}

sub printHeaderReport{
	printReport("Condiciones de invocacion|");
	printReport("Opciones:[");
	foreach $key(keys %opciones){
		if($opciones{$key}){
			printReport("$key ");
		}
	}
	printReport("]|");
	#printReport("Filtros\t");
	printReport("Provincia-Super:[");
	my $cantFilt=keys %filtroSupers;	
	if($cantFilt==0){
		printReport("Todos ");
	}else{
		foreach $key(keys %filtroSupers){
			printReport($filtroSupers{$key} . " | ");
		}
	}
	#printReport("\n");
	printReport("]|Usuarios:[");
	my $cantFilt=@filtroUsuarios;	
	if($cantFilt==0){
		printReport("Todos ");
	}else{
		foreach $usuario(@filtroUsuarios){
			printReport("$usuario ");
		}
	}
	printReport("]\n\n");
	return;
}

sub printPresReport{
	#print "informe a imprimir" . $_[0] . " \n";
	printReport("Lista Presupuestada: " . $_[0] . "\n\n");
	#print $PRESDIR.$_[0];
	open(PRES,$PRESDIR . "/" . $_[0]) || die "No pudo abrirse: $!";
	if($opciones{"m"} and $opciones{"r"}){
		reportMinWithRef();
		close(PRES);
		return;
	}
	if($opciones{"d"} and $opciones{"r"}){
		reportWhereWithRef();
		close(PRES);
		return;
	}
	if($opciones{"r"}){
		reportRef();
		close(PRES);
		return;
	}
	if($opciones{"d"}){
		reportWhere();
		close(PRES);
		return;
	}
	if($opciones{"m"}){
		reportMin();
		close(PRES);
		return;
	}
	if($opciones{"f"}){
		reportMissing();		
		close(PRES);
		return;
	}
	close(PRES);
	return;
}

sub armarDetalle{
	my $cantParams=@_;
	my $detalle="";	
	if ($cantParams<3){
		my ($supers,$producto)=@_;
		my %supers=%$supers;
		my @producto=@$producto;		
		$detalle.=$producto[0];
		$detalle.=";" . $producto[1];
		$detalle.=";" . $producto[3];
		$detalle.=";" . $producto[4];
		$detalle.=";" . $supers{$producto[2]};
	}else{
		my ($supers,$producto,$productoRef)=@_;
		my %supers=%$supers;
		my @producto=@$producto;
		my @productoRef=@$productoRef;
		my $cantCamposRef=@productoRef;
		$detalle=$supers{$producto[2]};
		$detalle.=";" . $producto[0];
		$detalle.=";" . $producto[1];
		$detalle.=";" . $producto[3];
		$detalle.=";" . $producto[4];
		if($cantCamposRef==0){
			$detalle.="; no encontrado";
			$detalle.="; (***)";
		}else{
			$detalle.=";" . $productoRef[4];			
			if($producto[4]<=@productoRef[4]){
				$detalle.="; (*)";
			}else{
				$detalle.="; (**)";
			}
		}
	}
	
	return $detalle;
}

sub reportMinWithRef{
	my $cteTecho=1000000;
	my %supers=getAllSupers();
	my @filtroSupers=keys %filtroSupers;
	my $cantFilters=@filtroSupers;
	my @productoRef=();
	my @producto=();
	my $priceMinRef=$cteTecho;
	my $priceMin=$cteTecho;
	my $nroItem=-1;
	$huboDetalle=0;
	while(<PRES>){
		my $linea=$_;
		chomp($linea);
		my @campos=split(";",$linea);
		my $cantCampos=@campos;
		if ($cantCampos<5){
			next;
		}
		if($nroItem==-1){
			$nroItem=$campos[0];
		}
		if($nroItem!=$campos[0]){
			if($priceMin!=$cteTecho){
				my $detalle=armarDetalle(\%supers,\@producto,\@productoRef);
				printReport("$detalle\n");				
				$huboDetalle=1;
			}
			$nroItem=$campos[0];
			@productoRef=();
			@producto=();
			$priceMinRef=$cteTecho;
			$priceMin=$cteTecho;			
		}
		if($campos[2]<100){
			if($campos[4]<$priceMinRef){
				@productoRef=@campos;
				$priceMinRef=$campos[4];
			}
			next;	
		}
		if($cantFilters>0){
			if(!(defined $filtroSupers{$campos[2]})){
				next;
			}			
		}
		if($campos[4]<$priceMin){
			@producto=@campos;
			$priceMin=$campos[4];
		}		
	}
	if($priceMin!=$cteTecho){
		my $detalle=armarDetalle(\%supers,\@producto,\@productoRef);
		printReport("$detalle\n");
		$huboDetalle=1;
	}
	if(!$huboDetalle){
		printReport("No hubo detalles para este informe\n");		
	}
	printReport("\n");
	return $huboDetalle;
}

sub reportWhereWithRef{
	my $cteTecho=1000000;
	my %supers=getAllSupers();
	my @filtroSupers=keys %filtroSupers;
	my $cantFilters=@filtroSupers;
	my @productoRef=();
	my @producto=();
	my $priceMinRef=$cteTecho;
	my $priceMin=$cteTecho;
	my $nroItem=-1;
	my %mapGanadores=();
	my @supersGanadores=();
	
	my $huboDetalle=0;
	while(<PRES>){
		my $linea=$_;
		chomp($linea);
		my @campos=split(";",$linea);
		my $cantCampos=@campos;
		if ($cantCampos<5){
			next;
		}
		if($nroItem==-1){
			$nroItem=$campos[0];
		}
		if($nroItem!=$campos[0]){
			if($priceMin!=$cteTecho){
				my $detalle=armarDetalle(\%supers,\@producto,\@productoRef);				
				if(!(defined $mapGanadores{$producto[2]})){
					$mapGanadores{$producto[2]}=@supersGanadores;
					push(@supersGanadores,[]);
				}
				$punteroItems=$supersGanadores[$mapGanadores{$producto[2]}];
				push(@$punteroItems,$detalle);				
				$huboDetalle=1;
			}
			$nroItem=$campos[0];
			@productoRef=();
			@producto=();
			$priceMinRef=$cteTecho;
			$priceMin=$cteTecho;			
		}
		if($campos[2]<100){
			if($campos[4]<$priceMinRef){
				@productoRef=@campos;
				$priceMinRef=$campos[4];
			}
			next;	
		}
		if($cantFilters>0){
			if(!(defined $filtroSupers{$campos[2]})){
				next;
			}			
		}
		if($campos[4]<$priceMin){
			@producto=@campos;
			$priceMin=$campos[4];
		}		
	}
	if($priceMin!=$cteTecho){
		my $detalle=armarDetalle(\%supers,\@producto,\@productoRef);				
		if(!(defined $mapGanadores{$producto[2]})){
			$mapGanadores{$producto[2]}=@supersGanadores;
			push(@supersGanadores,[]);
		}
		$punteroItems=$supersGanadores[$mapGanadores{$producto[2]}];
		push(@$punteroItems,$detalle);
		$huboDetalle=1;
	}

	foreach $punteroItems (@supersGanadores){
		@items=@$punteroItems;
		foreach $itemDetalle (@items){
			printReport("$itemDetalle\n");
		}
		printReport("\n");
	}

	if(!$huboDetalle){
		printReport("No hubo detalles para este informe\n");		
	}
	printReport("\n");
	return $huboDetalle;
}

sub reportRef{
	my %supers=getAllSupers();
	my @productoRef=();
	$huboDetalle=0;
	while(<PRES>){
		my $linea=$_;
		chomp($linea);
		my @campos=split(";",$linea);
		my $cantCampos=@campos;
		if ($cantCampos<5){
			next;
		}
		
		if($campos[2]<100){
			@productoRef=@campos;
			my $detalle=armarDetalle(\%supers,\@productoRef);
			printReport("$detalle\n");				
			$huboDetalle=1;
			next;	
		}		
	}

	if(!$huboDetalle){
		printReport("No hubo detalles para este informe\n");		
	}
	printReport("\n");
	return $huboDetalle;
}

sub reportWhere{
	my $cteTecho=1000000;
	my %supers=getAllSupers();
	my @filtroSupers=keys %filtroSupers;
	my $cantFilters=@filtroSupers;
	my @producto=();
	my $priceMin=$cteTecho;
	my $nroItem=-1;
	my %mapGanadores=();
	my @supersGanadores=();
	
	my $huboDetalle=0;
	while(<PRES>){
		my $linea=$_;
		chomp($linea);
		my @campos=split(";",$linea);
		my $cantCampos=@campos;
		if ($cantCampos<5){
			next;
		}
		if($nroItem==-1){
			$nroItem=$campos[0];
		}
		if($nroItem!=$campos[0]){
			if($priceMin!=$cteTecho){
				my $detalle=armarDetalle(\%supers,\@producto);				
				if(!(defined $mapGanadores{$producto[2]})){
					$mapGanadores{$producto[2]}=@supersGanadores;
					push(@supersGanadores,[]);
				}
				$punteroItems=$supersGanadores[$mapGanadores{$producto[2]}];
				push(@$punteroItems,$detalle);				
				$huboDetalle=1;
			}
			$nroItem=$campos[0];
			@producto=();
			$priceMin=$cteTecho;			
		}
		if($campos[2]<100){
			next;	
		}
		if($cantFilters>0){
			if(!(defined $filtroSupers{$campos[2]})){
				next;
			}			
		}
		if($campos[4]<$priceMin){
			@producto=@campos;
			$priceMin=$campos[4];
		}		
	}
	if($priceMin!=$cteTecho){
		my $detalle=armarDetalle(\%supers,\@producto);				
		if(!(defined $mapGanadores{$producto[2]})){
			$mapGanadores{$producto[2]}=@supersGanadores;
			push(@supersGanadores,[]);
		}
		$punteroItems=$supersGanadores[$mapGanadores{$producto[2]}];
		push(@$punteroItems,$detalle);
		$huboDetalle=1;
	}

	foreach $punteroItems (@supersGanadores){
		@items=@$punteroItems;
		foreach $itemDetalle (@items){
			printReport("$itemDetalle\n");
		}
		printReport("\n");
	}

	if(!$huboDetalle){
		printReport("No hubo detalles para este informe\n");		
	}
	printReport("\n");
	return $huboDetalle;
}

sub reportMin{
	my $cteTecho=1000000;
	my %supers=getAllSupers();
	my @filtroSupers=keys %filtroSupers;
	my $cantFilters=@filtroSupers;
	my @producto=();
	my $priceMin=$cteTecho;
	my $nroItem=-1;
	$huboDetalle=0;
	while(<PRES>){
		my $linea=$_;
		chomp($linea);
		my @campos=split(";",$linea);
		my $cantCampos=@campos;
		if ($cantCampos<5){
			next;
		}
		if($nroItem==-1){
			$nroItem=$campos[0];
		}
		if($nroItem!=$campos[0]){
			if($priceMin!=$cteTecho){
				my $detalle=armarDetalle(\%supers,\@producto);
				printReport("$detalle\n");				
				$huboDetalle=1;
			}
			$nroItem=$campos[0];
			@producto=();
			$priceMin=$cteTecho;			
		}
		if($campos[2]<100){
			next;	
		}
		if($cantFilters>0){
			if(!(defined $filtroSupers{$campos[2]})){
				next;
			}			
		}
		if($campos[4]<$priceMin){
			@producto=@campos;
			$priceMin=$campos[4];
		}		
	}
	if($priceMin!=$cteTecho){
		my $detalle=armarDetalle(\%supers,\@producto);
		printReport("$detalle\n");
		$huboDetalle=1;
	}
	if(!$huboDetalle){
		printReport("No hubo detalles para este informe\n");		
	}
	printReport("\n");
	return $huboDetalle;
}

sub reportMissing{
	my %supers=getAllSupers();
	my @productoFaltante=();
	$huboDetalle=0;
	while(<PRES>){
		my $linea=$_;
		chomp($linea);
		my @campos=split(";",$linea);
		my $cantCampos=@campos;
		
		if (($cantCampos<5)){
			#print "arreglo @campos fin";			
			@productoFaltante=@campos;
			my $detalle=$productoFaltante[0];
			$detalle.=";" . $productoFaltante[1];
			#print "a ver que onda $cantCampos\n";
			printReport("$detalle\n");				
			$huboDetalle=1;
			next;	
		}		
	}

	if(!$huboDetalle){
		printReport("No hubo detalles para este informe\n");		
	}
	printReport("\n");
	return $huboDetalle;
}

