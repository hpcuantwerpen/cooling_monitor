#! /usr/bin/env perl
#
# $HeadURL$
# $Id$
#
# Uses the following non-core modules:
# + Net::SNMP 
#
# NOTE:
# - Chiller data format: Fields are tab-separted, with the following fields:
#   01 timestamp: "%y%m%d-%H%M"
#   02 ambient temperature            AD14: analog  var 19   AD04: analog var  17
#   03 Return water temperature       AD14: analog  var 20   AD04: analog var  4
#   04 Supply water temperature       AD14: analog  var 21   AD04: analog var  5
#   05 set point                      AD14: analog  var 23   AD04: analog var  13
#   06 evaporator inlet temperature   AD14: analog  var 30   AD04: /
#   07 circuit 1 liquid pressure      AD14: analog  var 24   AD04: analog var  1
#   08 circuit 2 liquid pressure      AD14: analog  var 25   AD04: analog var  2
#   09 eev1 suction press. circ. 1    AD14: analog  var 40   AD04: analog var  11
#   10 eev2 suction press. circ. 2    AD14: analog  var 41   AD04: analog var  12
#   11 eev1 suction temp. circ. 1     AD14: analog  var 38   AD04: /
#   12 eev2 suction temp. circ. 2     AD14: analog  var 39   AD04: /
#   13 eev1 actual superheat          AD14: analog  var 42   AD04: /
#   14 eev2 actual superheat          AD14: analog  var 43   AD04: /
#   15 head pressure control          AD14: analog  var 36   AD04: /
#   16 water flow                     AD14: analog  var 54   AD04: analog var  122
#   17 free cooling valve position    AD14: analog  var 34   AD04: /
#   18 compressor 1 on/off            AD14: digital var 35   AD04: digital var 15
#   19 compressor 2 on/off            AD14: digital var 37   AD04: digital var 16
#   20 compressor 3 on/off            AD14: digital var 39   AD04: digital var 17
#   21 compressor 4 on/off            AD14: digital var 41   AD04: digital var 18
#   22 pump 1 on/off                  AD14: digital var 29   AD04: digital var 21
#   23 pump 2 on/off                  AD14: digital var 31   AD04: digital var 22
#   24 non-critical alarm             AD14: digital var 102  AD04: 0
#   25 critical alarm                 AD14: digital var 103  AD04: 23 && 24 && 54 
#
# - Cooler data format: Fields are tab-separated, with the following fields:
#   01 timestamp: "%y%m%d-%H%M"
#   02 return air temparature        analog var 35
#   03 return air humidity           analog var 34
#   04 supply air temperature        analog var 36
#   05 set point                     analog var 48
#   06 aisle differential pressure   analog var 39
#   07 inlet water temperature       analog var 33
#   08 evaporator fan speed          analog var 2
#   09 CW valve position             analog var 44
#   10 fan trip                      digital var 31
#   11 high return temperature       digital var 57
#   12 low return temperature        digital var 58
#   13 high supply temperature       digital var 59
#   14 low supply temperature        digital var 60
#
# - AHU data format: Fields are tab-separated, with the following fields:
#   01 timestamp: "%y%m%d-%H%M"
#   02 air return temperature        analog var 4
#   03 air return humidity           analog var 1   
#   04 air supply temperature        analog var 5
#   05 set point                     /
#   06 fan operating                 digital var 21
#   07 non-critical alarm            digital var 26
#   08 critical alarm                digital var 27
#


#use strict;
#use Data::Dumper qw(Dumper);

use IO::File;
use File::Basename;
use File::Copy;
use File::stat;
use Cwd 'realpath';
use POSIX qw(strftime);

use DEVICE::chillerAD04;
use DEVICE::chillerAD14;
use DEVICE::coolerAD;
use DEVICE::ahuAD;

#
# Set some locations etc.
#
my $datadir = "../data";
my $webdir  = "../www" ;
my $codedir = dirname( realpath( $0 ) );

#
# Overwrite the defaults with values specified on the command line (if any)
#
while (@ARGV) {

    if ( $ARGV[0] =~ /^-D|^--data-dir/ ) {
    	$datadir = $ARGV[1];
    	shift @ARGV;
    	shift @ARGV;
    } elsif ( $ARGV[0] =~ /^-W|^--dweb-dir/ ) {
    	$webdir = $ARGV[1];
    	shift @ARGV;
    	shift @ARGV;
    } elsif ( $ARGV[0] =~ /^-H|^--help/ ) {
        shift @ARGV;
        print_help( );
        exit(0);
    }
	
}

#
# Check if the directories exist.
#

if ( ! -d $datadir ) {
	print "Cannot find the data directory $datadir. Did you use the right options?\n";
	print_help( );
	exit( 1 );
}

if ( ! -d $webdir ) {
	print "Cannot find the web file directory $webdir. Did you use the right options?\n";
	print_help( );
	exit( 1 );
}

#
# Collect the data
#

# Routine to fetch data from chiller01/chiller02
$chiller01data = chillerAD04->New( "10.28.243.234", 6, "chiller01" );
$chiller02data = chillerAD04->New( "10.28.243.234", 7, "chiller02" );

# Routine to fetch data from Chiller04
$chiller04data = chillerAD14->New( "10.28.233.52", "chiller04" );

# Routine to fetch the data from the coolers of hopper and turing
$cooler01data = coolerAD->New( "10.28.233.50", "cooler01" );
$cooler02data = coolerAD->New( "10.28.233.51", "cooler02" );

# Routine to fetch the data from the Air Handling Units in the compute room
$ahu01data = ahuAD->New( "10.28.243.234", 1, "ahu01" );
$ahu02data = ahuAD->New( "10.28.243.234", 2, "ahu02" );
$ahu03data = ahuAD->New( "10.28.243.234", 3, "ahu03" );
$ahu04data = ahuAD->New( "10.28.243.234", 4, "ahu04" );
$ahu05data = ahuAD->New( "10.28.243.234", 5, "ahu05" );

#
# Create the log files for the graphs.
#
$timestamp = strftime( "%y%m%d-%H%M", localtime );  # Time stamp used for the web page.

$chiller01data->Log( "$datadir/chiller01.data" );
$chiller02data->Log( "$datadir/chiller02.data" );
$chiller04data->Log( "$datadir/chiller04.data" );
$cooler01data->Log( "$datadir/cooler01.data" );
$cooler02data->Log( "$datadir/cooler02.data" );
$ahu01data->Log( "$datadir/ahu01.data" );
$ahu02data->Log( "$datadir/ahu02.data" );
$ahu03data->Log( "$datadir/ahu03.data" );
$ahu04data->Log( "$datadir/ahu04.data" );
$ahu05data->Log( "$datadir/ahu05.data" );

#
# Create full log files in case we ever need more data.
# These files are created per month.
#
$chiller01data->FullLog( $datadir );
$chiller02data->FullLog( $datadir );
$chiller04data->FullLog( $datadir );
$cooler01data->FullLog( $datadir );
$cooler02data->FullLog( $datadir );
$ahu03data->FullLog( $datadir );
$ahu04data->FullLog( $datadir );
$ahu05data->FullLog( $datadir );

#
# Generate the device list hash
#
%devices = (
   1 => $chiller01data,
   2 => $chiller02data,
   4 => $chiller04data,
  11 => $cooler01data,
  12 => $cooler02data,
  23 => $ahu03data,
  24 => $ahu04data,
  25 => $ahu05data	
);

%links = (
   1 => "graphs.html#chiller01",
   2 => "graphs.html#chiller02",
   4 => "graphs.html#chiller04",
  11 => "graphs.html#cooler01",
  12 => "graphs.html#cooler02",
  23 => "graphs.html#AHU",
  24 => "graphs.html#AHU",
  25 => "graphs.html#AHU",
);

# Also create a hash with the number corresponding to each device label for sorting.
%deviceOrder = ( );
while ( ($key, $device) = each %devices ) {
    $deviceOrder{$device->{'label'}} = $key;
} 

#
# Introduce some problems for debug purposes.
#
my $debug = 0;
if ( $debug == 1 ) {
    $chiller02data->{'digital'}{24}  = 1;
	$chiller04data->{'digital'}{102} = 1;
	$chiller04data->{'digital'}{120} = 1;
	$cooler02data->{'digital'}{59}   = 1;
	$ahu03data->{'digital'}{26}      = 1;
}

#
#
# Build the list of alarm string
#
#

@alarmMssgs = () ; # an array, each entry is a hash with three keys: source, message and level.
foreach my $workdevice (values %devices ) {
	push @alarmMssgs, $workdevice->AlarmMssgs();
}
# Sort the message first according to how critical they are, then according to the device order.
@alarmMssgs = sort { (($res = ($a->{level} cmp $b->{level})) == 0) ? ($deviceOrder{$a->{source}} <=> $deviceOrder{$b->{source}}) : $res } @alarmMssgs ;

#
#
# Generate the overview web page
#
#

my @outputpage = () ;

open( my $webtemplate, "<", "$codedir/TEMPLATES/monitor_template.html" ) 
  or die "Could not open the web template file $codedir/monitor_template.html";

while ($line = <$webtemplate>) {
	# Note that for simplicity we assume that the HTML contains only one
	# %status%, %avar% or %dvar% command per line.
	if ( $line =~ /.*\%avar\((\d+),(\d+)\)\%.*/ ) {
		($replace, $units, $remark) = $devices{$1}->AVar( $2 );
		$line =~ s/(.*)\%avar\(\d+,\d+\)\%(.*)/$1$replace$2/;
		push @outputpage, $line;
	}
	elsif ( $line =~ /.*\%dvar\((\d+),(\d+)\)\%.*/ ) {
		($replace, $units, $remark) = $devices{$1}->DVar( $2 );
		$line =~ s/(.*)\%dvar\(\d+,\d+\)\%(.*)/$1$replace$2/;
		push @outputpage, $line;
	}
	elsif ( $line =~ /.*\%status\((\d+)\)\%.*/ ) {
		# We assume 4 possible values for status: Normal, Non-Critical, Critical and Off.
		$devnum = $1;
		$status = $devices{$devnum}->Status( );
		$class = $status ; $class =~ s/\-//;
		$replace = "<button class=\"StatusButton${class}\" onclick=\"parent.location='$links{$devnum}'\">$status<\/button>";
		$line =~ s/(.*)\%status\(\d+\)\%(.*)/$1$replace$2/;
		push @outputpage, $line;
	} elsif ( $line =~ /.*\%timestamp\%.*/ ) {
		$line =~ s/(.*)\%timestamp\%(.*)/$1$timestamp$2/;
		push @outputpage, $line;
	} elsif ( $line =~ /.*\%AlarmMssgs\%.*/ ) {
		# We do assume that there is only a %AlarmMssgs% on that line in the HTML file, but we will
		# prepend each line of the output with the correct number of spaces that was also used in the
		# template.
		$line =~ /(.*)\%AlarmMssgs\%.*/;
		$prepend = $1;
		for my $c1 (0 .. $#alarmMssgs) {
	        $spanclass = $alarmMssgs[$c1]{'level'};
	        $spanclass =~ s/\-//;
	        push @outputpage, "$prepend<span class=ConsoleMssg${spanclass}>$alarmMssgs[$c1]{source}: $alarmMssgs[$c1]{message}</span>" . 
	                           ( ($c1 < $#alarmMssgs) ? "<br/>\n" : "\n") ;
		}
	} else { push @outputpage, $line; }
};

close( $webtemplate );

open( $webpage, ">", "$webdir/index.html" );
print $webpage @outputpage;
close( $webpage );

#
#
# Generate the plots with gnuplot
#
#

# First we read the GNUplot commands.
open(my $gnuplotCMDS, "<", "$codedir/TEMPLATES/plotcmds_template.gnuplot" );
my @plotcmds = <$gnuplotCMDS> ;
close( $gnuplotCMDS );

# Overwrite the defintions of datadir and webdir in the template as they are 
# there for testing purposes.
map { s/datadir =.*/datadir = \"$datadir\"/ ; 
	  s/webdir *=.*/webdir  = \"$webdir\"/ ;
	  $_ } @plotcmds;
	  
# Now send the commands to GNUplot.
open( my $gnuplotPipe, "| gnuplot" ) || die "Failed to send commands to GNUplot." ;
print $gnuplotPipe @plotcmds ;
close( $gnuplotPipe );

#
#
# Check the web directory and copy other web files (from the WEB subdirectory of 
# the code) to that directory if needed.
# This doesn't take much time and ensures that changes to the web code will carry
# formward to the web server directory.
#

if ( ( ! (-e "$webdir/graphs.html") ) || 
     ( stat("$codedir/WEB/graphs.html")->mtime > stat("$webdir/graphs.html")->mtime ) ) {
	# Copy the files in the WEB subdirectory of the code to the web server directory.
	# We could name them one by one, but then we should not forget to adapt this bit of 
	# code when we add files. 
	# This loop is more robust.
	opendir( DIR, "$codedir/WEB" );
	my @filestocopy = readdir( DIR );
	closedir( DIR );
	# Remove names that start with a . from the list. This includes . and ..,
	# but may also include hidden files put in place by the IDE during 
	# development.
	@filestocopy = grep( !/^\./, @filestocopy );
    # Finally do the copy.
    foreach my $file (@filestocopy) { 
    	copy( "$codedir/WEB/$file", "$webdir/$file" );
    }
}

#
# 
# Done.
#
#
exit( 0 );



################################################################################
################################################################################
#
# Some subroutines for use in this file only.
#
#

sub print_help {

	print "Options:\n";
    print "* -D or --data-dir DIR: Specify the name of the directory where the log files will be put.\n";
    print "* -W or --web-dir DIR: Specify the name of the directory where the web files will be put.\n";
    print "* -H or --help: Display this help and quit.\n\n";

}

