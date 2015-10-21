package DEVICE::chillerAD04;

use IO::File;
use Net::SNMP;
use POSIX qw(strftime);

#use Data::Dumper qw(Dumper);


$description = {
  'digital' => { 
    15 => { info =>  'compressor 1 on/off ', type => 'NoAlarm',       value => ['Off', 'On'],           remark => '' },
    16 => { info =>  'compressor 2 on/off ', type => 'NoAlarm',       value => ['Off', 'On'],           remark => '' },
    17 => { info =>  'compressor 3 on/off ', type => 'NoAlarm',       value => ['Off', 'On'],           remark => '' },
    18 => { info =>  'compressor 4 on/off ', type => 'NoAlarm',       value => ['Off', 'On'],           remark => '' },
    21 => { info =>  'pump 1 on/off ',       type => 'NoAlarm',       value => ['Off', 'On'],           remark => '' },
    22 => { info =>  'pump 2 on/off ',       type => 'NoAlarm',       value => ['Off', 'On'],           remark => '' },
    23 => { info =>  'circuit 1 alarm ',     type => 'CriticalAlarm', value => ['No alarm', 'Alarm'],   remark => '' },
    24 => { info =>  'circuit 2 alarm ',     type => 'CriticalAlarm', value => ['No alarm', 'Alarm'],   remark => '' },
    28 => { info =>  'chiller disabled',     type => 'NoAlarm',       value => ['Enabled', 'Disabled'], remark => '' },   # Not sure that we read the correct value.
    54 => { info =>  'flow alarm ',          type => 'CriticalAlarm', value => ['No alarm', 'Alarm'],   remark => '' }
    } ,
  'analog' => {
      1 => { info => 'circuit 1 liquid pressure ',        unit => 'bar', remark => 'Winter: ~11, summer ~18' },
      2 => { info => 'circuit 2 liquid pressure ',        unit => 'bar', remark => 'Winter: ~11, summer ~18' },
      4 => { info => 'chiller return water temperature ', unit => 'ºC',  remark => '' },
      5 => { info => 'chiller supply water temperature ', unit => 'ºC',  remark => '' },
     11 => { info => 'eev1 suction pressure circuit 1 ',  unit => 'bar', remark => '' },
     12 => { info => 'eev2 suction pressure circuit 2 ',  unit => 'bar', remark => '' },
     13 => { info => 'Temperature set point ',            unit => 'ºC',  remark => '' },
     17 => { info => 'chiller outside ambient ',          unit => 'ºC',  remark => '' },
    122 => { info => 'water flow ',                       unit => 'l/s', remark => '' }
    },
  'integer' => { } 
  };

$OIDdigital = "1.";
$OIDanalog  = "2.";
$OIDinteger = "3.";
$OIDbase    = "1.3.6.1.4.1.9839.2.";
$FS = "\t";  # Field separator for the log file output.


#
# Constructor.
# Arguments:
# 0: the class, chillerAD04, or the object (hidden argument)
# 1: IP number of the WebGATE device
# 2: Device number of the device to monitor. 6 for chiller01, 7 for chiller02, 8 for chiller03
# 3: Label of the device to monitor, used, e.g., in alarm strings.
#
sub New
{

    my $proto = shift;
    my $class = ref($proto) || $proto;

	my $webgateIP      = $_[0];
	my $webgate_device = $_[1];  # 6 = chiller01, 7 = chiller02, 8 = chiller03.
	my $label          = $_[2];
	
    my $self = {
      'offset'      => $webgate_device, 
      'IP'          => $webgateIP,
      'label'       => $label,
      'description' => $description,
      'digital'     => { },
      'analog'      => { },
      'integer'     => { }
      };

	# Open the SNMP-session
	my ($session, $error) = Net::SNMP->session(
             -hostname  => $webgateIP,
             -community => 'public',
             -port      => 161,
             -timeout   => 1,
             -retries   => 3,
			 -debug		=> 0x0,
			 -version	=> 2,
             -translate => [-timeticks => 0x0] 
	         );

    # Read the keys, first the digital ones then the analog ones.
    foreach my $mykey ( sort keys %{ $description->{'digital'} } ) { 
	    my $oid = $OIDbase.$webgate_device.".".$OIDdigital.$mykey.".0";
	    my $result = $session->get_request( $oid )
	        or die ("SNMP service $oid is not available on this SNMP server.");
	    $self->{'digital'}{$mykey} = $result->{$oid};
    	# print ( "Digital key ", $mykey, " has value ", $self->{'digital'}{$mykey}, "\n" );
    }

    foreach my $mykey ( sort keys %{ $description->{'analog'} } ) { 
    	my $oid = $OIDbase.$webgate_device.".".$OIDanalog.$mykey.".0";
	    my $result = $session->get_request( $oid ) 
	        or die ("SNMP service $oid is not available on this SNMP server.");
	    $self->{'analog'}{$mykey} = $result->{$oid} / 10.;
    	# print ( "Analog key ", $mykey, " has value ", $self->{'analog'}{$mykey}, "\n" );
    }
    
    foreach my $mykey ( sort keys %{ $description->{'integer'} } ) { 
    	my $oid = $OIDbase.$webgate_device.".".$OIDinteger.$mykey.".0";
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
    return $self;
	
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
	
	my @logdata = (
	  $self->{'timestamp'},
	  $self->{'analog'}{17}, 
	  $self->{'analog'}{4}, 
	  $self->{'analog'}{5}, 
	  $self->{'analog'}{13}, 
	  'NaN', 
	  $self->{'analog'}{1}, 
	  $self->{'analog'}{2}, 
	  $self->{'analog'}{11}, 
	  $self->{'analog'}{12}, 
	  'NaN', 
	  'NaN', 
	  'NaN', 
	  'NaN', 
	  'NaN', 
	  $self->{'analog'}{122}, 
	  'NaN', 
	  $self->{'digital'}{15}, 
	  $self->{'digital'}{16}, 
	  $self->{'digital'}{17}, 
	  $self->{'digital'}{18}, 
	  $self->{'digital'}{21}, 
	  $self->{'digital'}{22}, 
     0,
      $self->{'digital'}{23} || $self->{'digital'}{24} || $self->{'digital'}{54}
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
	
	my $filestamp = substr( $self->{'timestamp'}, 2, 4 );  # YYMM-part of the time stamp.
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
	
	if    ( $self->{'digital'}->{23} || $self->{'digital'}->{24} || $self->{'digital'}->{54} ) { 
		$status = "Critical"; 
	} else { $status = "Normal" }
	
	return $status;
	
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


sub AVar
{
	
	my $self = $_[0];
	my $var  = $_[1];
	
	return ( $self->{'analog'}{$var}, 
	         $self->{'description'}{'analog'}{$var}{'unit'}, 
	         $self->{'description'}{'analog'}{$var}{'remark'} );
	
}


sub IVar
{
	
	my $self = $_[0];
	my $var  = $_[1];
	
	return ( $self->{'integer'}{$var}, 
	         $self->{'description'}{'integer'}{$var}{'unit'}, 
	         $self->{'description'}{'integer'}{$var}{'remark'} );
	
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


sub ObjDef
{
	
	return __FILE__;
	
}

#
# End of the package definition.
#
1; # Required to make sure the use or require commands succeed.

