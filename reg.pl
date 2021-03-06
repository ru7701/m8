#!/usr/bin/perl -w


#модули в составе ядра
use strict;
use warnings;
#no warnings 'layer';

use Cwd;
use POSIX qw(strftime);
use File::Path qw(make_path rmtree);
use File::Copy qw(copy move);
use File::Copy::Recursive qw(dircopy);
use File::Find::Rule;
use JSON; #Perl 5.14 been a core module

#инсталлируемые модули 	(perl -MCPAN -e shell)
#use Encode 'encode', 'decode'; #модуль указан как базовый, но ставить себя в 5.22.1.3 все равно просит
use CGI qw(:all); # модуль удален из базовой комплектации начиная с версии 5.22
use CGI::Carp qw(warningsToBrowser fatalsToBrowser); #идет в составе CGI
use XML::LibXML;
use XML::LibXML::PrettyPrint;
#нет в ubuntu
use Digest::MurmurHash3 qw( murmur128_x64 );
use XML::XML2JSON;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
#use FindBin qw($Bin);

use Time::HiRes qw( time gettimeofday );#gettimeofday

#установление возможности записывать файлы с правами 777
umask 0;

my $disk = '';
BEGIN {
   if ($^O eq 'MSWin32'){
      require Win32::Symlink;
      Win32::Symlink->import();
   }
}
$disk = "C:" if $^O eq 'MSWin32';

my %setting = (
	'guestDays' 	=> 30,
	'userDays'		=> 60,
	'userPassword'	=> 'example',
	'forceDbg'		=> 0,
	'chMod'			=> '0777',
	'platformLevel'	=> 3,
	'tempfsFolder'	=> '/mnt/tmpfs'
);
my $localForce = 1; #разрешение делать записи любым юзерам на любой стороне, в противном случае это будет разрешено лишь на сервере

my $reindexDays = 14;
my $passwordFile = 'password.txt';
my $sessionFile = 'session.json';
my $stylesheetDir = 'xsl';
my $defaultAvatar = 'formulyar';
my $startAvatar = 'start';
my $defaultUser = 'guest';
my $defaultFact = 'n';
my $defaultQuest = 'n';
my $admin = 'admin';
my $canonicalHomeAvatar = 'formulyar';	
my $tNode = '$t';
my @sentence = ( undef, 'subject', 	'predicate',	'object',	'modifier' );
my @matrix = ( undef, $defaultFact, $defaultFact, $defaultQuest );
my @level = ( 'system', 'prefix', 'fact', 'quest' );
my @number = (	'name',		'subject', 	'predicate',	'object',	'modifier', 'add' );
my @transaction = ( 'DOCUMENT_ROOT', 'REMOTE_ADDR', 'HTTP_USER_AGENT', 'REQUEST_URI', 'QUERY_STRING', 'HTTP_COOKIE', 'REQUEST_METHOD', 'HTTP_X_REQUESTED_WITH' );#, 'HTTP_USER_AGENT', 'HTTP_ACCEPT_LANGUAGE', 'REMOTE_ADDR' $$transaction{'QUERY_STRING'}
my @mainTriple = ( 'n', 'r', 'i' );
my %formatDir = ( '_doc', 1, '_json', 1, '_pdf', 1, '_xml', 1 );
my @superrole = ( 'triple', 'role', 'role', 'role', 'quest', 'subject', 'predicate', 'object' );
my @superfile = ( undef, 'port', 'dock', 'terminal' ); 


my $type = 'xml';

my $userDir = 'u';
my $auraDir = 'a';
my $planeDir = '.plane';
my $planeDir_link = 'p';
my $indexDir = 'm8';

my $logPath = $defaultAvatar.'/log'; #'../log';$userDir.'/'.
my $userPath = $indexDir.'/author';
my $configDir = 'config';
my $configPath = $userDir.'/'.$defaultAvatar.'/'.$configDir; #'../'.$configDir;
my $sessionPath = $configPath.'/temp_name';

my $errorLog = $logPath.'/error_log.txt';
my $logFile = 'data_log.txt';
my $log = $logPath.'/'.$logFile;
my $log1 = $logPath.'/control_log.txt';
my $guest_log = $logPath.'/guest_log.txt';
my $trashPath = $logPath.'/trash';
my $platformGit = '/home/git/_master/gitolite-admin/.git/refs/heads/master';
my $typesDir = 'm8';
my $typesFile = 'type.xml';

my $JSON = JSON->new->utf8;
my $XML2JSON = XML::XML2JSON->new(pretty => 'true');

warn 'script: '.$0;
my @bin = split '/', $0;
if ($bin[0]){
	if ( $bin[0]=~/:$/ ){ $disk = $bin[0] }
	else { 
		warn ' Not absolute path of script!!'; 
		exit 
	}
}
$bin[4] || warn ' Wrong absolute path!!' && exit;

my @planePath = splice( @bin, 1, -3 );
my $planePath = join '/', @planePath;
my $planeRoot = $disk.'/'.$planePath.'/';

chdir $planeRoot;
#my @head = split '/', &getFile ( '.plane/'.$univer.'/formulyar/.git/HEAD' );
#my $univer = $planePath[$#planePath];
#my $branche = $planePath[$#planePath-1];

#if ( $branche eq '.public' ){
$planePath[$#planePath]=~/^(\w+)-*(.*)$/;
my $univer = $1;
my $branche = $2 || 'master';
#}

my $chmod = $setting{'chMod'};
$chmod = &getSetting('chMod');
my $dbg = &getSetting('forceDbg');
my $prefix = '/';

my $platformLevel = &getSetting('platformLevel');
if ( defined $ENV{DOCUMENT_ROOT} ){
	my @dr = split '/', $ENV{DOCUMENT_ROOT};
	$dr[$#dr] || pop @dr;
	$platformLevel = $#dr;
}
for my $n ( $platformLevel..$#planePath ){ $prefix .= $planePath[$n].'/' }
my $multiRoot = join '/', splice( @planePath, 0, -2 );
$multiRoot = $disk.'/'.$multiRoot.'/';
warn 'prefix: '.$prefix;

if ( defined $ENV{DOCUMENT_ROOT} ){	
	warn 'WEB TEMP out!!';
	my $cookiePrefix = '';#$prefix; #&utfText(  );
	#$cookiePrefix =~ s!^/(.*).public/$!$1!;
	#$cookiePrefix =~ tr!/!.!;
	$dbg = 1 if 0 or cookie($cookiePrefix.'debug') ne '';
	copy( $log, $log.'.txt' ) or die "Copy failed: $!" if -e $log and $dbg; #копировать лог не ниже, т.е. не после возможного редиректа
	&setWarn( " Обработка запроса в сайте $ENV{DOCUMENT_ROOT}", $log);#	
	copy( $logPath.'/env.json', $logPath.'/env.json.json' ) or die "Copy failed: $!" if -e $logPath.'/env.json' and $dbg; #копировать лог не ниже, т.е. не после возможного
	&setFile( $logPath.'/env.json', $JSON->encode(\%ENV) ) if $dbg;
	my $dry;
	my $head;
	if ( -d '.plane/'.$univer ){
		&setWarn( "  Проверка необходимости сушки индекса после коммита");#	
		#if ( $^O ne 'MSWin32' ){ #and -d '/home/git'
		#	&setWarn( "   Обнаружена работа на сервере");#	
		if(0){
			for my $userName ( grep{ not $dry and not /^_/ and -d $planeDir.'/'.$_.'/.git' and -e $planeDir.'/'.$_.'/.git/refs/heads/'.$branche } &getDir( $planeDir, 1 ) ){ 
				&setWarn( "    Проверка коммитов в репозитории $userName");#	
				$head = &getFile( $planeDir.'/'.$userName.'/.git/refs/heads/'.$branche );
				$dry = 1 if not -e $userDir.'/'.$userName.'/'.$branche or &getFile( $userDir.'/'.$userName.'/'.$branche ) ne $head;
			}
		}
		#}
	}
	else { $dry = 1 }
	&dryProc2( 1 ) if $dry;
	my %temp = (
		'time'		=>	time,
		'univer'	=>	$univer,
		'planeRoot'	=>	$planeRoot,
		'prefix'	=>	$prefix,
		'record'	=>	0,
		'adminMode'	=> 	$dbg,
		'branche'	=>	$branche,
		'dry'		=>	$dry,
		'head'		=>	$head,
		'multiRoot' =>	$multiRoot,
		'fact'		=>	'n',
		'quest'		=>	'n',
	);
	#$temp{'adminMode'} = "true" if $dbg;
	for my $param ( @transaction ){	
		&setWarn('  ENV '.$param.': '.$ENV{$param});
		$temp{$param} = $ENV{$param} 
	}
	( $temp{'seconds'}, $temp{'microseconds'} ) = gettimeofday;
	$temp{'version'} = &getFile( $planeDir.'/'.$defaultAvatar.'/version.txt' ) || 'v0';
	foreach my $itm ( split '; ', $temp{'HTTP_COOKIE'} ){
		&setWarn('  Прием куки '.$itm);
		my ( $name, $value ) = split( '=', $itm );
		if ( $name eq $cookiePrefix.'user' ){
			$temp{'tempkey'} = $value;
			if ( $value eq 'guest' ){ $temp{'user'} = 'guest' }
			else { $temp{'user'} = &getFile( $sessionPath.'/'.$value.'/value.txt' ) if -e $sessionPath.'/'.$value.'/value.txt' }
		}
		elsif ( $name eq $cookiePrefix.'debug' ){		$temp{'debug'} = $value if $value	}
	}
	$temp{'user'} = $defaultUser if not defined $temp{'user'} or not $temp{'user'};
	$temp{'avatar'} = $temp{'ctrl'} = $univer;
	$temp{'mission'} = $temp{'format'} = 'html';
	$temp{'ajax'} = $temp{'HTTP_X_REQUESTED_WITH'} if $temp{'HTTP_X_REQUESTED_WITH'}; 
	$temp{'wkhtmltopdf'} = 'true' if $temp{'HTTP_USER_AGENT'}=~/ wkhtmltopdf/ or $temp{'HTTP_USER_AGENT'}=~m!Qt/4.6.1!;
	&setWarn( " Завершение инициализации процесса");#	
	
	my @request_uri = split /\?/, $temp{'REQUEST_URI'};
	$request_uri[0]=~s!^$temp{'prefix'}!!;	
	my $q = CGI->new();
	$q->charset('utf-8');

	if ( $request_uri[0] ne '' && -d $request_uri[0]) { 
		&setWarn( "  В пожелании $temp{'REQUEST_URI'} директория $request_uri[0] действительна. Идет прием факта/квеста" );# стирка 	
		$temp{'workpath'} = $request_uri[0];
		my @path = split '/', $temp{'workpath'};
		if ( $path[0] ne 'm8' ){
			&setWarn( "  Обнаружен регистр миссии $path[0]" );
			$temp{'mission'} = $temp{'format'} = shift @path;
			if ( $temp{'format'} eq $auraDir or $temp{'format'} eq $defaultAvatar ){ 	$temp{'format'} = 'html'	}
			else {									$temp{'format'} =~s/^_//	}
		}
		if ( @path ){
			if ( $path[0] ne 'm8' ){
				$temp{'ctrl'} = shift @path;
			}
		}		
		elsif ( $temp{'mission'} eq $defaultAvatar and $temp{'user'} eq $defaultUser ) {	$temp{'ctrl'} = $defaultAvatar } #Это указание не дает выйти на текущие контроллеры при переходе на страницу авторизации }
		if ( @path ){
			$temp{'m8path'} = join '/', @path;
			if ( $path[2] ){
				$temp{'fact'} = $path[2];
				if ( $path[3] ){
					$temp{'quest'} = $path[3];
					#( $matrix[1], $matrix[4] ) = ( $temp{'fact'}, $temp{'quest'} );
				}
				#else { $matrix[3] = $matrix[4] = $temp{'fact'} }
			}
		}
	}
	&setWarn( " Завершение разбора рабочего пути");#	
	#if ( $ENV{'QUERY_STRING'} =~ /^modifier=([\w\-\d]+)$/ and -d 'm8/n/'.$1 ){ $temp{'modifier'} = $1 }
	#else { $temp{'modifier'} = 'n' }
	if ( $ENV{'QUERY_STRING'} =~ /^reindex=(\d)$/ ){
		&dryProc2( $1 );
		print $q->header( -location => $ENV{REQUEST_SCHEME}.'://'.$ENV{HTTP_HOST}.$temp{'prefix'}.$auraDir.'/'.$temp{'ctrl'} )
	}
	elsif ( $temp{'format'} eq 'pdf' or $temp{'format'} eq 'doc' ){
		&setWarn( "  Выдача не текстовой информации (pdf, docx)" );#	
		my $extensiton = $temp{'format'};	
		if ( $temp{'format'} eq 'pdf' ){
			&setWarn( "   Формирование pdf-файла запросом $ENV{HTTP_HOST}/$auraDir/$temp{'ctrl'}/$temp{'m8path'}" );#
			my $req = $ENV{HTTP_HOST}.$temp{'prefix'}.$auraDir.'/'.$temp{'ctrl'}.'/'.$temp{'m8path'};
			$req .= '/?'.$temp{'QUERY_STRING'};
			system ( 'wkhtmltopdf '.$req.' '.$planeRoot.$temp{'m8path'}.'/report.pdf'.' 2>'.$planeRoot.$logPath.'/wkhtmltopdf.txt' ); #здесь нужно перевести в папку юзера
		}
		elsif ( $temp{'format'} eq 'doc' ){
			&setWarn( "   Формирование doc-файла" );#
			$ENV{'QUERY_STRING'} =~ /print=(\d+)/;
			my $repNum = $1;
			rmtree $temp{'m8path'}.'/report' if -d $temp{'m8path'}.'/report';
			unlink $temp{'m8path'}.'/report.docx' if -e $temp{'m8path'}.'/report.docx';
			dircopy $planeDir.'/'.$temp{'ctrl'}.'/template/'.$repNum.'/report', $temp{'m8path'}.'/report';
			-e $temp{'m8path'}.'/report/_rels/.rels' || copy( $planeDir.'/'.$temp{'ctrl'}.'/template/'.$repNum.'/report/_rels/.rels', $temp{'m8path'}.'/report/_rels/.rels' ) || die "Copy for Windows failed: $!";
			my $xmlFile = $planeRoot.$temp{'m8path'}.'/temp.xml';
			&setFile( $xmlFile, &getDoc( \%temp ) );
			my $xslFile = $planeRoot.$planeDir.'/'.$temp{'ctrl'}.'/'.$stylesheetDir.'/'.$temp{'ctrl'}.'.xsl';
			my $documentFile = $planeRoot.$temp{'m8path'}.'/report/word/document.xml';
			my $status = system ( 'xsltproc -o '.$documentFile.' '.$xslFile.' '.$xmlFile.' 2>'.$planeRoot.$logPath.'/xsltproc_generate_docx.txt' );#
			&setWarn( "   documntXML: $status" );#
			my $zip = Archive::Zip->new();
			$zip->addTree( $temp{'m8path'}.'/report/' );
			unless ( $zip->writeToFileNamed($temp{'m8path'}.'/report.docx') == AZ_OK ) {
				die 'write error';
			}
			$extensiton = 'docx';
		}
		if ( $temp{'format'} eq 'pdf' and 1 ){
			&setWarn( '   редирект на '.$temp{'prefix'}.$temp{'m8path'}.'/report.'.$extensiton );
			print $q->header(-location => $temp{'prefix'}.$temp{'m8path'}.'/report.'.$extensiton );
		}
		else {
			&setWarn( '   редирект на '.$ENV{REQUEST_SCHEME}.'://'.$ENV{HTTP_HOST}.$temp{'prefix'}.$auraDir.'/'.$temp{'ctrl'}.'/'.$temp{'m8path'}.'/report.'.$extensiton );
			print $q->header(-location => $ENV{REQUEST_SCHEME}.'://'.$ENV{HTTP_HOST}.$temp{'prefix'}.$auraDir.'/'.$temp{'ctrl'}.'/'.$temp{'m8path'}.'/report.'.$extensiton );
		}
	}
	else{
		&setWarn( "  Выдача текстовой информации" );
		my %cookie;
		$temp{'user'} = $cookie{'user'} = $defaultUser if not -d $planeDir.'/'.$temp{'user'}; 
		&washProc( \%temp, \%cookie ) if $temp{'REQUEST_METHOD'} eq 'POST' or $temp{'QUERY_STRING'};# || return 'user for server';# and $temp{'QUERY_STRING'}=~/&/ or {'QUERY_STRING'} eq 'a=');
		$temp{'modifier'} = 'n' if not defined $temp{'modifier'};	
		$temp{'fact'} = $temp{'quest'} = $defaultFact if not defined $temp{'fact'};	
		$temp{'ctrl'} = $defaultAvatar if $temp{'mission'} eq $defaultAvatar;	
		my @cookie;
		for (keys %cookie){	
			&setWarn( "   Добавление куки $cookiePrefix.$_: $cookie{$_}");#		
			push @cookie, $q->cookie( -name => $cookiePrefix.$_, -expires => '+1y', -value => $cookie{$_} ) 
		}
		if ( 0 and ( $temp{'mission'} eq $defaultAvatar and $temp{'user'} eq 'guest' ) ){
			my $location = $ENV{REQUEST_SCHEME}.'://'.$ENV{HTTP_HOST}.$temp{'prefix'};
			if ( defined $temp{'message'} and $temp{'message'} eq 'OK' ){ $location .= &m8req( \%temp ).'/'}
			else { $location .= $defaultAvatar.'/?error='.$temp{'message'} }
			print $q->header( -location => $location, -cookie => [@cookie] )
		
		}
		elsif ( 0 ) {
			&setWarn( '   Вывод в web c редиректом' );
			#copy( $log, $log.'.txt' ) or die "Copy failed: $!" if $dbg; #копировать лог не ниже, т.е. не после возможного редиректа
			my $location = $ENV{REQUEST_SCHEME}.'://'.$ENV{HTTP_HOST}.$temp{'prefix'};
			if ( defined $temp{'message'} and $temp{'message'} ne 'OK' ){ $location .= $defaultAvatar.'/?error='.$temp{'message'} }
			else { $location .= &m8req( \%temp ) }
			print $q->header( -location => $location, -cookie => [@cookie] )# -status => '201 Created' #куки нужны исключительно для случая указания автора		
		}		
		elsif ( 
			( 
				$temp{'mission'} ne $defaultAvatar or $temp{'user'} eq 'guest' 
			) and 
			( 
				not $temp{'QUERY_STRING'} or 
				( not $temp{'record'} and not defined $temp{'message'} ) or 
				( not $temp{'activity'} and not defined $temp{'message'} ) or
				defined $temp{'ajax'} or 
				defined $temp{'wkhtmltopdf'} 
			) 
		) { 	
		# ( not $temp{'record'} and not defined $temp{'message'} ) - для того что бы, например, указание в 'QUERY_STRING' только модификатора не приводило к редиректу
		#$temp{'QUERY_STRING'} $temp{'record'} or $temp{'QUERY_STRING'}=~/^n1464273764-4704-1/ $ENV{'HTTP_HOST'} eq 'localhost'$ENV{'REMOTE_ADDR'} eq "127.0.0.1"  =~/(^|&)a=(&|$)/ 
		#elsif (1) { and not $temp{'QUERY_STRING'}=~/^.*[?&]a=$/
			&setWarn( '   Вывод в web без редиректа (номеров: '.$temp{'record'}.')' );		
			my $doc;
			print $q->header( 
				-type 			=> 'text/'.$temp{'format'}, 
				-cookie 		=> [@cookie]
				#-expires		=> 'Sat, 26 Jul 1997 05:00:00 GMT',
				#-charset		=> 'utf-8',
				# always modified
				# -Last_Modified	=> strftime('%a, %d %b %Y %H:%M:%S GMT', gmtime),
				# HTTP/1.0
				# -Pragma			=> 'no-cache',
				# -Note 			=> 'CACHING IS DISABLED IN SCRIPT REG.PL',
				# HTTP/1.1 + IE-specific (pre|post)-check
				#-Cache_Control => join(', ', qw(
				#	private
				#	no-cache
				#	no-store
				#	must-revalidate
				#	max-age=0
				#	pre-check=0
				#	post-check=0
				#)),
			);
			if ( $temp{'format'} eq 'json' ){
				&setWarn ('    Вывод в json-варианте');
				$doc = $JSON->encode(\%temp);
				&setFile( $logPath.'/temp.json', $doc ) if $dbg;
			}
			else {
				&setWarn ('    Вывод в xml-варианте');
				$doc = &getDoc( \%temp );
				if ( $temp{'format'} eq 'html' ){
					&setWarn("     Вывод temp-а под аватаром: $temp{'ctrl'}");	
					my $xslFile = $planeDir.'/'.$temp{'ctrl'}.'/'.$stylesheetDir.'/'.$temp{'ctrl'}.'.xsl';
					my $tempFile = int( rand( 999 ) );						
					if (1) { 
						my $stl = '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:include href="'.$planeRoot.$xslFile.'"/>
</xsl:stylesheet>';#<xsl:include href="'.$planeRoot.'m8/type.xsl"/>
						$xslFile = $logPath.'/trash/'.$tempFile.'.xsl';
						&setFile( $xslFile, $stl );
						
					}
					my $trashTempFile = $logPath.'/trash/'.$tempFile.'.xml';
					&setFile( $trashTempFile, $doc );
					copy( $planeRoot.$logPath.'/out.txt', $planeRoot.$logPath.'/out.txt.txt' ) or die "Copy failed: $!" if -e $log and -e $logPath.'/out.txt' and $dbg;
					$doc = system ( 'xsltproc '.$planeRoot.$xslFile.' '.$planeRoot.$trashTempFile.' 2>'.$planeRoot.$logPath.'/out.txt' );#
					$doc =~s/(\d*)$//;
					print $1 if $dbg and $1
				}	
			}
			print $doc;
		}
		else {
			&setWarn( '   Вывод в web c редиректом' );
			#copy( $log, $log.'.txt' ) or die "Copy failed: $!" if $dbg; #копировать лог не ниже, т.е. не после возможного редиректа
			my $location = $ENV{REQUEST_SCHEME}.'://'.$ENV{HTTP_HOST}.$temp{'prefix'};
			if ( defined $temp{'message'} and $temp{'message'} ne 'OK' ){ $location .= $defaultAvatar.'/?error='.$temp{'message'} }
			else { $location .= &m8req( \%temp ) }
			print $q->header( -location => $location, -cookie => [@cookie], -status => "303 See Other")# Без установления статуса 301 в браузер уходит 302 (не найдено) и при нажатии "назад" браузер не сразу понимает как можно перейти на пустое место - секунду демонстрируется соответствующая страница. Куки нужны исключительно для случая указания автора		
		}			
	}
}
else {
	&setWarn (' Ответ на запрос с локалхоста', $log1);
	&dryProc2( @ARGV );	
	if ( 0 and &getSetting('forceDbg') ){
		my $zip = Archive::Zip->new();
		$zip->addTree( $planeRoot );
		unless ( $zip->writeToFileNamed( '../formulyar.zip') == AZ_OK ) {
			die 'write error';
		}
	
	}
}

exit;

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ФУНКЦИИ !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

######### функции первого порядка ##########
sub washProc{
	my ( $temp, $cookie ) = @_;
	&setWarn( "		wP @_" );
	my @num;
	my %types = &getJSON( $typesDir, 'type' );	
	if ( $$temp{'REQUEST_METHOD'} eq 'POST' ){
		&setWarn( "		wP  Запись файла" );# 
		my $req = new CGI; 
		my $DownFile = $req->param('file'); 
		$DownFile =~/tsv$/ || $DownFile =~/txt$/ || $DownFile =~/csv$/ || $DownFile =~/svg$/ || return;
		my @text;			
		while ( <$DownFile> ) { 
			s/\s+\z//;
			if ( $DownFile =~/svg$/ ){
				s/\t/ /g;
				$text[0] .= $_;
			}
			else { push @text, Encode::decode_utf8( $_ ) }
		}
		$text[0] =~ s/^.*(<svg .+)$/$1/ if $DownFile =~/svg$/;
		$$temp{'fact'} = $defaultFact if not defined $$temp{'fact'};
		$$temp{'quest'} = $defaultQuest if not defined $$temp{'quest'};
		my $iName = &setName( 'i', $$temp{'user'}, @text );
		my $trName =  &setName( 'd', $$temp{'user'}, $$temp{'fact'}, 'n', $iName );
		my @val = ( $trName, $$temp{'fact'}, 'n', $iName, 'n', 1 );#$$temp{'quest'}, 1 
		push @num, \@val;
	}
	else {
		&setWarn( "		wP  Имеется строка запроса $$temp{'QUERY_STRING'}. Идет идет ее парсинг" );# 
		my %param;
		$$temp{'QUERY_STRING'} =~ s/%0D//eg; #Оставляем LA(ака 0A или \n), но убираем CR(0D). Без этой обработки на выходе получаем двойной возврат каретки помимо перевода строки если данные идут из textarea
		#my $shy = '&shy;';
		#		$$temp{'QUERY_STRING'} =~ s/\&#//;
		#		$$temp{'QUERY_STRING'} =~ s/$shy//;
		#		$$temp{'QUERY_STRING'} =~ s/\&\w\w\w\;//; #убить символы типа &shy;
				
		$$temp{'QUERY_STRING'} = &utfText($$temp{'QUERY_STRING'});
		$$temp{'QUERY_STRING'} = Encode::decode_utf8($$temp{'QUERY_STRING'});
			
		for my $pair ( split( /&/, $$temp{'QUERY_STRING'}  ) ){
			&setWarn( "		wP   Первичный анализ пары $pair" );	
			my ($name, $value) = split( /=/, $pair );
			next if $name eq 'user';
			$param{$name} = $value; #&utfText($value);
			if ( $name eq 'logout' ){ $$temp{'logout'} = delete $$temp{'user'} }
			elsif ( $name eq 'debug' ){ 
				&setWarn( "		wP    Переключение режима отладки" );	
				$$temp{'message'} = 'OK';
				if ( $$temp{'debug'} ){ $$cookie{'debug'} = '' }
				else { $$temp{'debug'} = $$cookie{'debug'} = time }
			}			
			elsif ( $name =~/^\w\D+$/ ) { 
				&setWarn( "		wP     Детектирован простой корневой параметр" );
				if ( defined $types{$name} ){ $$temp{'record'} = $$temp{'record'} + 1 }
				else { $$temp{$name} = $param{$name} } 
			}
			elsif ( $name =~/^\w[\d_\w\-]*$/ ){ # здесь должно быть $name =~/^\w[\d_\-]*$/ но пока есть именованные юзеры все сложно
				&setWarn( "		wP     Детектирован элемент создания номера" );
				$$temp{'record'} = $$temp{'record'} + 1;
			}

		}
		
		#весь блок работы с матрицей нужно уводить в работу с пустотой, т.к. может быть и не 'а', а 'b' и 'с' и 'd'.
		#&setWarn( "		wP  Имеется строка запроса $$temp{'QUERY_STRING'}. Идет идет ее парсинг" );
		#if ( defined $param{'a'} ){
		#	$$temp{'modifier'} = $$temp{'fact'} if not defined $$temp{'modifier'};
		#	$matrix[3] = $$temp{'fact'};
		#}
		#else{
		#	$$temp{'modifier'} = 'n' if not defined $$temp{'modifier'} or not -d 'm8/n/'.$$temp{'modifier'} or $$temp{'modifier'} eq $$temp{'fact'};
		#	$matrix[1] = $$temp{'fact'};
		#}
		#for my $ps ( 1..3 ){
		#	$matrix[$ps] = $$temp{$sentence[$ps]} if defined $$temp{$sentence[$ps]} 
		#}
		#keys %param || return;
		if ( not $$temp{'user'} ){
			&setWarn( "		wP   Найден запрос смены автора" );# 
			if ( defined $$temp{'login'} or defined $$temp{'new_author'} ){
				&setWarn( "		wP    Процедура авторизации" );# 		
				my %pass;
				for my $pass ( grep { defined $param{$_} } ( 'password', 'new_password', 'new_password2' ) ){ $pass{$pass} = $param{$pass} 	}
				$$temp{'message'} = &parseNew ( $temp, \%pass );
				return if $$temp{'message'};
				if ( defined $$temp{'new_author'} ){
					&setWarn('		wP    фиксация создания автора '); 
					$$temp{'fact'} = $$temp{'quest'} = $defaultFact;
					$$temp{'user'} = $pass{'new_password'};
					$$temp{'user'} = $$temp{'new_author'};
					my @value = ( 'd', @mainTriple, $$temp{'user'}, $$temp{'quest'}, 1 );
					push @num, \@value;
					my $data = join "\t", @mainTriple;
					&setFile( $$temp{'user'}.'/tsv/d/value.tsv', $data );
					&rinseProc ( 'd', $data)
				}
				else { $$temp{'user'} = $$temp{'login'}	}
				-d '.plane/'.$$temp{'user'} || mkdir '.plane/'.$$temp{'user'};
				my $sessionListFile = $userDir.'/'.$$temp{'user'}.'/'.$sessionFile;
				my $tempName = 'u';
				$tempName .= murmur128_x64(rand(10000000));
				my %tempkey = &getHash( $sessionListFile );
				$tempkey{$tempName} = $$temp{'time'};
				&setFile( $sessionListFile, $JSON->encode(\%tempkey) );
				&setFile( $sessionPath.'/'.$tempName.'/value.txt', $$temp{'user'} );
				$$cookie{'user'} = $tempName;
			}
			else { 
				&setWarn( "		wP    Процедура разлогирования" );#
				my $sessionListFile = $userDir.'/'.$$temp{'logout'}.'/'.$sessionFile;
				if ( -e $sessionListFile ){
					&setWarn( "		wP     Удаление временного ключа $$temp{'tempkey'}" );#
					my %tempkey = &getHash( $sessionListFile );	
					delete $tempkey{$$temp{'tempkey'}};
					if ( keys %tempkey ){ &setFile( $sessionListFile, $JSON->encode(\%tempkey) ) }
					else { unlink $sessionListFile } 
				}
				rmtree $sessionPath.'/'.$$temp{'tempkey'} if -d $sessionPath.'/'.$$temp{'tempkey'};
				$$cookie{'user'} = $defaultUser 
			}
			$$temp{'message'} = 'OK';
		}
		elsif ( defined $param{'z0'} and $param{'z0'} eq 'd' ){
			&setWarn( "		wP   Найден запрос удаления автора" );
			my @value = ( 'd' );
			push @num, \@value;
			$$cookie{'user'} = $defaultUser
		}
		elsif ( $$temp{'record'} and ( $localForce or $^O ne 'MSWin32' or $$temp{'user'} =~/^user/ or $$temp{'user'} eq 'guest' ) ) {	#and ( $localForce or $^O ne 'MSWin32' or $$temp{'user'} =~/^user/ or $$temp{'user'} eq 'guest' ) 
			&setWarn( "		wP   Поиск и проверка номеров в строке запроса $$temp{'QUERY_STRING'}" );# стирка 
			#my @value; #массив для контроля повторяющихся значений внутри триплов
			my %table; #таблица перевода с буквы предлложения на номер позиции в процессе
			my $a = $$temp{'fact'};
			my $m = $$temp{'modifier'} || 'n';# if defined $$temp{'modifier'} and $$temp{'modifier'};
			my $o = 'r';
			my %predicate;
			for my $pair ( split( /&/, $$temp{'QUERY_STRING'}  ) ){
				&setWarn('		wP    итоговый парсинг пары >'.$pair.'<');
				my ($name, $value) = split(/=/, $pair);
				next if $name eq '_';#пара с именем '_' добавляется только для того что бы избежать кэширования запроса.
				$name = $types{$name} if defined $types{$name};
				next if $name eq 'user' or defined $$temp{$name};
				####  работа с значением  ####
				#$value =~ s/^\+$//;
				$value =~ s/^\s+//;
				$value =~ s/\s+$//;
				$value =~ s/\&#//;
				my $shy = '&shy;';
				$value =~ s/$shy//;
				$value =~ s/\&\w\w\w\;//; #убить символы типа &shy;
				$$temp{'n'} = $value if $name eq 'n'; #специально присваивается до последующего преобразования, что бы на выводе число (1) не перешло в форму кода (r1) 
				if ( not $value and $value ne '0' ){ 
					&setWarn('		wP     присвоение пустого значения');
					if ( defined $predicate{$name} ){ $value = $predicate{$name} }
					elsif ( $name ne 'm' and $name ne 'a' ) { $value = 'r' } 
				} #0 - тоже значение
				elsif ( $value=~m!^/m8/(\w)/([1-5])$! and defined $table{$1} and $num[$table{$1}][$2]  ){
					&setWarn('		wP     присвоение значения по ссылке');
					$value = $num[$table{$1}][$2] 
				}
				elsif ( $value=~/^-?\d{1,100}[,.]*\d{0,50}$/ ){ #$value=~/^-{0,1}\d{1,15}[,\.]*\d{0,8}$/ 
					&setWarn('		wP     присвоение цифрового значения');
					$value =~ tr/,/./;
					#$value =~ s/$(-?)0*(\d)/$1$2/;
					$value = $value + 0;
					$value =~ tr/./_/;
					$value = 'r'.$value 
				}
				elsif ( $value=~m!^/m8/[dirn]/([dirn][\d\w_\-]*)$! or $value=~m!^([dirn][\d\w_\-]*)$!  ){ #or ( ( $name =~/^[a-z]+[0-2]$/ or $name eq 'r' ) and $value=~m!^([dirn])$!)
					&setWarn('		wP     оставление значения '.$value.' как есть ('.$1.')');
					$value =  $1 
				}
				else {
					&setWarn('		wP     запрос карты');
					&setWarn('		wP: '.$value );
					my @value = split "\n", $value;
					$value = &setName( 'i', $$temp{'user'}, @value );
					if ( $value[1] and $value[1]=~/^xsd:(\w+)$/ ){
						&setWarn('		wP      запрос создания именнованой карты');
						#здесь еще нужно исключить указание одному имени разных типов
						$types{$value[0]} = $$temp{'fact'};
						#&setXML ( $typesDir, 'type', \%types );
						&rinseProc3 ( 'type', %types )
					}
				} 
				####  работа с именем  ####
				if ( $name eq 'a0' ){
					&setWarn("			wP      $pair: демонтаж (подлеж.: $a; обст.: $m)" );
					my @triple = &getTriple( $$temp{'user'}, $value );
					if ( $triple[2] eq 'r' ){
						$triple[4] = 'n'; #из-за этого момента нельзя использовать 'r' в квестах (не используются и цифры тут, т.к. они могут сильно мешать установлению иерархии)
						#( $triple[4] ) = &getDir( $planeDir.'/'.$$temp{'user'}.'/tsv/'.$value, 1 );
						#&setWarn("		wP       присвоение модификатора $triple[4]");
					}
					else { $triple[4] = $m }
					push @num, \@triple;
				}
				elsif( $name eq 'a' ){
					&setWarn("		wP     $pair: смена значения факта (обст.: $m)" );
					if ( not $value ){ 
						&setWarn("		wP      $pair: создание новой сущности" );
						my $s = @num;
						$value = 'n'.$$temp{'seconds'}.'-'.$$temp{'microseconds'}.'-'.$s;
						my $triple = &setName( 'd', $$temp{'user'}, $value, 'r', $a );
						my @triple = ( $triple, $value, 'r', $a, 'n', 2 );
						push @num, \@triple;
					}
					$predicate{'r'} = $a = $value
				}
				elsif( $name eq 'm' ){ 
					&setWarn("			wP      $pair: смена значения обстоятельства (подлеж.: $a)" );
					$m = $value || $a 
				}
				elsif( $name eq 'o' ){ 
					&setWarn("			wP      $pair: смена значения дополнения (подлеж.: $a; обст.: $m)" );
					$o = $value || 'r' 
				}
				elsif( $name eq 'p' ){ 
					&setWarn("			wP      $pair: установление в параметр текущее дополнение  (подлеж.: $a; обст.: $m)" );
					my $triple = &setName( 'd', $$temp{'user'}, $a, $value, $o );
					my @triple = ( $triple, $a, $value, $o, $m, 1 );
					push @num, \@triple;
				}
				else{ 
					&setWarn("			wP     $pair:  установление параметра в обычном режиме (подлеж.: $a; обст.: $m)");
					$predicate{$name} = $value; #запоминаются все предикаты включая 'r'
					my $triple = &setName( 'd', $$temp{'user'}, $a, $name, $value );
					my @triple = ( $triple, $a, $name, $value, $m, 1 );
					push @num, \@triple;
				}
				
				#2016-12-18 - $$temp{'shag'} = $value if $name eq $types{'shag'}
			}
			( $$temp{'fact'}, $$temp{'modifier'} ) = ( $a, $m );
		}
	}
	@num || return;
	
	&setWarn( "		wP ## Имеются номера. Идет запись." );
	my @warn = ("washProc @_ \n");
	for my $s ( grep { $num[$_] } 0..$#num ){
		&setWarn("		wP  Проверка номера $s ( @{$num[$s]} ) ");
		my $miss;
		if ( $num[$s][5] != 2 and not defined $$temp{'wkhtmltopdf'}  ){#wkhtmltopdf - это костыль, потом нужно убрать инструкции на запись для wkhtmltopdf
			&setWarn("		wP   Проверка собственности при изменениях");
			#if ( $num[$s][4] eq 'n' and $num[$s][2] ne 'r' ) or $num[$s][2] eq 'r' ){
			if ( $num[$s][4] eq 'n' or $num[$s][2] eq 'r' ){ #r - нужен для контроля удаления, в обстоятельствах там может быть что угодно и для этого нельзя проверять or not(num[$s][5]) т.к. удаляться может и параметр в обстоятельствах
				&setWarn("		wP    Проверка подлежащего");
				my $holder = &m8holder( $num[$s][1] );
				if ( $holder ne $$temp{'user'}){
					&setWarn("		wP     Номер запрашивает действие над  подлежащим пользователя $holder");
					$$temp{'povtor'}[$s] = 4;
					$$temp{'number'}[$s]{'message'} = "Номер запрашивает действие над подлежащим пользователя $holder";
					next
				}
			}
			else {
				&setWarn("		wP    Проверка обстоятельства");
				my $holder = &m8holder( $num[$s][4] );
				if ( $holder ne $$temp{'user'} ){
					&setWarn("		wP     Номер запрашивает действие в обстоятельствах пользователя $holder");
					$$temp{'povtor'}[$s] = 4;
					$$temp{'number'}[$s]{'message'} = "Номер запрашивает действие в обстоятельствах пользователя $holder";
					next
				}
			}
		}
		for my $key ( 0..5 ){ 
			if ( $num[$s][$key] ){ 
				&setWarn("		wP   Элемент $key:  $num[$s][$key]");
				$$temp{'number'}[$s]{$number[$key]} = $num[$s][$key] 
			}
			elsif ( $key != 5 ){ 
				$miss = $key;
				&setWarn("		wP   Не найден элемент номера $miss");
			}	
		}
		if ( $miss ){
			$$temp{'povtor'}[$s] = 4;
			$$temp{'number'}[$s]{'message'} = "Не найден элемент номера $miss";
			next
		}
		if ( grep { $s != $_ and $num[$_] and ( $num[$s][0] eq $num[$_][0] ) } 0..$#num ) { 
			&setWarn("		wP   Номер запрашивает повтор трипла в запросе");
			$$temp{'povtor'}[$s] = 1;
			$$temp{'number'}[$s]{'message'} = 'Номер запрашивает повтор трипла в запросе';
			next;
		}
		if ( $num[$s][0] ne 'd' and $num[$s][1] eq $num[$s][4] ) { 
			&setWarn("		wP   Номер запрашивает нарушение правила иерархии");
			$$temp{'povtor'}[$s] = 3;
			$$temp{'number'}[$s]{'message'} = 'Номер запрашивает нарушение правила иерархии';
			next;
		}
		#if ( $num[$s][2] eq $types{'shag'} and 0  ){
		#	&setWarn( "			m8req  проверка состояния" );
		#	&setWarn( &m8dir( $num[$s][0] ) );
		#	if ( -d &m8dir( $num[$s][0] ) ){
		#		$$temp{'activity'} = undef;
		#		next;
		#	}
		#	&setWarn( &m8dir( $num[$s][0] ) );
		#}
		if ( $num[$s][2]=~/^r/ and -d 'm8/n/'.$num[$s][1] ){
			&setWarn("		wP   Проверка изменения статуса имеющегося нечто.");
			#my $holder = &m8holder( $num[$s][1] );
			#if ( $holder ne $$temp{'user'} ){
			#	&setWarn("		wP    Номер запрашивает действие над чужим нечто");
			#	$$temp{'povtor'}[$s] = 4;
			#	$$temp{'number'}[$s]{'message'} = 'Номер запрашивает действие над чужим нечто';
			#	next
			#}
			if ( -d $planeDir.'/'.$$temp{'user'}.'/tsv/'.$num[$s][0] ){
				&setWarn("		wP    Проверка трипла $num[$s][0].");	#вероятно всю эту операцию нужно делать в сушке	
				if ( 0 and not $num[$s][5] ){# удалять начальников можно, но в стилях нужно избежать показа их подчиненных
					my %index = &getJSON( &m8dir( $num[$s][1] ), 'index' ); #Нельзя удалять объект имеющий подчиненных
					if ( defined $index{'director'} ){
						$$temp{'povtor'}[$s] = 3;
						$$temp{'number'}[$s]{'message'} = 'Номер запрашивает удаление директора';
						next
					}
					if ( defined $index{'object'} ){
						$$temp{'povtor'}[$s] = 3;
						$$temp{'number'}[$s]{'message'} = 'Номер запрашивает удаление лидера';
						next
					}
				}
				my ( $oldDirector ) = &getDir( $planeDir.'/'.$$temp{'user'}.'/tsv/'.$num[$s][0], 1 );
				if ( $oldDirector ){
					&setWarn("		wP     Удаление старой связи состава $num[$s][0].");	
					my @triple = ( $num[$s][0], $num[$s][1], $num[$s][2], $num[$s][3], $oldDirector );
					#push @num, \@triple;
					push @warn, &spinProc( \@triple, $$temp{'user'}, $$temp{'time'}, 713 );
					if ( defined $$temp{'object'} ){
						&setWarn("		wP      Добавление к новой связи состава указания такого же типа.");
						$num[$s][3] = $num[$s][4];#$$temp{'object'};
						$num[$s][0] = &setName( 'd', $$temp{'user'}, $num[$s][1], $num[$s][2], $num[$s][3] );
					}			
				
				}
			}
		}
		if ( $num[$s][2] eq 'r' and $num[$s][4] ne 'n' ){
			&setWarn("		wP   Недопущение указания r в квесте."); # 2016-12-01
			$$temp{'povtor'}[$s] = 3;
			$$temp{'number'}[$s]{'message'} = 'Номер запрашивает указание r в квесте';
			next
		}
		if ( $num[$s][5] and $num[$s][2] eq 'n' and -d $planeDir.'/'.$$temp{'user'}.'/tsv/'.$num[$s][0].'/'.$num[$s][4] and not defined $$temp{'activity'} ){ 
		# 2016-12-18 if ( $num[$s][5] and $num[$s][2] eq $types{'shag'} and -d $planeDir.'/'.$$temp{'user'}.'/tsv/'.$num[$s][0].'/'.$num[$s][4] and not defined $$temp{'activity'} ){ 
			&setWarn("		wP     Не активность.");	
			$$temp{'activity'} = 0;
			next if $num[$s][2] eq 'n' and -d $planeDir.'/'.$$temp{'user'}.'/tsv/'.$num[$s][0].'/'.$num[$s][4];
			# 2016-12-18next if $num[$s][2] eq $types{'shag'} and -d $planeDir.'/'.$$temp{'user'}.'/tsv/'.$num[$s][0].'/'.$num[$s][4]; #что бы запись метки не повторялась аж дважды за запрос, здесь еще видимо нужно добавить поиск квеста, а не только папки трипла
		}
		else{ 
			&setWarn("		wP     Детектирование активности .");	
			#&setWarn("		wP     Детектирование активности - есть еще номера .") if defined $$temp{'activity'};
			#&setWarn("		wP     Нет директории ".$planeDir.'/'.$$temp{'user'}.'/tsv/'.$num[$s][0].'/'.$num[$s][4] ) if not -d $planeDir.'/'.$$temp{'user'}.'/tsv/'.$num[$s][0].'/'.$num[$s][4];
			$$temp{'activity'} = 1;
			#
		}
		push @warn, &spinProc( $num[$s], $$temp{'user'}, $$temp{'time'}, 723 );
		#if ( 0 and &spinProc( $num[$s], $$temp{'user'}, $$temp{'time'}, 723 ) ){
		#	&setWarn("		wP   Номер запрашивает повтор трипла в базе.");
		#	$$temp{'povtor'}[$s] = 2;
		#	$$temp{'number'}[$s]{'message'} = 'Номер запрашивает повтор установления значения';
		#}
	}
	my $warn = join '', @warn;
	&setFile( $logPath.'/reindex/'.$$temp{'time'}.'_wash.txt', $warn );# if $$temp{'user'} ne 'guest' and not $$temp{'user'}=~/^user/;
	return if 1 or -e $configPath.'/control' or not grep { $$temp{'number'}[$_] eq 'OK' } @{$$temp{'number'}};
	
	&setWarn('   Обнаружены физические записи. Запуск процесса сушки');
	eval{ system( 'perl.exe M:\system\reg.pl dry >/dev/null 2>M:\_log\error_dry.txt' ); }	
}



sub rinseProc {
	my ( $name, @div )=@_;
	&setWarn("		rP @_"  );
	if ($div[0]=~/^\<svg/){
		&setWarn("		rP  запись xml-файла напрямую"  );
		&setFile( &m8dir( $name ).'/value.xml', '<?xml version="1.0" encoding="UTF-8"?><value id="'.$name.'">'.$div[0].'</value>' );
	}
	else{
		&setWarn("		rP  формировани xml-файла"  );
		my %value;
		if ( ( $div[0] and $div[0] ne '' ) or $div[1]  ){ 
			&setWarn("		rP  Раскладка @div по строкам"  );
			for my $s (0..$#div){
				&setWarn("		rP   Строка $s: $div[$s]"  );
				#$div[$s] = Encode::decode_utf8($div[$s]) if $div[$s];
				my @span = split "\t", $div[$s];
				for my $m (0..$#span){ $value{'div'}[$s]{'span'}[$m]{$tNode} = $span[$m] } 
			}
		}
		else { $value{'div'}[0]{'span'}[0]{$tNode} = undef }
		&setXML ( &m8dir( $name ), 'value', \%value );			
	}

}

sub rinseProc3 {
	my ( $root, %type )=@_;
	&setWarn("		rP3 @_"  );
	my %xsl_stylesheet;
	$xsl_stylesheet{'xsl:stylesheet'}{'version'} = '1.0';
	$xsl_stylesheet{'xsl:stylesheet'}{'xmlns:xsl'} = 'http://www.w3.org/1999/XSL/Transform';
	my $x = 0;
	for my $typeName ( keys %type ){
		$xsl_stylesheet{'xsl:stylesheet'}{'xsl:param'}[$x]{'name'} = $typeName;
		$xsl_stylesheet{'xsl:stylesheet'}{'xsl:param'}[$x]{'select'} = "'$type{$typeName}'";
		$x++
	}
	my $XML = $XML2JSON->json2xml( $JSON->encode(\%xsl_stylesheet) );
	&setFile( $typesDir.'/'.$root.'.xsl', $XML );
	&rinseProc3( 'class', reverse %type ) if $root eq 'type';
	&setXML( $typesDir, $root, \%type );
	
}

sub spinProc {
	my ( $val, $user, $time, $dry )=@_;
	&setWarn("
		sP @_"  );
	my @spin_warn;# = ( "spinProc \n");
	#if ( $$val[] ){
	if ( $$val[5] ){
		for my $key ( 0..5 ){ 
			&setWarn("		sP  Значение на сушку $key: $$val[$key]"  );
			#push @spin_warn, "		sP  Значение на сушку $key: $$val[$key]\n"
			#else { warn "delete $key - $$val[$key]"
		}	
	}
	else{ 
		&setWarn("		sP  Значение на сушку @{$val}"  );
		push @spin_warn, " DEL ($time / $dry): @{$val}\n" 
	}
	my ( $name, $subject, $predicate, $object, $modifier, $add ) = ( $$val[0], $$val[1], $$val[2], $$val[3], $$val[4], $$val[5] );
	#$add = 1 if $add;
	my @value = ( $name, $subject, $predicate, $object );
	#my $quest = $modifier;
	if ( $modifier eq 'n' ){ push @value, $user }
	else { push @value, $modifier } 
	if ( $predicate eq 'r' ){
	#	$value[4] = $quest = 'n';
		push @value, ( $subject, $predicate, $object )#, $modifier
	}
	my $mainDir = &m8dir( $subject, $modifier );
	my $good;
	#if (-d $mainDir){
	my %port = &getJSON( $mainDir, 'port' );
	if ( $add ){
		&setWarn("		sP  Поиск такого же значения в порту директории $mainDir"  );
		if ( defined $port{$predicate} ){
			&setWarn("		sP   Анализ значения"  );
			my @oldObject = keys %{$port{$predicate}[0]};
			my $oldObject = $oldObject[0];
			my @oldTriple = keys %{$port{$predicate}[0]{$oldObject}[0]};
			my $oldTriple = $oldTriple[0];
			my $oldTime = $port{$predicate}[0]{$oldObject}[0]{$oldTriple}[0]{'time'};
			if ( $time < $oldTime ){
				&setWarn("		sP    Значение было позже пезаписано другим. Пропуск"  );
				push @spin_warn,  " DELETE OLD ( $time < $oldTime ): @{$val} \n";
				$add = undef;
				$good = 1;
				#warn " DELETE OLD $planeDir/$user/tsv/$name/$modifier"
			} #имеющееся значение новее текущего
			elsif ( $oldObject eq $object ){ 
				&setWarn("		sP    Найдено такое же значение - $object. Пропуск"  );
				#warn " REPET RECORD ($time): @{$val} \n";
				$good = 1 
			} # or $$val[2] = 'r' повтор, пропускаем реиндексацию, но (излишне?) перезаписываем базу
			else{
				&setWarn("		sP    Удаление старого значения"  );
				#my $oldModifier = $modifier;
				#$oldModifier = &m8director( $subject ) if $predicate eq 'r';
				my @triple = ( $oldTriple, $subject, $predicate, $oldObject, $modifier );
				push @spin_warn, " NEW VALUE ($time): @{$val} \n";
				push @spin_warn, &spinProc ( \@triple, $user, $oldTime, 809 );
			}
		}
	}
	elsif ( not defined $port{$predicate} or not defined $port{$predicate}[0]{$object} ){ $good = 1 }
	#return 0 if $dry eq 809;
	#}
	#my @value = ( $name, $subject, $predicate, $object, $modifier, $user );
	if (not $good){
		#push @value, ( $subject, $predicate, $object ) if $predicate=~/^r\d*$/;
		#my ( $superAddQuest, $superAddUser ); #добавлено 2016-11-28 что бы не удалялось упоминание в квест-индексе при любом удалении в квесте
		my ( $supRole, $supFile, $supFirst, $supAdd );
		for my $mN ( grep { $value[$_] } 0..$#value ){
			&setWarn("		
			sP  Обработка упоминания cущности $mN: $value[$mN] (user: $user)"  );
			my $addC = $add || 0; #заводим отдельный регистр, т.к. $add должен оставаться с значением до цикла
			my $metter = &getID($value[$mN]);
			#&setLink( $planeRoot.'m8',	$planeRoot.$auraDir.'/m8'			);
			#&setLink( $planeRoot.'m8/n', 	$metter.'/q' ) if $value[$mN]=~/^n/ and $add;
			my $type = $superrole[$mN];
			my ( $role, $file, $first );
			if ( $mN == 0 ){	( $role, $file, $first ) = ( 'activate',	'activate'				, $modifier ) }
			elsif ( $mN < 4 ) {	( $role, $file, $first ) = ( 'role'.$mN,	'role'.$mN 				, $modifier ) }
			elsif ( $mN == 4 ){ 
								( $role, $file, $first ) = ( $supRole,		$supFile				, $supFirst ); 
				$addC = $supAdd;
				$type = 'author' if $modifier eq 'n';
			}#вероятнее всего, здесь subject нужно поменять на name		
			#elsif ( $mN == 5 ){ ( $role, $file, $first ) = ( 'author',		'author'				, $modifier ) }
			elsif ( $mN == 5 ){ ( $role, $file, $first ) = ( $predicate,	'subject_'.$predicate	, $modifier ) }
			elsif ( $mN == 6 ){	( $role, $file, $first ) = ( $object,		'predicate_'.$object	, $modifier ) }
			elsif ( $mN == 7 ){	( $role, $file, $first ) = ( $subject, 		'object_'.$subject		, $modifier ) } 
			#elsif ( $mN == 9 ){	( $role, $file, $first ) = ( $subject, 		'director_'.$subject	, $modifier ) } 
			
			if ( $mN == 1 or $mN == 2 or $mN == 3  ){
				&setWarn("		sP   Формирование порта/дока/терминала $role ($file, $first).  User: $user"  );
				
				my ( $master, $slave );
				if ( $mN == 1 )		{ ( $master, $slave ) = ( $predicate, 	$object 	) }
				elsif ( $mN == 2 )	{ ( $master, $slave ) = ( $subject, 	$object 	) }
				elsif ( $mN == 3 ) 	{ ( $master, $slave ) = ( $subject, 	$predicate 	) }
				my %role = &getJSON( $metter.'/'.$modifier, $superfile[$mN] );
				#$role{'user'} = $user;
				if ( $addC ){
					&setWarn("		sP    Операции при добавлении значения в индекс $metter/$modifier  ($master, $slave)"  );
					$role{$master}[0]{$slave}[0]{$name}[0]{'time'} = $time;
					$role{$master}[0]{$slave}[0]{$name}[0]{'user'} = $user if $mN == 1 and $master eq 'r';
				}
				else { 
					&setWarn("		sP    Операции при удалении значения. Удаление ключа $master"  );
					delete $role{$master} ; 
					$addC = 1 if keys %role; 
				} 
				&setXML ( $metter.'/'.$modifier, $superfile[$mN], \%role );
				if ( $mN == 1 ){
					&setWarn("		sP   Установление супер-маркеров"  );
					if ( $modifier eq 'n' ){ ( $supRole, $supFile, $supFirst ) = ( 'author', 'author', $modifier ) }
					else { ( $supRole, $supFile, $supFirst ) = ( 'quest', 'quest', $subject ) } 
					$supAdd = $addC
				} 
			}
			my %role1 = &getJSON( $metter, $file );
			if ( $addC ) {#==1
				&setWarn("		sP   Счетчик упоминаний не пустой - дополняем/обновляем индекс-файл роли $role ($file, $first)"  );
				$role1{$first}[0]{'time'} = $time;
				$role1{$first}[0]{'triple'} = $name;
				#if ( $mN == 6 ){
				#	$role1{$first}[0]{'holder'} = $user;
				#	$role1{$first}[0]{'director'} = $modifier;# if $modifier ne 'n';
				#}
			}
			else {
				&setWarn("		sP   Счетчик упоминаний пустой - сокращаем индекс-файл роли"  );
				delete $role1{$first};
				#if ( not grep {$_ ne 'time'} keys %{$role1{$first}[0]} ){
				#	delete $role1{$first};		
				#}			
			}
			&setXML ( $metter, $file, \%role1 );
			my %index = &getJSON( $metter, 'index' );
			if (keys %role1){
				&setWarn("		sP    Добавление/обновление упоминания роли"  );
				$index{$type}[0]{$role}[0]{'time'} = $time;
				$index{$type}[0]{$role}[0]{'file'} = $file;
				$index{$type}[0]{$role}[0]{'superfile'} = $superfile[$mN] if $mN and $mN < 4
			}
			else { 
				&setWarn("		sP    Удаление упоминания роли"  );
				delete $index{$type}[0]{$role};
				delete $index{$type} if not keys %{$index{$type}[0]};
			}
			&setXML ( $metter, 'index', \%index );
		}
	}
	my $questDir = $planeDir.'/'.$user.'/tsv/'.$name.'/'.$modifier;
	if ( $add ){
		&setWarn("		sP  Добавление в базу директории $questDir");
		&setFile ( $questDir.'/time.txt', $time ); #ss
	}
	else{
		&setWarn("		sP  Удаление из базы директории $questDir");
		rmtree $questDir;
		if ( not &getDir ( $planeDir.'/'.$user.'/tsv/'.$name, 1 ) ){
			&setWarn("		sP   Удаление из базы директории $planeDir/$user/tsv/$name");
			rmtree $planeDir.'/'.$user.'/tsv/'.$name;
			if ( not &getDir( $planeDir.'/'.$user.'/tsv', 1 ) ){
				&setWarn("		sP    Удаление из базы директории $planeDir/$user/tsv");
				&setXML( 'm8/d/'.$value[0], 'value' );
				rmtree $planeDir.'/'.$user.'/tsv';
			}
			if ( -e $typesDir.'/'.$typesFile and $value[3]=~/^i/ ){ #Эту проверку нужно делать в сушке, т.к. она нужна и при замене старого значения
				&setWarn("		sP    Проверка на идентификатор-тип");
				my @val = &getFile( $planeDir.'/'.$user.'/tsv/'.$value[3].'/value.tsv' );
				my %types = &getJSON( $typesDir, 'type' );
				if ( $val[1] and $val[1]=~/^xsd:/ ){
					delete $types{$val[0]};
					&setXML( $typesDir, 'type', \%types );
					&rinseProc3( 'type', %types )
				}
			}
		}
	}
	&setWarn("		sP @_ (END)
	"  );	
	return @spin_warn;
	
}

sub dryProc2 {
	my ( $clean, $clear )=@_; # $param
	#&setWarn("		dP 2 @_" );
	$dbg = 0;
	my @warn = ("dryProc2 @_ \n");
	my $indexTime = $reindexDays * 60 * 60 * 24;
	#rmtree $logPath if -d $logPath;
	#:: емкости и резервуары n1477307416-546366-pgstn-0
	#:: огнезащита воздуховода n1477308145-515249-pgstn-0
	-d $logPath.'/reindex' || make_path( $logPath.'/reindex', { chmod => $chmod } );
	#make_path( $logPath, { chmod => $chmod } );
	my $ctime = time;
	for my $indexLog ( &getDir( $logPath.'/reindex' ) ){
		my $mtime = (stat $logPath.'/reindex/'.$indexLog)[9]; 
		unlink $logPath.'/reindex/'.$indexLog if ( $ctime - $mtime ) > $indexTime;
	}
	open (REINDEX, '>'.$logPath.'/reindex/'.$ctime.'.txt')|| die "Ошибка при открытии файла $logPath/reindex/$ctime.txt: $!\n";
	warn '		DRY BEGIN ';	
	#mode1 - удаляется и переиндексируется все
	#mode2 - только удаляется мусор (в штатном режиме имеет смысл только для доудаления гостевых триплов)
	#@user - Если указаны то только они будут сохранены
	#chdir "W:";
	if ( -e $platformGit and 0 ){
		push @warn, "  Check platform \n";
		copy $platformGit, '/var/www/m8data.com/master';
	}
	if ( not -d 'm8' and 0 ){ #опция отключена 2016-10-05
		warn 'check tempfsFolder';
		my $tempfsFolder = &getSetting('tempfsFolder');
		if ( -d $tempfsFolder.'/m8'.$prefix ){
			warn 'link from '.$disk.$tempfsFolder.'/m8'.$prefix;
			&setLink( $disk.$tempfsFolder.'/m8'.$prefix, 	$planeRoot.'m8' )
		}
		else {
			warn 'add '.$planeRoot.'m8';
			make_path( $planeRoot.'m8', { chmod => $chmod } )
		}
	}
	else { make_path( $planeRoot.'m8', { chmod => $chmod } ) }
	#&setFile( '.htaccess', 'DirectoryIndex '.$prefix.'formulyar/reg.pl' );
	
	-d $auraDir || make_path( $auraDir, { chmod => $chmod } );
	-d 'formulyar' || make_path( 'formulyar', { chmod => $chmod } );
	-d $planeDir.'/'.$defaultUser || make_path( $planeDir.'/'.$defaultUser, { chmod => $chmod } );
	&setLink( $planeRoot.'m8',					$planeRoot.$auraDir.'/m8'			);
	&setLink( $planeRoot.$planeDir, 			$planeRoot.$planeDir_link 			);
	#&setLink( $planeRoot.'formulyar', 			$planeRoot.$planeDir.'/formulyar' 	);
	&setLink( $multiRoot.$branche.'/'.$univer, 	$planeRoot.$planeDir.'/'.$univer 	);
	if ( -e $planeDir.'/'.$univer.'/formulyar.conf' ){
		warn ('  Reed formulyar.conf');
		for my $site ( &getFile( $planeDir.'/'.$univer.'/formulyar.conf' ) ){
			$site=~/^(\w+)-*(.*)$/;
			my $univer_depend = $1;
			my $branch_depend = $2 || 'master';
			&setLink( $multiRoot.$branch_depend.'/'.$univer_depend, 	$planeRoot.$planeDir.'/'.$univer_depend );
		}
	}
	my @ava = &getDir( $planeDir, 1 );
	my %controller;
	for my $ava ( @ava ){
		$controller{$ava} = 1 if -e $planeDir.'/'.$ava.'/xsl/'.$ava.'.xsl';
		-d $auraDir.'/'.$ava || make_path( $auraDir.'/'.$ava, { chmod => $chmod } );
		&setLink( $planeRoot.'m8', $planeRoot.$auraDir.'/'.$ava.'/m8' );
		-e $userDir.'/'.$ava.'/'.$passwordFile || &setFile( $userDir.'/'.$ava.'/'.$passwordFile );
	}
	&setXML( $planeDir, 'controller', \%controller );
	for my $format ( keys %formatDir ){
		&setLink( $planeRoot.$auraDir, $planeRoot.$format );
	}
	$clean || return;
	my %stat;

	my $guestDays = &getSetting('guestDays');
	my $userDays = &getSetting('userDays');
	my $guestTime = time - $guestDays * 24 * 60 * 60;
	my $userTime = time - $userDays * 24 * 60 * 60;
	if ( $clear ){
		warn '		delete all index';
		my $zip = Archive::Zip->new();
		for my $userName ( grep{ not /^_/ and $_ ne 'formulyar' } &getDir( $planeDir, 1 ) ){ 
			warn "\n		user $userName to archive   \n";		
			my $tsvPath = $planeDir.'/'.$userName.'/tsv';
			if ( $userName ne 'guest' and not $userName =~ /^user/ ){ #and not $userName =~ /^test/
				$zip->addTree( $tsvPath, $userName );
			}		
		}
		unless ( $zip->writeToFileNamed($logPath.'/reindex/'.$ctime.'_all.zip') == AZ_OK ) { die 'write error'	}
		for my $d ( &getDir( 'm8' ) ){
			if ( -d 'm8/'.$d ){ 
				rmtree 'm8/'.$d 
			}
			else { unlink 'm8/'.$d }
		}
	}
	#exit;
	my %dry;
	my %userType;
	my %types;
	( $types{'n'}, $types{'r'}, $types{'d'}, $types{'i'} ) = ( 'n', 'r', 'd', 'i' );
	my $count1 = 0;
	my $n_delG = 0;
	my $n_delR = 0;
	my $n_delN = 0;
	my $all = 0;
	my $triple = 0;
	#my $clean = 0; 
	my $DL_map = 0;
	my $cookie = 0;
	my $DL_cookie = 0;

	for my $sessionName ( &getDir( $sessionPath, 1 ) ){ 
		push @warn, "sessionName	$sessionName \n";
		warn '		sessionName  '.$sessionName;
		$cookie++;
		my $cUser = &getFile( $sessionPath.'/'.$sessionName.'/value.txt' );
		my $tempKeysFile = $userDir.'/'.$cUser.'/'.$sessionFile;
		if ( -e $tempKeysFile ){
			my %tempkey = &getHash( $tempKeysFile );
			if ( not defined $tempkey{$sessionName} or $tempkey{$sessionName} < $userTime ){
				rmtree $sessionPath.'/'.$sessionName;
				$DL_cookie++
			}
		}
		else {
			rmtree $sessionPath.'/'.$sessionName;
			$DL_cookie++
		}		
	}

	push @warn, "\n Круг1 \n";
	warn "		\n==== Round 1 ====\n  ";
	my $time1 = time;
	for my $userName ( grep{ not /^_/ and $_ ne 'formulyar' } &getDir( $planeDir, 1 ) ){  # 
		push @warn, "\n userName	$userName \n";
		warn "		\n userName  $userName";
		my $tsvPath = $planeDir.'/'.$userName.'/tsv';
		if ( -e $planeDir.'/'.$userName.'/.git/refs/heads/'.$branche ){
			push @warn, "    Копирование указателя состояния ветки $branche";
			warn '	Copy of branche head  ';
			copy $planeDir.'/'.$userName.'/.git/refs/heads/'.$branche, $userDir.'/'.$userName.'/'.$branche;
		}
		#next if $userName eq $defaultAvatar;
		&setFile( $tsvPath.'/d/n/time.txt', '0.1' );
		&setFile( $tsvPath.'/d/value.tsv', ( join "\t", @mainTriple ) );
		&setFile( $tsvPath.'/i/value.tsv' );
		if ( not defined $stat{$userName} ){
			for ( 'add', 'n_delR', 'n_delN' ){ $stat{$userName}{$_} = 0 }
		}
		for my $tsvName ( &getDir( $tsvPath, 1 ) ){
			#push @warn, "   Исследование tsv-шки $tsvName \n";
			push @warn, "   tsv  $tsvName\n";
			warn '	tsv  '.$tsvName;
			my $metterPath = $tsvPath.'/'.$tsvName;
			if ( not -e $metterPath.'/value.tsv' ){
				push @warn, "   Error: no $metterPath/value.tsv file \n";
				warn "Error: no $metterPath/value.tsv file";
				rmtree $metterPath;
				next;
			}
			$all++;
			my @div = map{ Encode::decode_utf8($_) } &getFile( $metterPath.'/value.tsv' );
			&rinseProc( $tsvName, @div );
			next if $tsvName=~/^i/;
			if ( not &getDir( $metterPath, 1 ) ){
				push @warn, "   Error: no dir in $tsvName. Deleting triple. \n";
				warn "Error: no dir in $tsvName. Deleting triple.";
				rmtree $metterPath;
				next;
			}
			my @val = split "\t", $div[0];
			unshift @val, $tsvName;
			#$val[4] = $userName;
			$triple++;
			if ( $val[3] =~/^i\d+$/ ){
				my @map = map{ Encode::decode_utf8($_) } &getFile( $tsvPath.'/'.$val[3].'/value.tsv' );
				$userType{$userName}{$val[3]} = $map[0] if $map[1] and $map[1]=~/^xsd:\w+$/;
				$types{$map[0]} = $val[1] if $map[1] and $map[1]=~/^xsd:\w+$/;
			}
			if (1){		
			my @quest = &getDir( $metterPath, 1 );			
			if ( not @quest ){
				push @warn, "	!!! delete triple without quest ( @val )";
				warn "	!!! delete triple without quest ( @val )";
				rmtree $metterPath || warn "Еrror deleting file $metterPath: $!\n";;
				next;
			}
			for my $questName ( @quest ){
				#push @warn, "    Исследование квеста $questName \n";
				$val[4] = $questName;

				my ( $timeProc ) = &getFile( $metterPath.'/'.$val[4].'/time.txt' );
				if ( $val[0] ne 'd' and $val[1] eq $val[4] ){
					#корректировка формата данных 2016-10-07
					warn "	!!! refresh: @val";
					push @warn, "	!!! корректировка формата данных 2016-10-07: ( @val ) \n";
					rmtree $metterPath.'/'.$val[4];
					if ( $val[2] eq 'r' ){ $val[4] = $val[3]; }
					else { $val[4] = 'n'}
					&setFile( $metterPath.'/'.$val[4].'/time.txt', $timeProc )
				}
				elsif ( $val[4] ne 'n' and $val[2] eq 'r' ){
					#удаление аномалии в квесте ( 2016-12-01 )
					warn "	!!! delete r from quest: $metterPath/$val[4] ( @val )";
					push @warn, "	!!! delete r from quest: $metterPath/$val[4] ( @val ) \n";
					rmtree $metterPath.'/'.$val[4] || warn "Еrror deleting file $metterPath/$val[4]: $!\n";
					#sleep 8
					if ( $val[4] eq $val[3] ){
						push @warn, "	!!!!! REPLACE \n";
						warn "	!!!!! REPLACE";
						$val[4] = 'n';
						&setFile( $metterPath.'/'.$val[4].'/time.txt', $timeProc )
					}
					else { next }
				}
				if ( $userName eq 'guest' and $tsvName ne 'd' and $timeProc and $timeProc < $guestTime ){ 
					push @warn, "     Удаление старого гостевого трипла '.$div[0].' \n";
					$n_delG++
				}
				else {
					$val[5] = 1;
					push @warn, "     Реиндексация значений @val \n"; # d1341061753575729161 d14757079324734822550
					$stat{$userName}{'add'}++;
				}
				push @warn, &spinProc( \@val, $userName, $timeProc, 1094 );
			}
			}
		}
	}
	my $time2 = time;
	if ( $clean == 2 ){	
		push @warn, "\n Круг2 \n";
		warn "		\n==== Round 2 ====\n  ";
		
		for my $userName ( grep{ not /^_/ and $_ ne 'formulyar' } &getDir( $planeDir, 1 ) ){ 
			push @warn, "userName2	$userName \n";
			warn "\n		userName2  $userName \n";		
			my $tsvPath = $planeDir.'/'.$userName.'/tsv';
			if ( $userName ne 'guest' and not $userName =~ /^user/ and not $userName =~ /^test/ ){
				my $zip = Archive::Zip->new();
				$zip->addTree( $tsvPath );
				unless ( $zip->writeToFileNamed($logPath.'/reindex/'.$ctime.'_'.$userName.'.zip') == AZ_OK ) { die 'write error'	}
			}
			push @warn, $@ if $@;
			for my $tsvName ( &getDir( $tsvPath, 1 ) ){ 
				warn '	tsv2  '.$tsvName;
				push @warn, "  tsv2	$tsvName \n";
				if ( $tsvName=~/^i/ ){
					if ( not -e &m8path( $tsvName, 'index' ) and $tsvName ne 'i' ){
						rmtree $tsvPath.'/'.$tsvName;
						rmtree &m8dir( $tsvName );
						$DL_map++
					}
				}
				elsif ( $tsvName=~/^d/ ){
					#push @warn, "    Исследование трипла $tsvName \n";			
					my @val = map{ Encode::decode_utf8($_) } &getTriple( $userName, $tsvName );
					my $parent = $val[1];
					#$val[4] = $userName;
					for my $questName ( &getDir( $tsvPath.'/'.$tsvName, 1 ) ){
						#push @warn, "     Исследование квеста $questName \n";
						$val[4] = $questName;
						my $good = 1;
						for my $n ( grep { $val[$_]=~/^n/ and $good } 1..4 ){
							next if $n == 1 and $questName ne 'n'; #подлежащее имеет право быть удаленным, если оно мульт
							my $dirr = &m8dir( $val[$n] );
							#push @warn, "      Исследование роли $n: $val[$n] в папке $dirr \n";
							my %index = &getJSON( &m8dir( $val[$n] ), 'index' );
							if ( not defined $index{'subject'} ){
								$good = 0; 
								push @warn, "       Cущность удалена. Номер испорчен. \n";
								push @warn, "  No find $val[$n]. Delete nechto"
								#for my $key ( %index ){
								#	print REINDEX "       key: $key => $index{$key} \n";
								#}
							}
						}
						next if $good;
						my ( $timeProc ) = &getFile( $tsvPath.'/'.$tsvName.'/'.$val[4].'/time.txt' );
						if ( $val[3] =~/^i\d+$/ ){
							my @map = map{ Encode::decode_utf8($_) } &getFile( $tsvPath.'/'.$val[3].'/value.tsv' );
							delete $userType{$userName}{$val[3]} if $map[1]=~/^xsd:\w+$/;
							delete $types{$map[0]} if $map[1]=~/^xsd:\w+$/;
						}
						push @warn, &spinProc( \@val, $userName, $timeProc, 1156 );
						if ( $val[2]=~/^r/ ){ $stat{$userName}{'n_delR'}++ }
						else { $stat{$userName}{'n_delN'}++ }
					}
				}
			}
		}
		my $time3 = time+1;
		
	}

	&rinseProc3( 'type', %types );# if keys %types;

	print REINDEX @warn;
	
	my $second1 = int( $time2 - $time1 ) +1;
	#my $second2 = int( $time3 - $time2 ) +1;
	my $s1 = int( $all / $second1 );
	#my $s2 = int( $all / $second2 );
	my $map = $all - $triple;
	my $list = '
	guestDays: 	'.$guestDays.'
	guestTime:	'.$guestTime.'
	N_DL-G:	'.$n_delG.'
	
	ALL: 	'.$all.'
	MAP:	'.$map.'
	DL_map: '.$DL_map.'
	
	TRIPLE:	'.$triple.'
	';
	for my $auth ( keys %stat ){
		$list .= $auth.':		'.$stat{$auth}{'add'}.'	'.$stat{$auth}{'n_delR'}.'	'.$stat{$auth}{'n_delN'}.'
	';
	}
	$list .= '
	
	cookie:		'.$cookie.'
	DL_cookie:	'.$DL_cookie.'
	
	TIME1:		'.$second1.'	/	'.$s1.'
	';
	warn $list;
	print REINDEX $list;
	close (REINDEX);
}




sub parseNew {
	my ( $temp, $pass )=@_;
	&setWarn( "			pN @_" );	
	if ( defined $$temp{'login'} ){ 
		&setWarn('			pN   Вход ранее созданного пользователя');
		if ($$temp{'login'} ne 'guest'){
			#$^O ne 'MSWin32' || $$temp{'login'} =~/^user/ || return 'user for server'; #здесь нужно фильтровать не windows, но пока так - 2016-11-15
			defined $$pass{'password'} and $$pass{'password'} || return 'no_password';
			my $userPath = $userDir.'/'.$$temp{'login'};
			-d $userPath  || return 'no_user'; #&& -d $planeDir.'/'.$$temp{'login'}
			my $password = &getFile( $userPath.'/'.$passwordFile ) || &getSetting('userPassword');
			#$password = &getSetting('userPassword') if $password eq '';
			$password eq $$pass{'password'} || return 'bad_password';
		}
	}
	elsif ( defined $$temp{'new_author'} ){
		&setWarn('			pN   Создание автора');
		$$temp{'new_author'} =~/^\w+$/ || return 'В имени могут быть лишь буквы латинского алфавита и цифры.';
		34 >= length $$temp{'new_author'} || return 'Имя не должно быть длиннее 34 символов.';
		return 'Такой пользователь уже существует' if -d $userDir.'/'.$$temp{'new_author'};
		defined $$pass{'new_password'} and $$pass{'new_password'} || return 'Введите пароль';
		defined $$pass{'new_password2'} and $$pass{'new_password2'} || return 'Введите пароль с повтором';		
		$$pass{'new_password'} eq $$pass{'new_password2'} || return 'Пароль повторен не верно';
	}	
	return 0
}




######### функции второго порядка ##########
sub m8path {
	my @level = @_;
	my $path = 'm8/';
	if ( @level ){
		$path .= substr( $level[0], 0, 1 ).'/';
		$path .= join '/', @level
	}
	#if ( $level2 ){
	#	$path = 'm8/'.substr($level1,0,1).'/'.$level1.'/'.$level2;
		#if ( $level4 ){ 	$path .= '/'.$level3.'/'.$level4 }
	#	if ( $level3 ){	$path .= '/'.$level3 }
	#}
	#else { $path = $userPath.'/'.$level1.'/type' }
	return $path.'.xml'
}
sub m8dir {
	my ( $fact, $quest ) = @_;
	my $dir = 'm8/'.substr($fact,0,1).'/'.$fact;
	$dir .= '/'.$quest if $quest; 
	return $dir
}
sub m8req {
	my $temp = shift;
	&setWarn( "			m8req @_" );		
	my $dir = '';
	if ( defined $$temp{'avatar'} and $$temp{'ctrl'} ne $$temp{'avatar'} ){
		$dir = $auraDir.'/'.$$temp{'ctrl'}.'/'
	}
	if ( $$temp{'fact'} ne 'n' ){
		$dir .= 'm8/'.substr($$temp{'fact'},0,1).'/'.$$temp{'fact'}.'/';
		if ( defined $$temp{'number'} ){
			&setWarn( "			m8req  добавление строки запроса" );	
			my %string;
			$string{'modifier'} = $$temp{'modifier'} if $$temp{'modifier'} ne 'n';
			$string{'error'} = $$temp{'number'}[0]{'message'} if defined $$temp{'number'}[0]{'message'};
			$string{'n'} = $$temp{'n'} if $$temp{'n'}; #позднее здесь 'shag' заменить на 'n'
			# 2016-12-18 $string{'shag'} = $$temp{'shag'} if $$temp{'shag'};
			#my @ss = keys %{$temp};
			#&setWarn( "			m8req  добавление cостояния @ss" ) if $$temp{'activity'};
			my $prefix = '?';
			for my $key ( keys %string ){
				&setWarn( "			m8req    Добавление параметра $key" );	
				$dir .= $prefix.$key.'='.$string{$key};
				$prefix = '&';
			}
		}
	}
	# and ( ( $$temp{'modifier'} ne 'n' ) or defined $$temp{'number'}[0]{'message'} or defined $$temp{'activity'} ) ){
	#	$dir .= '?';
	#	$dir .= 'modifier='.$$temp{'modifier'} if $$temp{'modifier'} ne 'n';
	#	$dir .= '&error='.$$temp{'number'}[0]{'message'} if defined $$temp{'number'}[0]{'message'};
	#	$dir .= '&shag='.$$temp{'activity'} if defined $$temp{'activity'};
	#}
	return $dir;
}
sub m8holder {
	&setWarn( "			m8holder @_" );	
	my $fact = shift;
	my $dir = &m8dir( $fact, 'n' );
	my %port = &getJSON( $dir, 'port' );
	#my @keys = keys %port;
	#&setWarn( "			return $port{'user'} ( dir: $dir )" );	
	my @object = keys %{$port{'r'}[0]};
	my $object = $object[0];
	my @triple = keys %{$port{'r'}[0]{$object}[0]};
	my $triple = $triple[0];
	return $port{'r'}[0]{$object}[0]{$triple}[0]{'user'}
}
sub m8director {
	&setWarn( "			m8director @_" );	
	my $fact = shift;
	my $dir = &m8dir( $fact, 'n' );
	my %port = &getJSON( $dir, 'port' );
	my @object = keys %{$port{'r'}[0]};
	return $object[0];
}



sub setFile {
	my ( $file, $text, $add )=@_;
	#&setWarn( "						sF @_" );
	
	my @path = split '/', $file;
	my $fileName = pop @path;
	if ( @path ){
		my $dir = join '/', @path;
		-d $dir || make_path( $dir, { chmod => $chmod } );
	}
	my $mode = '>';#>:encoding(UTF-8)
	if ( $add ){ $mode = '>'.$mode }
	elsif ( -e $file  ){
		#my @result = ;
		my $result = join '\n', &getFile( $file );
		if ( not $text and not $result ){ return }
		elsif ( $text and $result and ( $result eq $text ) ){ return $text }
		else { unlink $file }
	}
	open (FILE, $mode, $file )|| die "Error opening file $file: $!\n";
		if ($text){
			chomp $text;
			print FILE $text; #на входе может быть '0' поэтому не просто "if $text"
			print FILE "\n" if $add;
		}
	close (FILE);
	if ( $dbg and $file=~/.xml$/ ){
		-d $trashPath || make_path( $trashPath, { chmod => $chmod } );
		#my $file = $trashPath.'/'.$path[$#path].'_'.$fileName;
		copy $file, $trashPath.'/'.$path[$#path].'_'.$fileName;
		#open (FILE, $mode, $file )|| die "Error opening file $file: $!\n";#$path[2].'-'.
		#	print FILE $text if $text;
		#	print FILE "\n" if $add;
		#close (FILE);
	}
	return $text; #обязательно нужно что-то возвращать, т.к. иногда функция вызывается в контексте and
}
sub setXML {
	my ( $pathDir, $root, $hash ) = @_;
	&setWarn("						sX @_" );
	my @keys = keys %{$hash};
	if ( $keys[0] ){
		#&setWarn("						sX  Add xml" );
		my %hash = ( $root => $hash );
		&setFile( $pathDir.'/'.$root.'.json', $JSON->encode(\%hash) );
		if ( $pathDir ){
			my @path = split '/', $pathDir;
			for ( 1..$#path ){	$hash{$root}{$level[$_]} = $path[$_] }
		}
		my $XML = $XML2JSON->json2xml( $JSON->encode(\%hash) );
		&setFile( $pathDir.'/'.$root.'.xml', $XML );
		return $XML;
	}
	else{
		#&setWarn("						sX  Удаление xml-файла" );
		unlink $pathDir.'/'.$root.'.xml';
		unlink $pathDir.'/'.$root.'.json';
	}
}
sub setName {
	my ( $type, $user, @value )=@_;
	&setWarn( "					sN @_" );
	my $name;
	my $tsvPath = $planeDir.'/'.$user.'/tsv';
	if (@value){
		@value = ( join( "\t", @value ) ) if $type eq 'd'; 
		my $value = join "\n", @value;
		my @name = murmur128_x64($value);
		( $name[0], $name[1] ) = ( $type.$name[0], $type.$name[1] );
		for my $n ( grep { -e $tsvPath.'/'.$name[$_].'/value.tsv' } ( 0, 1 ) ){
			&setWarn( "					sN  проверка варианта $n - $tsvPath.'/'.$name[$n].'/value.tsv'" );
			my $old = join "\n", &getFile( $tsvPath.'/'.$name[$n].'/value.tsv' );
			$old = Encode::decode_utf8($old);#читает и так нормально, но проверку на эквивалетность без флага не пройдет
			if ( $value eq $old ){ 
				&setWarn( "					sN  да, это текущее значение, оставляем его" );
				$name = $name[$n] 
			}
			else { 
				&setWarn( "					sN  нет, значения не совпали - игнорируем" );
				$name[$n] = undef 
			}
		}
		if (not $name ){
			&setWarn( "					sN  присвоение первого попавшегося имени из двух: @name" );
			( $name ) = grep { $_ } @name;
			
			&setFile( $tsvPath.'/'.$name.'/value.tsv', $value );
			&rinseProc( $name, @value );
		}	
	}
	else{
		$name = 'i';
		&rinseProc( 'i', '' )
	}
	return $name
}
sub setWarn {
	$dbg || return;
	my ( $text, $logFile )=@_;
	-d $logPath || mkdir $logPath;
	my @c = caller;
	if ($logFile){
		$log = $logFile;  #что бы записи отладки для контроля и другого шли в разные логи
		unlink $log if -e $log;
	}
	my $time = time;
	#$text = Encode::decode_utf8($text);
	open( FILE, ">>", $log ) || die "Ошибка при открытии файла $log: $!\n"; #:utf8 без :utf8 выдает ошибку "wide character..."
		#$text = Encode::decode_utf8($c[2].' '.$text);
		print FILE $text, "\n";#  $c[3], ' ' - секунда
	close (FILE);
}
sub setMessage {
	open (REINDEX, '>>reindex.txt')|| die "Ошибка при открытии файла reindex.txt: $!\n";
		print REINDEX $_[0]."\n";#  $c[3], ' ' - секунда
	close (REINDEX);
}
sub setLink {
	my ( $fromPhysic, $toLink )=@_;
	if ( -d $toLink ){
		if ( readlink( $toLink ) ne $fromPhysic ){
			rmdir $toLink;
			symlink( $fromPhysic => $toLink )
		}
	}
	else{ symlink( $fromPhysic => $toLink ) }
}


sub getID {
	my $name = shift;
#	&setWarn("						gI  @_" );
	if ( $name=~m!^/m8/[dirn]/[dirn][\d\w_\-]*$! or $name=~m!^/m8/author/[a-z]{2}[\w\d]*$! ){ $name=~s!^/!!; return $name }
	elsif( $name=~m!^([dirn])[\w\d_\-]*$! ){ return 'm8/'.$1.'/'.$name }
	else{ return $userPath.'/'.$name }
}
sub getFile {
	&setWarn( "						gF @_" );
	my $file = shift;
	-e $file || return;
	my @text;
	open (FILE, $file)|| die "Error opening file $file: $!\n"; #'encoding(UTF-8)', "<:utf8", 
		while (<FILE>){
			s/\s+\z//;
			push @text, $_;
		}
	close (FILE);
	if ( @text > 1 ){	return @text 	}	#elsif ( $text[0] ){ return $text[0]	}
	elsif (@text) 	{	return $text[0]	}
	else { 				return '' 		}
}
sub getDir{
	my ( $dir, $dir_only )=@_;
#	&setWarn("						gD  @_" );
	-d $dir.'/' || return; #используется в начале стирки при детектировании автора
	opendir (TEMP, $dir.'/') || die "Error open dir $dir: $!";
		my @name = grep {!/^\./} readdir TEMP;
	closedir(TEMP);
	if ( $dir_only ){ 
		@name = grep { -d $dir.'/'.$_ } @name;
		if ($dir_only == 1) { return @name }
		elsif ($dir_only == 2) { return $name[0] }
	}
	else { return @name } #возвращает имена файлов включая имена директорий
}
sub getHash {
	-e $_[0] || return;
	my $hash = decode_json( &getFile( $_[0] ) );	
	return %{$hash};
}
sub getJSON {
	my ( $pathDir, $root ) = @_;
#	&setWarn("						gJ Получение JSON @_" );
	-d $pathDir || return; #иначе скрипт прежде чем проверить наличие файла в папке будет еще 2 секунды искать саму папку
	-e $pathDir.'/'.$root.'.json' || return;
	my %hash = &getHash( $pathDir.'/'.$root.'.json' );
	return %{$hash{$root}}
}
sub getSetting {
	my $key = shift;
	&setWarn("						getSetting  @_" );	
	if ( -e $configPath.'/'.$key.'.txt' ){ $setting{$key} = &getFile( $configPath.'/'.$key.'.txt' ) }
	else { &setFile( $configPath.'/'.$key.'.txt', $setting{$key} ) }
	return $setting{$key}
}
sub getDoc {
	my ( $temp, $adminMode, $xslFile )=@_;
	my $doc = XML::LibXML::Document->new( "1.0", "UTF-8" );
	$$temp{'quest'} = $$temp{'modifier'} if defined $$temp{'modifier'};
	my $rootElement = $doc->createElement($$temp{'fact'});
	$doc->addChild($rootElement);
	if ( defined $$temp{'number'} ){
		&setWarn('     Идет выдача отладочной информации '.$$temp{'number'} );
		foreach my $s ( 0..$#{$$temp{'number'}} ){
			&setWarn("      Передача в темп-файл информации о созданном номере $s");
			my $tripleElement = $doc->createElement('number');
			foreach my $key ( keys %{$$temp{'number'}[$s]} ){
				$tripleElement->setAttribute($key, $$temp{'number'}[$s]{$key});
			}
			$tripleElement->appendText($s);
			$rootElement->addChild($tripleElement);
		}
		delete $$temp{'number'}
	}
	$rootElement->appendText('_');
	for my $param ( grep {$$temp{$_}} keys %{$temp} ) {	$rootElement->setAttribute( $param, $$temp{$param} ) }
	my $localtime = localtime($$temp{'time'}); 
	$rootElement->setAttribute( 'localtime', $localtime );
	if ($xslFile){
		&setWarn('      Подготовка преобразования на клиенте');
		my $pi = $doc->createProcessingInstruction("xml-stylesheet"); #нельзя добавлять в конце поэтому добавляем вручную
		$pi->setData(type=>'text/xsl', href => $xslFile);
		$doc->insertBefore($pi, $rootElement);
	}
	my $pp = XML::LibXML::PrettyPrint->new();
	$pp->pretty_print($rootElement);
	
	my $tempFile = $logPath.'/temp.xml';
	copy( $tempFile, $tempFile.'.xml' ) or die "Copy failed: $!" if -e $tempFile;
	#copy( $tempFile, $tempFile.'.xml' ) if -e $tempFile and $adminMode;
	&setFile( $tempFile, $doc );
	return $doc
}
sub getTriple {
	&setWarn("		gT @_");
	my ( $user, $name )=@_;
	my $val = &getFile( $planeDir.'/'.$user.'/tsv/'.$name.'/value.tsv' );
	&setWarn("		gT val: $val");
	my @value = ( split "\t", $val );
	unshift @value, $name;
	&setWarn("		gT return: @value");
	return @value 
}


sub delDir {
	#&setWarn( "						dD @_" );
	my ( $dirname, $subdir)=@_;
	-d $dirname || return;
	my $count = 0;
	for my $file ( &getDir( $dirname ) ){
		if ( -d $dirname.'/'.$file ){ $count += &delDir( $dirname.'/'.$file ) }
		else {
#			&setWarn("						dD   Удаление файла $dirname/$file" );
			unlink  $dirname.'/'.$file;
			$count++
		}	
	}
	rmdir $dirname;
	if ( $subdir ){
		&setWarn("						dD  Удаление поддиректорий" );
		my @dir = split '/', $dirname;
		pop @dir;
		while (@dir > $subdir){
#			&setWarn("						dD   Удаление поддиректории @dir" );		
			my $dir = join '/', @dir;
			if ( &getDir( $dir, 1 ) ){ @dir = () }
			else { &delDir( $dir ) }
			pop @dir
		}
	}
	return $count
}


sub utfText {
	my $value = shift;
	$value =~ tr/+/ /;
	$value =~ s/%([a-fA-F0-9]{2})/pack("C", hex($1))/eg;
	return $value
}