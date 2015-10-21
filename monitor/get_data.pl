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
use Data::Dumper qw(Dumper);

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
my $datadir   = "../data";
my $webdir    = "../www" ;
my $codedir   = dirname( realpath( $0 ) );
my $dataValid = 300;                        # Time the data should remain valid as indicated in the data file.   

#
# Overwrite the defaults with values specified on the command line (if any)
#
while (@ARGV) {

    if ( $ARGV[0] =~ /^-D|^--data-dir/ ) {
    	$datadir = $ARGV[1];
    	shift @ARGV;
    	shift @ARGV;
    } elsif ( $ARGV[0] =~ /^-W|^--web-dir/ ) {
    	$webdir = $ARGV[1];
    	shift @ARGV;
    	shift @ARGV;
    } elsif ( $ARGV[0] =~ /^-I|^--interval/ ) {
    	$dataValid = $ARGV[1];
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

# Set the time stamp of the data capture,
$timestampL = strftime( "%c",           localtime );  # Time stamp used for the web page in thelocal time zone.
$timestampZ = strftime( "%Y%m%dT%H%MZ", gmtime );     # Time stamp in Zulu time.

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
  25 => "graphs.html#AHU"
);

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
# Generate the raw data page
#
#

generate_rawdata( \%devices, $webdir );


#
# Create the log files for the graphs.
#
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
# Create full log files in case we ever need more data.
# These files are created per month.
#
$chiller01data->FullLog( $datadir );
$chiller02data->FullLog( $datadir );
$chiller04data->FullLog( $datadir );
$cooler01data->FullLog( $datadir );
$cooler02data->FullLog( $datadir );
#$ahu01data->FullLog( $datadir );
#$ahu02data->FullLog( $datadir );
$ahu03data->FullLog( $datadir );
$ahu04data->FullLog( $datadir );
$ahu05data->FullLog( $datadir );

#
#
# Re-generate the overview web page if needed
#
#

my $mtime_template =  (stat("$codedir/TEMPLATES/monitor_template.html")->mtime);
my $mtime_code     =  (stat("$codedir/get_data.pl")->mtime);

if ( ( ! (-e "$webdir/index.html") ) || 
     ( $mtime_template > (stat("$webdir/index.html")->mtime) ) || 
     ( $mtime_code > (stat("$webdir/index.html")->mtime) ) ) {

    generate_monitor_root( \%devices, \%links, $codedir, $webdir );
    
} # End of the re-generation of the index web page.

#
#
# Re-generate the details web pages
#
#

#
# We'll rebuild all of them as soon as one is missing or out-of-date.
#

my $rebuildDetails = 0;
$mtime_template    =  (stat("$codedir/TEMPLATES/details_template.html")->mtime);
#$mtime_code        =  (stat("$codedir/get_data.pl")->mtime);   # Still set from before.

foreach my $device (values  %devices) {
	
	my $filename = "$webdir/$device->{'label'}-details.html";
	
    $rebuildDetails = $rebuildDetails 
                      || ( ! (-e $filename) )
                      || ( $mtime_template > (stat($filename)->mtime) )
                      || ( $mtime_code > (stat($filename)->mtime) ); 
    		
}


if ( $rebuildDetails ) {
	
    # Read the web template
    open( my $webtemplateFH, "<", "$codedir/TEMPLATES/details_template.html" ) 
      or die "Could not open the web template file $codedir/details_template.html";
    my @webtemplate = <$webtemplateFH>;
    close( $webtemplateFH );
    
    while ( ($devkey, $device) = each %devices ) {
        generate_detail_page( \@webtemplate, $device, $devkey, $webdir );
    }  # End of while loop over the devices.

}  # End of if ( rebuildDetails )


#
# Check the web directory and copy other web files (from the WEB subdirectory of 
# the code) to that directory if needed.
# This doesn't take much time and ensures that changes to the web code will carry
# formward to the web server directory.
#

if ( ( ! (-e "$webdir/graphs.html") ) || 
     ( (stat("$codedir/WEB/graphs.html")->mtime) > (stat("$webdir/graphs.html")->mtime) ) || 
     ( $mtime_code > (stat("$webdir/graphs.html")->mtime) ) ) {
	# Copy the files in the WEB subdirectory of the code to the web server directory.
	# We could name them one by one, but then we should not forget to adapt this bit of 
	# code when we add files. 
	# This loop is more robust.
    # print "Updating web pages from WEB subdirectory.\n";
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


################################################################################
################################################################################
#
# Print help.
#
#

sub print_help {

	print "Options:\n";
    print "* -D or --data-dir DIR: Specify the name of the directory where the log files will be put.\n";
    print "* -W or --web-dir DIR: Specify the name of the directory where the web files will be put.\n";
    print "* -I or --interval NUMBER: Time that the data should remain valid in seconds.\n";
    print "* -H or --help: Display this help and quit.\n\n";

}


################################################################################
################################################################################
#
# Generate the raw data page.
#
#

sub generate_rawdata {
	
	my $devices = $_[0];  # This is a reference!
	my $webdir  = $_[1];
	
	#
	# First build the alarm strings.
	#
	
	# Also create a hash with the number corresponding to each device label for sorting.
    my %deviceOrder = ( );
    while ( ($key, $device) = each %$devices ) {
        $deviceOrder{$device->{'label'}} = $key;
    } 
	
    # Get the alarm strings
	my @alarmMssgs = () ; # an array, each entry is a hash with three keys: source, message and level.
    foreach my $workdevice (values %$devices ) {
	    push @alarmMssgs, $workdevice->AlarmMssgs();
    }
    
    # Sort the message first according to how critical they are, then according to the device order.
    @alarmMssgs = sort { (($res = ($a->{level} cmp $b->{level})) == 0) ? ($deviceOrder{$a->{source}} <=> $deviceOrder{$b->{source}}) : $res } @alarmMssgs ;
	
	#
	# Now we an build the web page.
	#
    
    my @outputpage = ( );
    
    # Add the time stamp
    push @outputpage, "<div id=\"RD_time2L\">$timestampL<br>$timestampZ</div>\n";
    push @outputpage, "<div id=\"RD_time1L\">$timestampL ($timestampZ)</div>\n";
    
    # Add the alarm strings.
    push @outputpage, "<div id=\"RD_alarms\">\n";
    for my $c1 (0 .. $#alarmMssgs) {
        $spanclass = $alarmMssgs[$c1]{'level'};
        $spanclass =~ s/\-//;
        push @outputpage, "  <span class=ConsoleMssg${spanclass}>$alarmMssgs[$c1]{source}: $alarmMssgs[$c1]{message}</span>" . 
                          ( ($c1 < $#alarmMssgs) ? "<br/>\n" : "\n") ;
    }
    push @outputpage, "</div>\n";
    
    foreach my $devkey ( sort {$a <=> $b} keys %$devices ) {
    
    	my $device = $devices->{$devkey};
    
        push @outputpage, join( '', "<div>Variables for device ", $device->{'label'}, "\n" );
        
        # Device status
        $status = $device->Status( );
        $class = $status ; $class =~ s/\-//;
        push @outputpage, "  <div id=\"RD\_D$devkey\_SV\">$status</div>\n";
        
        
        # Do the digital variables
        push @outputpage, "  <div>Digital variables\n";
        foreach my $mykey ( sort {$a <=> $b} keys %{ $device->{'description'}{'digital'} } ) { 
        	$label = "RD\_D$devkey\_D$mykey";
        	($value, $valtext, $remark) = $device->DVar( $mykey ); # In fact, we don't need $remark here...
        	! length( $valtext ) || ( $value = join( '', $value, ' - ', $valtext ) ); # Add textual value
        	push @outputpage, "    <div id=\"$label\">$value</div>\n";
        }    
        push @outputpage, "  </div>\n";
        
        # Do the analog variables
        push @outputpage, "  <div>Analog variables\n";
        foreach my $mykey ( sort {$a <=> $b} keys %{ $device->{'description'}{'analog'} } ) { 
        	$label = "RD\_D$devkey\_A$mykey";
        	($value, $units, $remark) = $device->AVar( $mykey ); # In fact, we don't need $units and $remark here...
        	push @outputpage, "    <div id=\"$label\">$value</div>\n";
        }    
        push @outputpage, "  </div>\n";
        
        # Do the integer variables
        push @outputpage, "  <div>Integer variables\n";
        foreach my $mykey ( sort {$a <=> $b} keys %{ $device->{'description'}{'integer'} } ) { 
        	$label = "RD\_D$devkey\_I$mykey";
        	($value, $units, $remark) = $device->IVar( $mykey ); # In fact, we don't need $units and $remark here...
        	push @outputpage, "    <div id=\"$label\">$value</div>\n";
        }    
        push @outputpage, " </div>\n";
        
        # Set the expiration time
        $timestampExp = strftime( "%Y-%m-%dT%H:%M:%SZ", 
                                  gmtime( time() + $dataValid ) );     # Time stamp in Zulu time in the format for JS date.Parse
        push @outputpage, "  <div id=\"RD_Expiration\">$timestampExp</div>\n";
        
        push @outputpage, "</div>\n"; 
    
    }  # End of while loop over all devices.
    
    #push @outputpage, "</body>\n</html>\n";
    
    open( my $webpageFH, ">", "$webdir/rawdata.txt" );
    print $webpageFH @outputpage;
    close( $webpageFH );
	
} # end of generate_rawdata


################################################################################
################################################################################
#
# Rebuild index.html.
#
#

sub generate_monitor_root( ) {
	
    my $devices = shift;  # This is a reference! 
    my $links   = shift;  # This is a reference! 
	my $codedir = shift;
	my $webdir  = shift;
	
    #print "Regenerating the index.html file.\n";

    my @outputpage = () ;
    
    open( my $webtemplate, "<", "$codedir/TEMPLATES/monitor_template.html" ) 
      or die "Could not open the web template file $codedir/monitor_template.html";
    
    while ($line = <$webtemplate>) {
    	# Note that for simplicity we assume that the HTML contains only one
    	# %status%, %avar% or %dvar% command per line.
    	if ( $line =~ /(.*)\%avar\((\d+),(\d+)\)\%(.*)/ ) {
    		$pre    = $1;
    		# $devnum = $2;   # Commented out to reduce data copying as the values remain valid until they are used anyway.
    		# $varnum = $3;
    		$post   = $4;
    		$body = "<span class=\"dataItem\" id=\"D$2\_A$3\"></span>";
    		($value, $units, $remark) = $devices->{$2}->AVar( $3 );    # $value is not needed here.
    		#if ( $units ne '') { $body = $body.'&nbsp;'.$units; }
    		! length( $units ) || ( $body = $body.'&nbsp;'.$units ); # Trick from a Perl book, should be more efficient than the above if.
    		if ( $remark ne '') {
    			$pre =~ s/\"data\"/\"data dataRemark\"/g;
    			$body = join( '', $body, '<div class="dataRemark"><span class="dataRemark">', $remark, '</span></div>' );
    		}
    		push @outputpage, $pre.$body.$post."\n";
    	}
    	elsif ( $line =~ /(.*)\%ivar\((\d+),(\d+)\)\%(.*)/ ) {
    		$pre    = $1;
    		# $devnum = $2;
    		# $varnum = $3;
    		$post   = $4;
    		$body = "<span class=\"dataItem\" id=\"D$2\_I$3\"></span>";
    		($value, $units, $remark) = $devices->{$2}->IVar( $3 );    # $value is not needed here.
    		#if ( $units ne '') { $body = $body.'&nbsp;'.$units; }
    		! length( $units ) || ( $body = $body.'&nbsp;'.$units );
    		if ( $remark ne '') {
    			$pre =~ s/\"data\"/\"data dataRemark\"/g;
    			$body = join( '', $body, '<div class="dataRemark"><span class="dataRemark">', $remark, '</span></div>' );
    		}
    		push @outputpage, $pre.$body.$post."\n";
    	}
    	elsif ( $line =~ /(.*)\%dvar\((\d+),(\d+)\)\%(.*)/ ) {
    		$pre    = $1;
    		# $devnum = $2;
    		# $varnum = $3;
    		$post   = $4;
    		$body = "<span class=\"dataItem\" id=\"D$2\_D$3\"></span>";
    		($value, $valtext, $remark) = $devices->{$2}->DVar( $3 );   # $value and $valtext are not needed here.
    		if ( $remark ne '') {
    			$pre =~ s/\"data\"/\"data dataRemark\"/g;
    			$body = $body.'<div class="dataRemark"><span class="dataRemark">'.$remark.'</span></div>';
    		}
    		#$line =~ s/(.*)\%dvar\(\d+,\d+\)\%(.*)/$1$replace$2/;
    		push @outputpage, $pre.$body.$post."\n";
    	}
    	elsif ( $line =~ /^( *)(.*)\%status\((\d+)\)\%(.*)/ ) {
    		# We assume 4 possible values for status: Normal, Non-Critical, Critical and Off.
    		$spaces    = $1;
    		$startline = $2;
    		$devnum    = $3;
    		$endline   = $4;
    		$status = "<span class=\"statusItem\" id=\"D$3\_SV\"></span>";
    		$replace = "$spaces  <button class=\"StatusButtonNormal\" onclick=\"parent.location='$devices->{$devnum}->{'label'}-details.html'\">$status<\/button><br/>\n".
    		           "$spaces  <img src=\"48px-line_chart_icon.png\"  onclick=\"parent.location='$links->{$devnum}'\">&nbsp;&nbsp;\n" . 
    		           "$spaces  <img src=\"48px-table_icon.png\"       onclick=\"parent.location='$devices->{$devnum}->{'label'}-details.html'\">\n";
    		$line = $spaces.$startline."\n".$replace.$spaces.$endline."\n";
    		push @outputpage, $line;
    	} elsif ( $line =~ /(.*)\%timestamp\%(.*)/ ) {
        	push @outputpage, $1.'<span class="dataItem" id="time2L"></span>'.$2."\n";
    	} elsif ( $line =~ /.*\%AlarmMssgs\%.*/ ) {
    		# We do assume that there is only a %AlarmMssgs% on that line in the HTML file, but we will
    		# prepend each line of the output with the correct number of spaces that was also used in the
    		# template.
    		$subst = '<span class="dataItem" id="alarms"></span>';
    		$line =~ s/\%AlarmMssgs\%/$subst/;
    		push @outputpage, $line;
    	} else { push @outputpage, $line; }
    };
    
    close( $webtemplate );
    
    open( $webpageFH, ">", "$webdir/index.html" );
    print $webpageFH @outputpage;
    close( $webpageFH );
    
}  # End of generate_monitor_root




################################################################################
################################################################################
#
# Rebuild a details page.
#
#

sub generate_detail_page(  ) {
	
    my $webtemplate = shift;  # Reference!
    my $device      = shift;
    my $devkey      = shift;
    my $webdir      = shift; 
    
    #print "Regenerating $webdir/$device->{'label'}-details.html\n";

    # 
    # Create the details web page for device $device.
    #
        
    # - Create an empty list as the output structure
    @outputpage = ( );
        
    # - Now process the template and build the output page.
    foreach $line(@$webtemplate) {
    	
    	if ( $line =~ /(.*)\%device\%(.*)/ ) {
    		push @outputpage, $1.$device->{'label'}.$2."\n";
    	} elsif ( $line =~ /(.*)\%timestamp\%(.*)/ ) {
     		push @outputpage, $1.'<span class="dataItem" id="time1L"></span>'.$2."\n";
    	} elsif ( $line =~ /.*\%dataLines.*/ ) {
    		# This is the main block of this part of the code where most of the work is done.
    		# + Parse the command
    		$line =~ s/\\n/\n/g;
    		my @cmds = split( '\|\|', $line ); # Should result in a 6-elenment array, the first and the last element aren't really needed.
    		my $pre      = $cmds[1];
    		my $post     = $cmds[2];
    		my $withdata = $cmds[3];
    		my $nodata   = $cmds[4];
    		# + Get the keys of each type and sort them numerically.
    		@Dkeys = sort { $a <=> $b } ( keys %{$device->{'digital'}} );
     		@Akeys = sort { $a <=> $b } ( keys %{$device->{'analog'}} );
    		@Ikeys = sort { $a <=> $b } ( keys %{$device->{'integer'}} );
    		# + Determine the largest of the number of keys of the three variable types.
    		$max = ( $#Dkeys > $#Akeys ) ? $#Dkeys : $#Akeys;
    		$max = ( $max > $#Ikeys )    ? $max    : $#Ikeys;
    		# + Loop over the rows of the table to generate.
    		for ( my $c = 0; $c <= $max; $c++ ) {
    			# ++ Start of output record
    			push @outputpage, $pre;
    			# ++ Digital variable (if there is one)
    			if ( $c <= $#Dkeys ) {
    				$workline = $withdata;
    				$key = $Dkeys[$c];
    				$label = $device->{'description'}{'digital'}{$key}{'info'};
    				$body = "<span class=\"dataItem\" id=\"D$devkey\_D$key\"></span>";
 		            ($value, $valtext, $remark) = $device->DVar( $key );         # $value and $valtext are not needed here.
		            if ( $remark ne '') {
			            $workline =~ s/\"data\"/\"data dataRemark\"/g;
			            $body = $body.'<div class="dataRemark"><span class="dataRemark">'.$remark.'</span></div>'; # Add a remark.
		            }
		            $workline =~ s/\%number\%/$key/;
		            $workline =~ s/\%label\%/$label/;
		            $workline =~ s/\%value\%/$body/;		            
		            push @outputpage, $workline;  				
    			} else { push @outputpage, $nodata; }
     			# ++ Analog variable (if there is one)
    			if ( $c <= $#Akeys ) {
    				$workline = $withdata;
    				$key = $Akeys[$c];
    				$label = $device->{'description'}{'analog'}{$key}{'info'};
    				$body = "<span class=\"dataItem\" id=\"D$devkey\_A$key\"></span>";
		            ($value, $units, $remark) = $device->AVar( $key );            # $value is not needed here.
		            #if ( $units ne '') { $body = join( '', $body, '&nbsp;', $units ); }
		            ! length( $units ) || ( $body = $body.'&nbsp;'.$units );      # Add units to the value (if units are defined)
		            if ( $remark ne '') {
			            $workline =~ s/\"data\"/\"data dataRemark\"/g;
			            $body = $body.'<div class="dataRemark"><span class="dataRemark">'.$remark.'</span></div>'; # Add a remark.
		            }
		            $workline =~ s/\%number\%/$key/;
		            $workline =~ s/\%label\%/$label/;
		            $workline =~ s/\%value\%/$body/;		            
		            push @outputpage, $workline;  				
    			} else { push @outputpage, $nodata; }
     			# ++ Integer variable (if there is one)
    			if ( $c <= $#Ikeys ) {
    				$workline = $withdata;
    				$key = $Ikeys[$c];
    				$label = $device->{'description'}{'integer'}{$key}{'info'};
    				$body = "<span class=\"dataItem\" id=\"D$devkey\_I$key\"></span>";
		            ($value, $units, $remark) = $device->IVar( $key );            # $value is not needed here.
		            #if ( $units ne '') { $body = join( '', $body, '&nbsp;', $units ); }
		            ! length( $units ) || ( $body = $body.'&nbsp;'.$units );      # Add units to the value (if units are defined)
		            if ( $remark ne '') {
			            $workline =~ s/\"data\"/\"data dataRemark\"/g;
			            $body = $body.'<div class="dataRemark"><span class="dataRemark">'.$remark.'</span></div>'; # Add a remark.
		            }
		            $workline =~ s/\%number\%/$key/;
		            $workline =~ s/\%label\%/$label/;
		            $workline =~ s/\%value\%/$body/;		            
 		            push @outputpage, $workline;  				
    			} else { push @outputpage, $nodata; }
    			# ++ Terminate the record
    			push @outputpage, $post;
    		} # End of for-loop.
        		
    	} else { push @outputpage, $line; }
        	
    } # End of the foreach loop iterating over the lines of the webpage template
    
    # - Finally write the output page.
    open( $webpageFH, ">", "$webdir/$device->{'label'}-details.html" );
    print $webpageFH @outputpage;
    close( $webpageFH );
 
}

