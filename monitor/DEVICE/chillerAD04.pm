package DEVICE::chillerAD04;

use parent 'DEVICE::generic';

use IO::File;
use Net::SNMP;
use POSIX qw(strftime);
use Try::Tiny;

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
  'integer' => { },
  'computed' => { } 
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
      'valid'       => 1,             # This object contains valid data.
      'digital'     => { },
      'analog'      => { },
      'integer'     => { }
      };

	try {
	
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
    	        or die "SNMP service $oid is not available on the SNMP server $webgateIP:$webgate_device.\n";
            $self->{'digital'}{$mykey} = $result->{$oid};    	
        	# print ( "Digital key ", $mykey, " has value ", $self->{'digital'}{$mykey}, "\n" );
        }
    
        foreach my $mykey ( sort keys %{ $description->{'analog'} } ) { 
        	my $oid = $OIDbase.$webgate_device.".".$OIDanalog.$mykey.".0";
    	    my $result = $session->get_request( $oid )
    	        or die "SNMP service $oid is not available on the SNMP server $webgateIP:$webgate_device.\n"; 
            $self->{'analog'}{$mykey} = $result->{$oid} / 10.;       
        	# print ( "Analog key ", $mykey, " has value ", $self->{'analog'}{$mykey}, "\n" );
        }
        
        foreach my $mykey ( sort keys %{ $description->{'integer'} } ) { 
        	my $oid = $OIDbase.$webgate_device.".".$OIDinteger.$mykey.".0";
    	    my $result = $session->get_request( $oid )
    	        or die "SNMP service $oid is not available on the SNMP server $webgateIP:$webgate_device.\n";
            $self->{'integer'}{$mykey} = $result->{$oid};       
        	# print ( "Integer key ", $mykey, " has value ", $self->{'integer'}{$mykey}, "\n" );
        }
        
        # Close the connection
        $session->close;

	} catch {
		warn "Failed to read device data: $_";
		$self->{'valid'} = 0;  # Something went wrong, the data is incomplete.
	};

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


sub Status
{
	
	my $self = $_[0];
	
	my $status = "";
	
	if ( ! $self->{'valid'} ) {
		$status = "Offline";
	} elsif ( $self->{'digital'}->{23} || $self->{'digital'}->{24} || $self->{'digital'}->{54} ) { 
		$status = "Critical"; 
	} else { $status = "Normal" }
	
	return $status;
	
}


sub ObjDef
{
	
	return __FILE__;
	
}

#
# End of the package definition.
#
1; # Required to make sure the use or require commands succeed.

