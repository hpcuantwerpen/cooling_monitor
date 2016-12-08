package DEVICE::ahuAD;

use parent 'DEVICE::generic';
use DEVICE::deviceHelpers qw(RangeCheck);

use IO::File;
use Net::SNMP;
use POSIX qw(strftime);
use Try::Tiny;

#use Data::Dumper qw(Dumper);

# Note range field analog variables: CriticalAlarm Range[0] SoftAlarm Range[1] OK Range[2] Softalarm Range[3] CriticalAlarm
$description = {
  'digital' => { 
     21 => { info => 'fan operating ',      type => 'NoAlarm',       value => ['No', 'Yes'],           remark => '' },
     26 => { info => 'non-critical alarm ', type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],   remark => '' },
     27 => { info => 'critical alarm ',     type => 'CriticalAlarm', value => ['No alarm', 'Alarm'],   remark => '' },
    114 => { info => 'AHU enabled ',        type => 'NoAlarm',       value => ['Disabled', 'Enabled'], remark => '' }
    } ,
  'analog' => {
      1 => { info => 'return air humidity ',    unit => '%RH',                              remark => '' },
      4 => { info => 'return air temperature ', unit => 'ºC',  range => [ 10, 20, 27, 29 ], remark => 'Room, controlled by set point' },
      5 => { info => 'supply air temperature ', unit => 'ºC',  range => [  5, 10, 23, 25 ], remark => '"Cold aisle"' },
     12 => { info => 'Temperature set point ',  unit => 'ºC',                               remark => '' },
     35 => { info => 'cooling 0-10vdc ',        unit => '',                                 remark => 'Proportional to water valve, 10=100%?' }
    },
  'integer' => { },
  'computed' => { 
      1 => { info => 'return air humidity (when measurable)',    type => 'D', unit => '%RH', remark => '' },
      2 => { info => 'return air temperature (when measurable)', type => 'D', unit => 'ºC',  remark => 'Room, controlled by set point' },
      3 => { info => 'supply air temperature (when measurable)', type => 'D', unit => 'ºC',  remark => '"Cold aisle"' },
    }
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
            $self->{'digital'}{$mykey}{'value'} = $result->{$oid};       
        	# print ( "Digital key ", $mykey, " has value ", $self->{'digital'}{$mykey}{'value'}, "\n" );
        }
    
        foreach my $mykey ( sort keys %{ $description->{'analog'} } ) { 
        	my $oid = $OIDbase.$webgate_device.".".$OIDanalog.$mykey.".0";
    	    my $result = $session->get_request( $oid )
                or die "SNMP service $oid is not available on the SNMP server $webgateIP:$webgate_device.\n";
            $self->{'analog'}{$mykey}{'value'} = $result->{$oid} / 10.; 
            if ( exists( $description->{'analog'}{$mykey}{'range'} ) ) { 
            	$self->{'analog'}{$mykey}{'status'} = DEVICE::deviceHelpers::RangeCheck( $self->{'analog'}{$mykey}{'value'}, $description->{'analog'}{$mykey}{'range'} ); 
            }     
        	# print ( "Analog key ", $mykey, " has value ", $self->{'analog'}{$mykey}{'value'}, "\n" );
        }
        
        foreach my $mykey ( sort keys %{ $description->{'integer'} } ) { 
        	my $oid = $OIDbase.$webgate_device.".".$OIDinteger.$mykey.".0";
    	    my $result = $session->get_request( $oid )
    	        or die "SNMP service $oid is not available on the SNMP server $webgateIP:$webgate_device.\n";
            $self->{'integer'}{$mykey}{'value'} = $result->{$oid};       
        	# print ( "Integer key ", $mykey, " has value ", $self->{'integer'}{$mykey}{'value'}, "\n" );
        }
        
        # Close the connection
        $session->close;

    } catch {
        warn "Failed to read device data: $_";
        $self->{'valid'} = 0;  # Something went wrong, the data is incomplete.
    };

    # Add the timestamp field
    $self->{'timestamp'} = strftime( "%Y%m%dT%H%MZ", gmtime );

    # Compute the computed variables
    # The idea is to not show a value if it can't be measured well because the fan
    # is not spinning.
    if ( $self->{'digital'}{21}{'value'} ) {
        $self->{'computed'}{1}{'value'}  = $self->{'analog'}{1}{'value'};
        $self->{'computed'}{2}{'value'}  = $self->{'analog'}{4}{'value'};
        $self->{'computed'}{2}{'status'} = DEVICE::deviceHelpers::RangeCheck( $self->{'computed'}{2}{'value'}, $description->{'analog'}{4}{'range'} );;
        $self->{'computed'}{3}{'value'}  = $self->{'analog'}{5}{'value'};
        $self->{'computed'}{3}{'status'} = DEVICE::deviceHelpers::RangeCheck( $self->{'computed'}{3}{'value'}, $description->{'analog'}{5}{'range'} );;
    } else {
        $self->{'computed'}{1}{'value'} = '/';
        $self->{'computed'}{2}{'value'} = '/';
        $self->{'computed'}{3}{'value'} = '/';
    }

    # Finalise the object creation
    bless( $self, $class );
    return $self;
	
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
	  $self->{'analog'}{4}{'value'}, 
	  $self->{'analog'}{1}{'value'}, 
	  $self->{'analog'}{5}{'value'}, 
      $self->{'analog'}{12}{'value'}, 
      $self->{'analog'}{35}{'value'}, 
	  $self->{'digital'}{21}{'value'}, 
	  $self->{'digital'}{26}{'value'}, 
	  $self->{'digital'}{27}{'value'}
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
	
	if    ( ! $self->{'valid'} )                      { $status = "Offline"; }
    elsif ( $self->{'digital'}->{27}{'value'} != 0  ) { $status = "Critical"; }
	elsif ( $self->{'digital'}->{26}{'value'} != 0  ) { $status = "Non-Critical"; }
	else                                              { $status = "Normal" };
	
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

