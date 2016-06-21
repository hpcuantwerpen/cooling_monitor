package DEVICE::ahuAD;

use parent 'DEVICE::generic';

use IO::File;
use Net::SNMP;
use POSIX qw(strftime);

#use Data::Dumper qw(Dumper);


$description = {
  'digital' => { 
     21 => { info => 'fan operating ',      type => 'NoAlarm',       value => ['No', 'Yes'],           remark => '' },
     26 => { info => 'non-critical alarm ', type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],   remark => '' },
     27 => { info => 'critical alarm ',     type => 'CriticalAlarm', value => ['No alarm', 'Alarm'],   remark => '' },
    114 => { info => 'AHU enabled ',        type => 'NoAlarm',       value => ['Disabled', 'Enabled'], remark => '' }
    } ,
  'analog' => {
      1 => { info => 'air return humidity ',    unit => '%RH', remark => '' },
      4 => { info => 'air return temperature ', unit => 'ºC',  remark => '' },
      5 => { info => 'air supply temperature ', unit => 'ºC',  remark => '' },
     12 => { info => 'Temperature set point ',  unit => 'ºC',  remark => '' },
     35 => { info => 'cooling 0-10vdc ',        unit => '',    remark => 'Unknown units' }
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
# 0: the class, ahuAD, or the object (hidden argument)
# 1: IP number of the WebGATE device
# 2: Device number of the device to monitor. 1 for ahu01, 2 for ahu02 etc.
# 3: Label of the device to monitor, used, e.g., in alarm strings.
#
sub New
{

    my $proto = shift;
    my $class = ref($proto) || $proto;

	my $webgateIP      = $_[0];
	my $webgate_device = $_[1];  # 1 = ahu01, 2 = ahu02, ....
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
	    $self->{'integer'}{$mykey} = $result->{$oid} / 10.;
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
# Log file: Time stamp, return temperaturat, return humidity, supply temperature,
# fan operating, non-critical alrm, critical alarm.
sub Log
{
	my $self      = $_[0];
	my $filename  = $_[1];
	
	my @logdata = (
	  $self->{'timestamp'},
	  $self->{'analog'}{4}, 
	  $self->{'analog'}{1}, 
	  $self->{'analog'}{5}, 
      $self->{'analog'}{12}, 
      $self->{'analog'}{35}, 
	  $self->{'digital'}{21}, 
	  $self->{'digital'}{26}, 
	  $self->{'digital'}{27}
	  );

    # print( "To $filename: ", join(",", @logdata), "\n" ) ;
	my $fh = IO::File->new( $filename, '>>' ) or die "Could not open file '$filename'";
	$fh->print( join($FS, @logdata), "\n" );
	$fh->close;
	
}


sub Status
{
	
	my $self = $_[0];
	
	my $status = "";
	
	if    ( $self->{'digital'}->{27} != 0  ) { $status = "Critical"; }
	elsif ( $self->{'digital'}->{26} != 0  ) { $status = "Non-Critical"; }
	else                                     { $status = "Normal" };
	
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

