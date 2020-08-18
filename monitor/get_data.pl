#! /usr/bin/env perl
#
# $HeadURL$
# $Id$
#
# Uses the following non-core modules:
# + Net::SNMP 
#
# NOTE: See the design.txt file for more information on file formats and the
# design of the code.
#


#use strict;
use Data::Dumper qw(Dumper);

use IO::File;
use File::Basename;
use File::Copy;
use File::stat;
use Cwd 'realpath';
use POSIX qw(strftime);
use Time::Local;  # For the timelocal function.
use Storable;

use DEVICE::coolerAD;
use DEVICE::ahuAD;

#
# Set some locations etc.
#
my $datadir    = "../data";
my $webdir     = "../www" ;
my $codedir    = dirname( realpath( $0 ) );
#print( "Codedir: $codedir\n" );
my $dataValid  = 310;                           # Time the data should remain valid as indicated in the data file. 
my $mailto     = '';  
if ( $codedir =~ /\/opt\/.*/ ) {
  $mailto      = 'cooler@calcua.uantwerpen.be'; # Production use: cooler@calcua.uantwerpen.be   
  #Alternative if sending mail directly via smtp.uantwerpen.be should not work anymore:
  #$mailto      = 'kurt.lust@uantwerpen.be,franky.backeljauw@uantwerpen.be,stefan.becuwe@uantwerpen.be'
} else {
  $mailto      = 'kurt.lust@uantwerpen.be';     # Test use 
}
# Send mail via smtp.uantwerpen.be rather than via the master node as that one is  
# in the calcua.uantwerpen.be domain and then fails since cooler is not a loca
# userid. To do this, we also need to set the from address (-r option).
my $mailx      = '/bin/mailx -r cooler@calcua.uantwerpen.be -S smtp=smtp.uantwerpen.be';
#Alternative if sending mail directly via smtp.uantwerpen.be should not work anymore:
#my $mailx      = '/bin/mailx';

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

# Routine to fetch the data from the coolers of hopper and turing
$cooler01data = DEVICE::coolerAD->New( "10.28.233.50", "cooler01" );
$cooler02data = DEVICE::coolerAD->New( "10.28.233.51", "cooler02" );

# Routine to fetch the data from the Air Handling Units in the compute room
# $ahu01data = DEVICE::ahuAD->New( "10.28.233.53", 1, "ahu01" );
# $ahu02data = DEVICE::ahuAD->New( "10.28.233.53", 2, "ahu02" );
$ahu03data = DEVICE::ahuAD->New( "10.28.233.53", 3, "ahu03" );
$ahu04data = DEVICE::ahuAD->New( "10.28.233.53", 4, "ahu04" );
$ahu05data = DEVICE::ahuAD->New( "10.28.233.53", 5, "ahu05" );

# Set the time stamp of the data capture,
$timestampL = strftime( "%c",           localtime );  # Time stamp used for the web page in thelocal time zone.
$timestampZ = strftime( "%Y%m%dT%H%MZ", gmtime );     # Time stamp in Zulu time.

#
# Generate the device list hash
#
%devices = (
  11 => $cooler01data,
  12 => $cooler02data,
  23 => $ahu03data,
  24 => $ahu04data,
  25 => $ahu05data  
);

%links = (
  11 => "graphs.html#cooler01",
  12 => "graphs.html#cooler02",
  23 => "graphs.html#ahu03",
  24 => "graphs.html#ahu04",
  25 => "graphs.html#ahu05"
);

#
# Introduce some problems for debug purposes.
#
my $debug = 0;
if ( $debug == 1 ) {
	print "Setting some alarms for debug purposes.\n";
    $cooler01data->{'digital'}{59}   = 1; # High supply temp critical alarm
#    $cooler02data->{'digital'}{59}   = 1; # High supply temp critical alarm
    $ahu03data->{'digital'}{26}      = 1; # Non-critical alarm
}


#
# Get the alarms and send out mails if there are new or expired critical alarms.
#

(my $alarmMssgsRef, my $alarmListRef) = get_alarms( \%devices, $datadir );
#print "\n\nReturn of get_alarms: the list of new, active and expired alarms:\n"; print Dumper $alarmListRef;

send_mail( $alarmListRef, $mailto );


#
# Generate the raw data page
#

generate_rawdata( \%devices, $webdir, $alarmMssgsRef );


#
# Create the log files for the graphs.
# Don't log if we don't have valid data for now (this avoids problems when
# making the plots)
#
$cooler01data->{'valid'}  and $cooler01data->Log( "$datadir/cooler01.data" );
$cooler02data->{'valid'}  and $cooler02data->Log( "$datadir/cooler02.data" );
# $ahu01data->{'valid'}     and $ahu01data->Log( "$datadir/ahu01.data" );
# $ahu02data->{'valid'}     and $ahu02data->Log( "$datadir/ahu02.data" );
$ahu03data->{'valid'}     and $ahu03data->Log( "$datadir/ahu03.data" );
$ahu04data->{'valid'}     and $ahu04data->Log( "$datadir/ahu04.data" );
$ahu05data->{'valid'}     and $ahu05data->Log( "$datadir/ahu05.data" );

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
$cooler01data->{'valid'}  and $cooler01data->FullLog( $datadir );
$cooler01data->{'valid'}  and $cooler02data->FullLog( $datadir );
# $ahu01data->{'valid'}     and $ahu01data->FullLog( $datadir );
# $ahu02data->{'valid'}     and $ahu02data->FullLog( $datadir );
$ahu03data->{'valid'}     and $ahu03data->FullLog( $datadir );
$ahu04data->{'valid'}     and $ahu04data->FullLog( $datadir );
$ahu05data->{'valid'}     and $ahu05data->FullLog( $datadir );

################################################################################
#
# Install/update all web pages
# - Some are generated based on the loaded devices, from templates in TEMPLATES
# - Others are just copied from the WEB subdirectory and do not depend on this
#   script nor the devices that are being monitored through this script.
#

#
# Re-generate the overview web page if needed (from TEMPLATES/monitor_template.html)
# We'll do this if either the template file or this script has changed since the last update
#

my $mtime_template =  (stat("$codedir/TEMPLATES/monitor_template.html")->mtime);
my $mtime_code     =  (stat("$codedir/get_data.pl")->mtime);

if ( ( ! (-e "$webdir/index.html") ) || 
     ( $mtime_template > (stat("$webdir/index.html")->mtime) ) || 
     ( $mtime_code > (stat("$webdir/index.html")->mtime) ) ) {

    generate_monitor_root( \%devices, \%links, $codedir, $webdir );
    
} # End of the re-generation of the index web page.

#
# Re-generate the details web pages (from TEMPLATES/details_template.html)
#
# We'll rebuild all of them as soon as one is missing or out-of-date with 
# respect to the template or this script.
#

my $rebuildDetails = 0;
$mtime_template    =  (stat("$codedir/TEMPLATES/details_template.html")->mtime);
#$mtime_code        =  (stat("$codedir/get_data.pl")->mtime);   # Still set from before.

foreach my $device (values  %devices) {
    
    my $filename = "$webdir/$device->{'label'}-details.html";
    my $objdef   = $device->ObjDef();
    
    $rebuildDetails = $rebuildDetails 
                      || ( ! (-e $filename) )
                      || ( $mtime_template > (stat($filename)->mtime) )
                      || ( $mtime_code > (stat($filename)->mtime) )
                      || ( (stat($objdef)->mtime) > (stat($filename)->mtime) ); 
            
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
# Synchronise with the WEB subdirectory.
#
# Check the web directory and copy other web files (from the WEB subdirectory of 
# the code) to that directory if needed.
# This doesn't take much time and ensures that changes to the web code will carry
# formward to the web server directory.
# Note that these 
#

# if ( ( ! (-e "$webdir/graphs.html") ) || 
#      ( (stat("$codedir/WEB/graphs.html")->mtime) > (stat("$webdir/graphs.html")->mtime) ) || 
#      ( $mtime_code > (stat("$webdir/graphs.html")->mtime) ) ) {
#     # Copy the files in the WEB subdirectory of the code to the web server directory.
#     # We could name them one by one, but then we should not forget to adapt this bit of 
#     # code when we add files. 
#     # This loop is more robust.
#     # print "Updating web pages from WEB subdirectory.\n";
#     opendir( DIR, "$codedir/WEB" );
#     my @filestocopy = readdir( DIR );
#     closedir( DIR );
#     # Remove names that start with a . from the list. This includes . and ..,
#     # but may also include hidden files put in place by the IDE during 
#     # development.
#     @filestocopy = grep( !/^\./, @filestocopy );
#     # Finally do the copy.
#     foreach my $file (@filestocopy) { 
#         copy( "$codedir/WEB/$file", "$webdir/$file" );
#     }
# }

# Get the list of files in the WEB direcotry.
opendir( DIR, "$codedir/WEB" );
my @filestocopy = readdir( DIR );
closedir( DIR );
# Remove names that start with a . from the list. This includes . and ..,
# but may also include hidden files put in place by the IDE during 
# development.
@filestocopy = grep( !/^\./, @filestocopy );
# Now check which files need to be copied again and do the copy.
# We don't copy more than needed.
foreach my $file (@filestocopy) {
	my $sourcefile = "$codedir/WEB/$file";
	my $targetfile = "$webdir/$file";
	if ( ( ! (-e $targetfile) ) ||   
	      ( (stat($sourcefile)->mtime) > (stat($targetfile)->mtime) ) ) { 
        copy( $sourcefile, $targetfile );
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
# Convert at timestamp from ISO 8601 Zulu time to the local format.
#
#

#sub convert_timestamp {
#    
#    use POSIX::strptime qw(strptime);
#
#    return strftime( "%c", localtime( timegm( strptime( $_[0],"%Y%m%dT%H%MZ" ) ) ) );
#    
#}

# Current Hopper master node does not have the POSIX::strptime package, so to
# avoid messing with the Perl install on the master nodes:

sub convert_timestamp {
    
    $_[0] =~ /(\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)Z/;
    return strftime( "%c", localtime( timegm( ( 0, $5+0, $4+0, $3+0, $2 - 1, $1 + 100 ) ) ) );
    
}



################################################################################
################################################################################
#
# Get the alarms and check if they are new.
#
# Return value is the alarm structure with information about new, expired
# and other active alarms.
#
# The routine uses an alarm database stored on disk. The alarm database
# contains more information than is actually needed in the current incarnation
# of the code as the error message for a given alarm is 100% predictable and thus
# doesn't need to be stored, but it offers us an easy way to generate very 
# user-readable mails. The databasse contains an array of hashes, where each
# hash contains the source, message, level, a unique key ID and a ISO 8601
# timestamp in Zulu time indicating when the alarm was raised.
#

sub get_alarms {
    
    my $devices   = $_[0];  # This is a reference!
    my $datadir   = $_[1];

    #
    # Load the alarm database from disk.
    #
    my $alarmDB_file = $datadir.'/alarms.perlStorable';
    my $old_alarmDB_ref;
    eval {
        $old_alarmDB_ref = retrieve( $alarmDB_file );
    };
    if ( $@ ) { $old_alarmDB_ref = []; }  # If reading failed, we just start with an empty array.
    
    #
    # Get the current active alarms.
    #
    my @alarmMssgs = () ; # an array, each entry is a hash with five keys: source, message, level, timestamp and a unique key ID.
    foreach my $workdevice (values %$devices ) {
        push @alarmMssgs, $workdevice->AlarmMssgs();
    }    
    
    #
    # Process the alarms: compare with the database.
    #
    my %alarmList = ( 
        critical_new     => [ ], 
        critical_active  => [ ],
        critical_expired => [ ],
        soft_new         => [ ], 
        soft_active      => [ ],
        soft_expired     => [ ]
        );
    
    # Run through the alarms fetched from disk and put them in either the active or expired
    # category depending on whether they are still active in the new list.
    foreach my $alarm (@{$old_alarmDB_ref}) { 
        my @alarmOccurs = grep { $_->{ID} eq $alarm->{ID} } @alarmMssgs;
        if ( @alarmOccurs ) { # The alarm is still active.
            if ( $alarm->{level} eq 'CriticalAlarm' ) {
                push @{$alarmList{critical_active}}, $alarm;
            } else {
                push @{$alarmList{soft_active}}, $alarm;
            }
        } else { # Couldn't find the alarm in the new list, so the alarm has expired.
            if ( $alarm->{level} eq 'CriticalAlarm' ) {
                push @{$alarmList{critical_expired}}, $alarm;
            } else {
                push @{$alarmList{soft_expired}}, $alarm;
            }
        }
    }
    
    
    # Run through the list of new alarms and check if it is on the active list already.
    # If not, it is a new alarm that should be added to the list of recent alarms.
    foreach my $alarm (@alarmMssgs) {
        my @alarmOccurs = grep { $_->{ID} eq $alarm->{ID} } @{$old_alarmDB_ref};
        unless ( @alarmOccurs ) { 
            if ( $alarm->{level} eq 'CriticalAlarm' ) {
                push @{$alarmList{critical_new}}, $alarm;
            } else {
                push @{$alarmList{soft_new}}, $alarm;
            }
        }
    }
    
    #
    # Build and store the new database structure.
    #
    my @new_alarmDB = ();
    foreach my $alarm (@{$alarmList{critical_new}}, @{$alarmList{soft_new}}, 
                       @{$alarmList{critical_active}}, @{$alarmList{soft_active}}) { push @new_alarmDB, $alarm };
    
    store \@new_alarmDB, $alarmDB_file;
    
    #
    # Finish and return.
    #

    return ( \@alarmMssgs, \%alarmList );
    
}  # End of get_alarms


################################################################################
################################################################################
#
# Generate mail messages if there are any new or expired critical alarms.
#
#

sub send_mail {

    my $alarmListRef = shift;
    my $mailto       = shift;

    my $subject;
    my @message = ( );

    if ( @{$alarmListRef->{critical_new}} ) {

        $subject = 'COOLING: New critical alarms!';
        
        # Add new alarms to the mail.
        push @message, 'The following new critical alarms have been raised (at about ' . 
                       convert_timestamp( $alarmListRef->{critical_new}[0]{timestamp} ) . '):';
        foreach my $alarm (@{$alarmListRef->{critical_new}}) {
            push @message, '* '. $alarm->{source} . ': '. $alarm->{message};
        }

        # Add active alarms to the mail (if any).
        push @message, '';
        if ( @{$alarmListRef->{critical_active}} ) {
            push @message, 'The following critical alarms are still active:';
            foreach my $alarm (@{$alarmListRef->{critical_active}}) {
                push @message, '* '. $alarm->{source} . ': '. $alarm->{message} .
                               ' (since ' . convert_timestamp( $alarm->{timestamp} ) . ')';
            }
        } else { push @message, 'There are no other active critical alarms.' }

        # Add expired alarms to the mail (if any).
        push @message, '';
        if ( @{$alarmListRef->{critical_expired}} ) {
            push @message, 'The following critical alarms have been reset:';
            foreach my $alarm (@{$alarmListRef->{critical_expired}}) {
                push @message, '* '. $alarm->{source} . ': '. $alarm->{message} .
                               ' (raised on ' . convert_timestamp( $alarm->{timestamp} ) . ')';
            }       
        } else { push @message, 'No alarms have been reset recently.' }

    } elsif ( @{$alarmListRef->{critical_expired}} ) {

        if ( @{$alarmListRef->{critical_active}} ) {
            $subject = 'COOLING: Some critical alarms cleared, other remain active';
        } else {
            $subject = 'COOLING: Alarms cleared';
        }

        # Add the messages that have been reset.
        push @message, 'The following critical alarms have been reset:';
        foreach my $alarm (@{$alarmListRef->{critical_expired}}) {
            push @message, '* '. $alarm->{source} . ': '. $alarm->{message} .
                           ' (raised on ' . convert_timestamp( $alarm->{timestamp} ) . ')';
        }       

        # We now there are no new ones as that case has been treated before. 
        # There may however be more active alarms.
        # Add active alarms to the mail (if any).
        push @message, '';
        if ( @{$alarmListRef->{critical_active}} ) {
            push @message, 'The following critical alarms reamin active however:';
            foreach my $alarm (@{$alarmListRef->{critical_active}}) {
                push @message, '* '. $alarm->{source} . ': '. $alarm->{message} .
                               ' (since ' . convert_timestamp( $alarm->{timestamp} ) . ')';
            }       
        } else { push @message, 'There are no remaining active critical alarms.' }

    }

    # Do we have anything to send? If so, send message.
    # Test mailx with: echo 'Test!' | mailx -s "Testmail" k.w.a.lust@gmail.com

    if ( @message ) {
        my $mailcommand = join( ' ', ( '|', $mailx, '-s', "'$subject'", $mailto ) );
        #print "Sending message \":\n". join( "\n", @message ) . "\n\" using the command \"" . $mailcommand . "\"\n";  
        my $pipe = IO::File->new( $mailcommand ) or die "Could not open create a pipe for sending mail";
        $pipe->print( join( "\n", @message ) );
        $pipe->close;
    }

}


################################################################################
################################################################################
#
# Generate the raw data page.
#
#

sub generate_rawdata {
    
    my $devices       = $_[0];  # This is a reference!
    my $webdir        = $_[1];
    my $alarmMssgsRef = $_[2];  # This contains a reference to the list with alarm messages!
    
    #
    # First build the alarm strings.
    #
    
    # Also create a hash with the number corresponding to each device label for sorting.
    my %deviceOrder = ( );
    while ( ($key, $device) = each %$devices ) {
        $deviceOrder{$device->{'label'}} = $key;
    } 
       
    # Sort the message first according to how critical they are, then according to the device order.
    # We use the fact that 'CriticalAlarm' lt 'SoftAlarm'
    @alarmMssgs = sort { (($res = ($a->{level} cmp $b->{level})) == 0) ? ($deviceOrder{$a->{source}} <=> $deviceOrder{$b->{source}}) : $res } @{$alarmMssgsRef};
    
    #
    # Now we can build the raw data "web" page.
    #
    
    my @outputpage = ( );
    
    # Add the time stamp
    push @outputpage, "<div id=\"RD_time2L\">$timestampL<br>$timestampZ</div>\n";
    push @outputpage, "<div id=\"RD_time1L\">$timestampL ($timestampZ)</div>\n";
    
    # Add the alarm strings.
    push @outputpage, "<div id=\"RD_alarms\">\n";
    for my $c1 (0 .. $#alarmMssgs) {
        push @outputpage, "  <span class=ConsoleMssg$alarmMssgs[$c1]{'level'}>$alarmMssgs[$c1]{source}: $alarmMssgs[$c1]{message} (since " .
                          convert_timestamp( $alarmMssgs[$c1]{timestamp} ) . ")</span>" . 
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
            $style = '';
            if ( $device->{'valid'} ) {
                ($value, $status, $valtext, $remark) = $device->DVar( $mykey ); # In fact, we don't need $remark here...
                ! length( $valtext ) || ( $value = join( '', $value, ' - ', $valtext ) ); # Add textual value
                if    ( $status eq "CriticalAlarm" ) { $style = ' style="color: var(--CriticalAlarm-color)"'; }
                elsif ( $status eq "SoftAlarm" )     { $style = ' style="color: var(--SoftAlarm-color)"'; }
            } else { $value = '/'; }
            push @outputpage, "    <div id=\"$label\"$style>$value</div>\n";
        }    
        push @outputpage, "  </div>\n";
        
        # Do the analog variables
        push @outputpage, "  <div>Analog variables\n";
        foreach my $mykey ( sort {$a <=> $b} keys %{ $device->{'description'}{'analog'} } ) { 
            $label = "RD\_D$devkey\_A$mykey";
            $style = '';
            if ( $device->{'valid'} ) {
                ($value, $status, $units, $remark) = $device->AVar( $mykey ); # In fact, we don't need $units and $remark here...
                if    ( $status eq "CriticalAlarm" ) { $style = ' style="color: var(--CriticalAlarm-color)"'; }
                elsif ( $status eq "SoftAlarm" )     { $style = ' style="color: var(--SoftAlarm-color)"'; }
            } else { $value = '/'; }
            push @outputpage, "    <div id=\"$label\"$style>$value</div>\n";
        }    
        push @outputpage, "  </div>\n";
        
        # Do the integer variables
        push @outputpage, "  <div>Integer variables\n";
        foreach my $mykey ( sort {$a <=> $b} keys %{ $device->{'description'}{'integer'} } ) { 
            $label = "RD\_D$devkey\_I$mykey";
            $style = '';
            if ( $device->{'valid'} ) {
                ($value, $status, $units, $remark) = $device->IVar( $mykey ); # In fact, we don't need $units and $remark here...
                if    ( $status eq "CriticalAlarm" ) { $style = ' style="color: var(--CriticalAlarm-color)"'; }
                elsif ( $status eq "SoftAlarm" )     { $style = ' style="color: var(--SoftAlarm-color)"'; }
            } else { $value = '/'; }
            push @outputpage, "    <div id=\"$label\"$style>$value</div>\n";
        }    
        push @outputpage, " </div>\n";
        
        # Do the computed variables
        push @outputpage, "  <div>Computed variables\n";
        foreach my $mykey ( sort {$a <=> $b} keys %{ $device->{'description'}{'computed'} } ) { 
            $label = "RD\_D$devkey\_C$mykey";
            $style = '';
            if ( $device->{'valid'} ) {
                ($value, $status, $type, $units, $remark) = $device->CVar( $mykey ); # In fact, we don't need $type, $units and $remark here...
                if    ( $status eq "CriticalAlarm" ) { $style = ' style="color: var(--CriticalAlarm-color)"'; }
                elsif ( $status eq "SoftAlarm" )     { $style = ' style="color: var(--SoftAlarm-color)"'; }
            } else { $value = '/'; }
            push @outputpage, "    <div id=\"$label\"$style>$value</div>\n";
        }    
        push @outputpage, " </div>\n";
        
        # Set the expiration time
        $timestampExp = strftime( "%Y-%m-%dT%H:%M:%SZ", 
                                  gmtime( time() + $dataValid ) );     # Time stamp in Zulu time in the format for JS date.Parse
        push @outputpage, "  <div id=\"RD_Expiration\">$timestampExp</div>\n";
        
        push @outputpage, "</div>\n"; 
    
    }  # End of while loop over all devices.
    
    #push @outputpage, "</body>\n</html>\n";
    
    open( my $webpageFH, ">", "$webdir/rawdata.html" );
    print $webpageFH @outputpage;
    close( $webpageFH );
    
} # end of generate_rawdata


################################################################################
################################################################################
#
# Rebuild index.html.
#
#

sub generate_monitor_root {
    
    my $devices = shift;  # This is a reference! 
    my $links   = shift;  # This is a reference! 
    my $codedir = shift;
    my $webdir  = shift;
    
    #print "Regenerating the index.html file.\n";

    my @outputpage = () ;
    
    open( my $webtemplate, "<", "$codedir/TEMPLATES/monitor_template.html" ) 
      or die "Could not open the web template file $codedir/monitor_template.html";
    
    while ($line = <$webtemplate>) {
        # We allow for multiple commands on a single line. This increases the overhead 
        # here but offers more flexibility for the template file we start from.
        # We do assume though that there is only a single %timestamp% or
        # %AlarmMssgs%

        while ( $line =~ /(.*)\%avar\((\d+),(\d+)\)\%(.*)/s ) {
            # Split of the %avar(...,...)% that will be processed now.
            $pre    = $1;
            # $devnum = $2;   # Commented out to reduce data copying as the values remain valid until they are used anyway.
            # $varnum = $3;
            $post   = $4;
            $body = "<span class=\"dataItem\" id=\"D$2\_A$3\"></span>";
            ($value, $status, $units, $remark) = $devices->{$2}->AVar( $3 );    # $value is not needed here.
            #if ( $units ne '') { $body = $body.'&nbsp;'.$units; }
            ! length( $units ) || ( $body = $body.'&nbsp;'.$units ); # Trick from a Perl book, should be more efficient than the above if.
            if ( $remark ne '' ) {
                $pre =~ s/\"data\"/\"data dataRemark\"/g;
                $body = join( '', $body, '<div class="dataRemark"><span class="dataRemark">', $remark, '</span></div>' );
            }
            # Rebuild $line, but replace the %avar% command.
            $line = $pre.$body.$post;        	
        } # End processing %avar%

        while ( $line =~ /(.*)\%ivar\((\d+),(\d+)\)\%(.*)/s ) {
            $pre    = $1;
            # $devnum = $2;
            # $varnum = $3;
            $post   = $4;
            $body = "<span class=\"dataItem\" id=\"D$2\_I$3\"></span>";
            ($value, $status, $units, $remark) = $devices->{$2}->IVar( $3 );    # $value is not needed here.
            #if ( $units ne '') { $body = $body.'&nbsp;'.$units; }
            ! length( $units ) || ( $body = $body.'&nbsp;'.$units );
            if ( $remark ne '' ) {
                $pre =~ s/\"data\"/\"data dataRemark\"/g;
                $body = join( '', $body, '<div class="dataRemark"><span class="dataRemark">', $remark, '</span></div>' );
            }
            $line = $pre.$body.$post;
        } # End while loop processing %ivar%
        
        while ( $line =~ /(.*)\%dvar\((\d+),(\d+)\)\%(.*)/s ) {
            $pre    = $1;
            # $devnum = $2;
            # $varnum = $3;
            $post   = $4;
            $body = "<span class=\"dataItem\" id=\"D$2\_D$3\"></span>";
            ($value, $status, $valtext, $remark) = $devices->{$2}->DVar( $3 );   # $value and $valtext are not needed here.
            if ( $remark ne '' ) {
                $pre =~ s/\"data\"/\"data dataRemark\"/g;
                $body = $body.'<div class="dataRemark"><span class="dataRemark">'.$remark.'</span></div>';
            }
            #$line =~ s/(.*)\%dvar\(\d+,\d+\)\%(.*)/$1$replace$2/;
            $line = $pre.$body.$post;
        } # End while loop processing the dvar commands.
        
        while ( $line =~ /(.*)\%cvar\((\d+),(\d+)\)\%(.*)/s ) {
            $pre    = $1;
            # $devnum = $2;
            # $varnum = $3;
            $post   = $4;
            $body = "<span class=\"dataItem\" id=\"D$2\_C$3\"></span>";
            ($value, $status, $type, $units, $remark) = $devices->{$2}->CVar( $3 );   # $value and $type are not needed here.
            #if ( $units ne '') { $body = $body.'&nbsp;'.$units; }
            ! length( $units ) || ( $body = $body.'&nbsp;'.$units );
            if ( $remark ne '' ) {
                $pre =~ s/\"data\"/\"data dataRemark\"/g;
                $body = $body.'<div class="dataRemark"><span class="dataRemark">'.$remark.'</span></div>';
            }
            #$line =~ s/(.*)\%cvar\(\d+,\d+\)\%(.*)/$1$replace$2/;
            $line = $pre.$body.$post;
        } # End while-lopp processing the %cvar% commands
        
        while ( $line =~ /^( *)(.*)\%status\((\d+)\)\%(.*)/s ) {
            # We assume 4 possible values for status: Normal, Non-Critical, Critical and Off.
            $spaces = $1;
            $pre    = $2;
            $devnum = $3;
            $post   = $4;
            $status = "<span class=\"statusItem\" id=\"D$devnum\_SV\"></span>";
            $replace = "$spaces  <button class=\"StatusButtonNormal\"  onclick=\"parent.location='$devices->{$devnum}->{'label'}-details.html'\">$status<\/button><br/>\n".
                       "$spaces  <img src=\"48px-line_chart_icon.png\" onclick=\"parent.location='$links->{$devnum}'\">&nbsp;&nbsp;\n" . 
                       "$spaces  <img src=\"48px-table_icon.png\"      onclick=\"parent.location='$devices->{$devnum}->{'label'}-details.html'\">\n";
            $line = $spaces.$pre."\n".$replace.$spaces.$post;
        } # End while-loop processing the %status% command 
        
        if ( $line =~ /(.*)\%timestamp\%(.*)/s ) {
            push @outputpage, $1.'<span class="dataItem" id="time2L"></span>'.$2;
        } elsif ( $line =~ /.*\%AlarmMssgs\%.*/s ) {
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

sub generate_detail_page {
    
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
            @Dkeys = sort { $a <=> $b } ( keys %{$device->{'description'}{'digital'}} );
            @Akeys = sort { $a <=> $b } ( keys %{$device->{'description'}{'analog'}} );
            @Ikeys = sort { $a <=> $b } ( keys %{$device->{'description'}{'integer'}} );
            @Ckeys = sort { $a <=> $b } ( keys %{$device->{'description'}{'computed'}} );
            # + Determine the largest of the number of keys of the three variable types.
            $max = ( $#Dkeys > $#Akeys ) ? $#Dkeys : $#Akeys;
            $max = ( $max > $#Ikeys )    ? $max    : $#Ikeys;
            $max = ( $max > $#Ckeys )    ? $max    : $#Ckeys;
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
                    ($value, $status, $valtext, $remark) = $device->DVar( $key );         # $value and $valtext are not needed here.
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
                    ($value, $status, $units, $remark) = $device->AVar( $key );            # $value is not needed here.
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
                    ($value, $status, $units, $remark) = $device->IVar( $key );            # $value is not needed here.
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
                # ++ Computed variable (if there is one)
                if ( $c <= $#Ckeys ) {
                    $workline = $withdata;
                    $key = $Ckeys[$c];
                    $label = $device->{'description'}{'computed'}{$key}{'info'};
                    $body = "<span class=\"dataItem\" id=\"D$devkey\_C$key\"></span>";
                    ($value, $status, $type, $units, $remark) = $device->CVar( $key );            # $value is not needed here.
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

