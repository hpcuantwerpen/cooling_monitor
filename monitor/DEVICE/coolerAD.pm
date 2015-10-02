package coolerAD;

use IO::File;
use Net::SNMP;
use POSIX qw(strftime);

#use Data::Dumper qw(Dumper);

# $description is a reference to an anonymous hash table...
$description = {
  'digital' => { 
    31 => { info =>  'fan trip ',                type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
    57 => { info =>  'high return temperature ', type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
    58 => { info =>  'low return temperature ',  type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
    59 => { info =>  'high supply temperature ', type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
    60 => { info =>  'low supply temperature ',  type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' }
    } ,
  'analog' => {
     2 => { info => 'evaporator fan speed ',        unit => '%',   remark => '' },
    33 => { info => 'inlet water temperature ',     unit => 'ºC',  remark => '' },
    34 => { info => 'return air humidity ',         unit => '%RH', remark => '' },
    35 => { info => 'return air temperature ',      unit => 'ºC',  remark => '' },
    36 => { info => 'supply air temperature ',      unit => 'ºC',  remark => '' },
    39 => { info => 'aisle differential pressure ', unit => 'Pa',  remark => '' },
    44 => { info => 'CW valve position ',           unit => '%',   remark => '' },
    48 => { info => 'Temperature set point',        unit => 'ºC',  remark => '' }
    },
  'integer' => { } 
  };

$OIDbase = "1.3.6.1.4.1.9839.2.1.";
$OIDdigital = "1.";
$OIDanalog  = "2.";
$OIDinteger = "3.";
$FS = "\t";  # Field separator for the log file output.


#
# Constructor.
# - The first argument is the class, chillerAD04, or the object
# - The second argument is either 1 or 2, for chiller01 and chiller02.
#
sub New
{

    my $proto = shift;
    my $class = ref($proto) || $proto;

	my $cooler_ip = $_[0];
	my $label     = $_[1];

    my $self = {
      'ip'          => $cooler_ip, 
      'label'       => $label,
      'description' => $description,
      'digital'     => { },
      'analog'      => { },
      'integer'     => { }
      };

	# Open the SNMP-session
	my ($session, $error) = Net::SNMP->session(
             -hostname  => $cooler_ip,
             -community => 'public',
             -port      => 161,
             -timeout   => 1,
             -retries   => 3,
			 -debug		=> 0x0,
			 -version	=> 2,
             -translate => [-timeticks => 0x0] 
	         );

    # Read the keys, first the digital ones then the analog ones.
    foreach my $mykey ( sort keys %{ $description->{'digital'} } ) 
    { 
	    my $oid = $OIDbase.$OIDdigital.$mykey.".0";
	    my $result = $session->get_request( $oid )
	        or die ("SNMP service $oid is not available on this SNMP server.");
	    $self->{'digital'}{$mykey} = $result->{$oid};
    	# print ( "Digital key ", $mykey, " has value ", $self->{'digital'}{$mykey}, "\n" );
    }

    foreach my $mykey ( sort keys %{ $description->{'analog'} } ) 
    { 
    	my $oid = $OIDbase.$OIDanalog.$mykey.".0";
	    my $result = $session->get_request( $oid ) 
	        or die ("SNMP service $oid is not available on this SNMP server.");
	    $self->{'analog'}{$mykey} = $result->{$oid} / 10.;
    	# print ( "Analog key ", $mykey, " has value ", $self->{'analog'}{$mykey}, "\n" );
    }

    foreach my $mykey ( sort keys %{ $description->{'integer'} } ) 
    { 
    	my $oid = $OIDbase.$OIDinteger.$mykey.".0";
	    my $result = $session->get_request( $oid ) 
	        or die ("SNMP service $oid is not available on this SNMP server.");
	    $self->{'integer'}{$mykey} = $result->{$oid};
    	# print ( "Integer key ", $mykey, " has value ", $self->{'integer'}{$mykey}, "\n" );
    }

    # Close the connection
    $session->close;

    # Add the timestamp field
    $self->{'timestamp'} = strftime( "%Y%m%dT%H%MZ", gmtime );

    # Finalise the object creation
    bless( $self, $class );
    return $self
	
}


#
# Log the data to the common chiller log format.
# 2 arguments:
# - The chillerAD04 object
# - The file name of the log file
sub Log
{
	my $self = $_[0];
	my $filename  = $_[1];

	# Order: Time stamp, Return Air Temperature, Return Air Humidity, Supply Air Temperature,
	# Aisle Differential Pressure, Inlet Water Temperature, Evaporator Fan Speed (%), CW Valve Position (%),
	# Fan Trip alarm, High Return Temperature alarm, Low Return Temperature alarm,
	# High Supply Temperature alarm, Low Supply Temperature alarm.
	my @logdata = (
	  $self->{'timestamp'},
	  $self->{'analog'}{35}, 
	  $self->{'analog'}{34}, 
	  $self->{'analog'}{36}, 
	  $self->{'analog'}{48}, 
	  $self->{'analog'}{39}, 
	  $self->{'analog'}{33}, 
	  $self->{'analog'}{2}, 
	  $self->{'analog'}{44}, 
	  $self->{'digital'}{31}, 
	  $self->{'digital'}{57}, 
	  $self->{'digital'}{58}, 
	  $self->{'digital'}{59}, 
	  $self->{'digital'}{60}
	  );

	my $fh = IO::File->new( $filename, '>>' ) or die "Could not open file '$filename'";
	$fh->print( join($FS, @logdata), "\n" );
	$fh->close;
	
}


#
# Create a log of all available variables for future reference.
# The file name is the label-YYMM.log in the directory indicated by the second argument.
# If the file does not exist, we first write a line with the description of each column
# derived from the SNMP OIDs.
# Otherwise we just add a new record.
#
sub FullLog {
	
	my $self   = $_[0];
	my $logdir = $_[1];
	
	my $filestamp = substr( $self->{'timestamp'}, 0, 4 );  # YYMM-part of the time stamp.
	my $logfilename = "$logdir/$self->{'label'}-$filestamp.log";

    my @labelline = ();
    
    if ( ! (-e $logfilename) ) {
    	# Log file does not yet exist, build the line with labels.
    	push @labelline, "\"timestamp\"";
    	
    	foreach my $mykey ( sort {$a<=>$b} keys %{ $description->{'digital'} } ) { 
    		push @labelline, "\"$OIDdigital$mykey\"";
        }

        foreach my $mykey ( sort {$a<=>$b} keys %{ $description->{'analog'} } ) { 
    		push @labelline, "\"$OIDanalog$mykey\"";
        }    	

        foreach my $mykey ( sort {$a<=>$b} keys %{ $description->{'integer'} } ) { 
    		push @labelline, "\"$OIDinteger$mykey\"";
        }    	

    }	
	
	# Now prepare the data record.
	my @dataline = ( $self->{'timestamp'} );
	foreach my $mykey ( sort {$a<=>$b} keys %{ $description->{'digital'} } ) { 
        push @dataline, $self->{'digital'}{$mykey};
    }
	foreach my $mykey ( sort {$a<=>$b} keys %{ $description->{'analog'} } ) { 
        push @dataline, $self->{'analog'}{$mykey};
    }
	foreach my $mykey ( sort {$a<=>$b} keys %{ $description->{'integer'} } ) { 
        push @dataline, $self->{'integer'}{$mykey};
    }

    my $fh = IO::File->new( $logfilename, '>>' ) or die "Could not open file '$logfilename'";
    if ( $#labelline > 0 ) { $fh->print( join($FS, @labelline), "\n" ); }
    $fh->print( join($FS, @dataline), "\n" );
    $fh->close;
	
}



sub Status
{
	
	my $self = $_[0];
	
	my $status = "";
	
	if    ( $self->{'digital'}->{31} || 
	        $self->{'digital'}->{57} || 
	        $self->{'digital'}->{58} || 
	        $self->{'digital'}->{59} || 
	        $self->{'digital'}->{60} ) { 
		$status = "Critical"; 
	} else { $status = "Normal" }
	
	return $status;
	
}


sub AVar
{
	
	my $self = $_[0];
	my $var  = $_[1];
	
	return ( $self->{'analog'}{$var}, 
	         $self->{'description'}{'analog'}{$var}{'unit'}, 
	         $self->{'description'}{'analog'}{$var}{'remark'} );
	
}


sub DVar
{
	
	my $self = $_[0];
	my $var  = $_[1];
	
	my $value = $self->{'digital'}{$var};
	
	return ( $value, 
	         $self->{'description'}{'digital'}{$var}{'value'}[$value], 
	         $self->{'description'}{'digital'}{$var}{'remark'} );
	
}


sub AlarmMssgs
{
	my $self = $_[0];
	
	my @alarmlist = ();
	
	foreach my $key (sort keys %{$self->{'digital'}} ) {
		if ( $self->{'description'}{'digital'}{$key}{'type'} eq "SoftAlarm" ) {
			if ( $self->{'digital'}{$key} != 0 ) {
				push @alarmlist, ( { source => $self->{'label'}, 
					                 message => $self->{'description'}{'digital'}{$key}{'info'}, 
					                 level => 'Non-Critical' } );
			}
		} elsif ( $self->{'description'}{'digital'}{$key}{'type'} eq "CriticalAlarm" ) {
			if ( $self->{'digital'}{$key} != 0 ) {
				push @alarmlist, ( { source => $self->{'label'}, 
					                 message => $self->{'description'}{'digital'}{$key}{'info'}, 
					                 level => 'Critical' } );
			}			
		}
	}
	
	return @alarmlist;
}


#
# End of the package definition.
#
1; # Required to make sure the use or require commands succeed.

