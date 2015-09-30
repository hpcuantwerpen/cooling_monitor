package chillerAD14;

use IO::File;
use Net::SNMP;
use POSIX qw(strftime);

#use Data::Dumper qw(Dumper);

# $description is a reference to an anonymous hash table...
$description = {
  'digital' => { 
     19 => { info =>  'status of remote on/off by digital input (option)',                type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     20 => { info =>  'status of 2nd temperature setpoint by digital input (option)',     type => 'NoAlarm',       value => ['1st setpoint', '2nd setpoint'],    remark => '' },
     21 => { info =>  'unit on/off by keyboard',                                          type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     22 => { info =>  'phase monitor status',                                             type => 'NoAlarm',       value => ['Disabled', 'Enabled'],             remark => '' },
     23 => { info =>  'MCCB status',                                                      type => 'NoAlarm',       value => ['Closed - Normal', 'Open - Fault'], remark => '' },
     24 => { info =>  'emergency stop status',                                            type => 'NoAlarm',       value => ['Closed - Normal', 'Open - Fault'], remark => '' },
     25 => { info =>  'evaporator flow switch status',                                    type => 'NoAlarm',       value => ['Closed - Normal', 'Open - Fault'], remark => '' },
     26 => { info =>  'pad heater status',                                                type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     27 => { info =>  'unit enabled by sequencer',                                        type => 'NoAlarm',       value => ['No', 'Yes'],                       remark => '' },
     28 => { info =>  'remote pumps on via digital output',                               type => 'NoAlarm',       value => ['No', 'Yes'],                       remark => '' },
     29 => { info =>  'pump 1 on/off',                                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     30 => { info =>  'pump 1 contactor status',                                          type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     31 => { info =>  'pump 2 on/off',                                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     32 => { info =>  'pump 2 contactor status',                                          type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     33 => { info =>  'chilled water valve on/off',                                       type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     34 => { info =>  'chilled water valve end position',                                 type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     35 => { info =>  'compressor 1 on/off',                                              type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     36 => { info =>  'compressor 1 contactor status',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     37 => { info =>  'compressor 2 on/off',                                              type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     38 => { info =>  'compressor 2 contactor status',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     39 => { info =>  'compressor 3 on/off',                                              type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     40 => { info =>  'compressor 3 contactor status',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     41 => { info =>  'compressor 4 on/off',                                              type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     42 => { info =>  'compressor 4 contactor status',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     43 => { info =>  'compressor 5 on/off',                                              type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     44 => { info =>  'compressor 5 contactor status',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     45 => { info =>  'compressor 6 on/off',                                              type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     46 => { info =>  'compressor 6 contactor status',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     47 => { info =>  'circuit 1 low pressure switch status',                             type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     48 => { info =>  'circuit 2 low pressure switch status',                             type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     49 => { info =>  'circuit 1 condenser by pass 1',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     50 => { info =>  'circuit 1 condenser by pass 2',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     51 => { info =>  'circuit 1 condenser by pass 3',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     52 => { info =>  'circuit 2 condenser by pass 1',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     53 => { info =>  'circuit 2 condenser by pass 2',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     54 => { info =>  'circuit 2 condenser by pass 3',                                    type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     55 => { info =>  'pump enabled by outdoor ambient temperature',                      type => 'NoAlarm',       value => ['No', 'Yes'],                       remark => '' },
     56 => { info =>  'sequence manager on/off',                                          type => 'NoAlarm',       value => ['Off', 'On'],                       remark => '' },
     80 => { info =>  'test variable',                                                    type => 'NoAlarm',       value => ['Comm. fail', 'Comm. established'], remark => '' },
    101 => { info =>  'manual override mode alarm, unit in manual operation',             type => 'NoAlarm',       value => ['Healthy', 'Alarm'],                remark => '' },
    102 => { info =>  'non-critical alarm',                                               type => 'SoftAlarm',     value => ['Healthy', 'Alarm'],                remark => '' },
    103 => { info =>  'critical alarm',                                                   type => 'CriticalAlarm', value => ['Healthy', 'Alarm'],                remark => '' },
    104 => { info =>  'controller real time clock failure alarm',                         type => 'SoftAlarm',     value => ['Healthy', 'Alarm'],                remark => '' },
    105 => { info =>  'PLAN network disconnection alarm (1 or more units not connected)', type => 'SoftAlarm',     value => ['Healthy', 'Alarm'],                remark => '' },
    106 => { info =>  'system maintenance hours alarm',                                   type => 'SoftAlarm',     value => ['Healthy', 'Alarm'],                remark => '' },
    107 => { info =>  'password alarm - password entered wrong 3 times',                  type => 'SoftAlarm',     value => ['Healthy', 'Alarm'],                remark => '' },
    108 => { info =>  'return water temperature probe fault alarm',                       type => 'SoftAlarm',     value => ['Healthy', 'Alarm'],                remark => '' },
    109 => { info =>  'supply water temperature probe fault alarm',                       type => 'SoftAlarm',     value => ['Healthy', 'Alarm'],                remark => '' },
    110 => { info =>  'ambient air temperature probe fault alarm',                        type => 'SoftAlarm',     value => ['Healthy', 'Alarm'],                remark => '' },
    111 => { info =>  'liquid pressure alarm',                                            type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    112 => { info =>  'circuit 2 liquid pressure alarm',                                  type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    113 => { info =>  'circuit 1 liquid pressure sensor faulty without EVD',              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    114 => { info =>  'circuit 2 liquid pressure sensor faulty without EVD',              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    115 => { info =>  'inlet water temperature probe faulty alarm',                       type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    116 => { info =>  'water differential pressure probe faulty alarm',                   type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    117 => { info =>  'condenser water temperature faulty',                               type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    118 => { info =>  'alarm: remote setpoint adjust 0- 10vdc input faulty',              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    119 => { info =>  'alarm: refrigerant leak detector faulty',                          type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    120 => { info =>  'refrigerant leak detected',                                        type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    121 => { info =>  'refrigerant leak detected, compressors disabled alarm',            type => 'CriticalAlarm', value => ['No alarm', 'Alarm'],               remark => '' },
    122 => { info =>  'MCCB status alarm, unit isolator off/tripped',                     type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    123 => { info =>  'emergency stop alarm',                                             type => 'CriticalAlarm', value => ['No alarm', 'Alarm'],               remark => '' },
    124 => { info =>  'Phase alarm',                                                      type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    125 => { info =>  'frost protection alarm',                                           type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    126 => { info =>  'high return water temperature alarm',                              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    127 => { info =>  'pump contactor status 1 alarm',                                    type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    128 => { info =>  'pump contactor status 2 alarm',                                    type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    129 => { info =>  'no evaporator flow alarm',                                         type => 'CriticalAlarm', value => ['No alarm', 'Alarm'],               remark => '' },
    130 => { info =>  'flow switch stuck (n/c) alarm',                                    type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    131 => { info =>  'evaporator differential pressure alarm',                           type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    132 => { info =>  'chilled water valve faulty alarm',                                 type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    133 => { info =>  '3 way free cooling valve alarm valve in wrong position',           type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    134 => { info =>  'serious flow alarm within 24 hours',                               type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    135 => { info =>  'compressors oil pre- heater timer disabled',                       type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    136 => { info =>  'compressor 1 contactor status alarm',                              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    137 => { info =>  'compressor 2 contactor status alarm',                              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    138 => { info =>  'compressor 3 contactor status alarm',                              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    139 => { info =>  'compressor 4 contactor status alarm',                              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    140 => { info =>  'compressor 5 contactor status alarm',                              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    141 => { info =>  'compressor 6 contactor status alarm',                              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    143 => { info =>  'circuit 1 common alarm',                                           type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    144 => { info =>  'circuit 2 common alarm',                                           type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    145 => { info =>  'circuit 1 low pressure switch alarm',                              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    146 => { info =>  'circuit 2 low pressure switch alarm',                              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    147 => { info =>  'circuit 1 low pressure transducer alarm',                          type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    148 => { info =>  'circuit 2 low pressure transducer alarm',                          type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    149 => { info =>  'circuit 1 high pressure transducer alarm',                         type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    150 => { info =>  'circuit 2 high pressure transducer alarm',                         type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    151 => { info =>  'circuit 1 compressors differential pressure alarm',                type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    152 => { info =>  'circuit 2 compressors differential pressure alarm',                type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    153 => { info =>  'circuit 1 common EEV driver alarm',                                type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    154 => { info =>  'circuit 1 EEV network failure alarm',                              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    155 => { info =>  'circuit 1 EEV suction pressure or temperature alarm',              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    156 => { info =>  'circuit 1 EEV stepper motor alarm',                                type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    157 => { info =>  'circuit 1 EEV valve not closed alarm',                             type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    158 => { info =>  'circuit 2 common EEV driver alarm',                                type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    159 => { info =>  'circuit 2 EEV network failure alarm',                              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    160 => { info =>  'circuit 2 EEV suction pressure or temperature alarm',              type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    161 => { info =>  'circuit 2 EEV stepper motor alarm',                                type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    162 => { info =>  'circuit 2 EEV valve not closed alarm',                             type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    163 => { info =>  'power meter off line',                                             type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    164 => { info =>  'power meter low voltage alarm',                                    type => 'SoftAlarm',     value => ['No alarm', 'Alarm'],               remark => '' },
    181 => { info =>  'enable remote on/off access',                                      type => 'NoAlarm',       value => ['No alarm', 'Alarm'],               remark => '' },
    182 => { info =>  'reset alarms',                                                     type => 'NoAlarm',       value => ['No alarm', 'Alarm'],               remark => '' }
    } ,
  'analog' => {
     19 => { info => 'chiller outside ambient',                unit => 'ºC',  remark => '' },
     20 => { info => 'chiller return water temperature',       unit => 'ºC',  remark => '' },
     21 => { info => 'chiller supply water temperature',       unit => 'ºC',  remark => '' },
     23 => { info => 'chiller actual temperature setpoint',    unit => 'ºC',  remark => '' },
     24 => { info => 'circuit 1 liquid pressure',              unit => 'bar', remark => 'Winter: ~11, sumer ~18' },
     25 => { info => 'circuit 2 liquid pressure',              unit => 'bar', remark => 'Winter: ~11, sumer ~18' },
     26 => { info => 'Circuit 1 suction pressure without EVD', unit => 'bar', remark => '3.4 - 5 normal' },
     27 => { info => 'Circuit 1 suction pressure without EVD', unit => 'bar', remark => '3.4 - 5 normal' },
     28 => { info => 'refrigerant leak detection level',       unit => '%',   remark => '' },
     29 => { info => 'water differential pressure',            unit => 'Pa',  remark => '' },
     30 => { info => 'evaporator water inlet temperature',     unit => 'ºC',  remark => '' },
     31 => { info => 'condenser water temperature',            unit => 'ºC',  remark => '' },
     32 => { info => 'compressor cooling demand',              unit => '%',   remark => '' },
     33 => { info => 'compressor cooling demand (sequencer)',  unit => '%',   remark => '' },
     34 => { info => 'free cooling valve position',            unit => '%',   remark => '' },
     36 => { info => 'head pressure control',                  unit => '%',   remark => '' },
     38 => { info => 'eev1 suction temperature circuit 1',     unit => 'ºC',  remark => '' },
     39 => { info => 'eev2 suction temperature circuit 2',     unit => 'ºC',  remark => '' },
     40 => { info => 'eev1 suction pressure circuit 1',        unit => 'bar', remark => '' },
     41 => { info => 'eev2 suction pressure circuit 2',        unit => 'bar', remark => '' },
     42 => { info => 'eev1 actual superheat 1',                unit => 'ºC',  remark => '3-11 normal' },
     43 => { info => 'eev2 actual superheat 2',                unit => 'ºC',  remark => '3-11 normal' },
     54 => { info => 'water flow',                             unit => 'l/m', remark => '4.1-5 normal' },
     58 => { info => 'pump 1 invertor speed',                  unit => '%',   renark => '' },
     59 => { info => 'pump 2 invertor speed',                  unit => '%',   renark => '' },
     79 => { info => 'strategy version',                       unit => '',    remark => 'No specific units' },
     80 => { info => 'test variable',                          unit => '',    remark => 'Normal value is 464.8', },
    110 => { info => 'change cooling setpoint by supervisor',  unit => 'ºC',  remark => '' },
    111 => { info => 'change second setpoint by supervisor',   unit => 'ºC',  remark => '' },
    112 => { info => 'change cooling band by supervisor',      unit => 'ºC',  remark => 'Value from 4.0 - 8.0' }
    } 
  };

$OIDbase = "1.3.6.1.4.1.9839.2.1.";
$OIDdigital = "1.";
$OIDanalog  = "2.";
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

	my $chiller_ip = $_[0];
	my $label      = $_[1];

    my $self = {
      'ip'          => $chiller_ip, 
      'label'       => $label,
      'description' => $description,
      'digital'     => { },
      'analog'      => { }
      };

	# Open the SNMP-session
	my ($session, $error) = Net::SNMP->session(
             -hostname  => $chiller_ip,
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
	    my $oid = $OIDbase.$OIDdigital.$mykey.".0";
	    my $result = $session->get_request( $oid )
	        or die ("SNMP service $oid is not available on this SNMP server.");
	    $self->{'digital'}{$mykey} = $result->{$oid};
    	# print ( "Digital key ", $mykey, " has value ", $self->{'digital'}{$mykey}, "\n" );
    }

    foreach my $mykey ( sort keys %{ $description->{'analog'} } ) { 
    	my $oid = $OIDbase.$OIDanalog.$mykey.".0";
	    my $result = $session->get_request( $oid ) 
	        or die ("SNMP service $oid is not available on this SNMP server.");
	    $self->{'analog'}{$mykey} = $result->{$oid} / 10.;
    	# print ( "Analog key ", $mykey, " has value ", $self->{'analog'}{$mykey}, "\n" );
    }
    
    # Close the connection
    $session->close;

    # Add the timestamp field
    $self->{'timestamp'} = strftime( "%y%m%d-%H%M", localtime );

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
	
	my @logdata = (
	  $self->{'timestamp'},
	  $self->{'analog'}{19}, 
	  $self->{'analog'}{20}, 
	  $self->{'analog'}{21}, 
	  $self->{'analog'}{23}, 
	  $self->{'analog'}{30}, 
	  $self->{'analog'}{24}, 
	  $self->{'analog'}{25}, 
	  $self->{'analog'}{40}, 
	  $self->{'analog'}{41}, 
	  $self->{'analog'}{38}, 
	  $self->{'analog'}{39}, 
	  $self->{'analog'}{42}, 
	  $self->{'analog'}{43}, 
	  $self->{'analog'}{36}, 
	  $self->{'analog'}{54}, 
	  $self->{'analog'}{34}, 
	  $self->{'digital'}{35}, 
	  $self->{'digital'}{37}, 
	  $self->{'digital'}{39}, 
	  $self->{'digital'}{41}, 
	  $self->{'digital'}{29}, 
	  $self->{'digital'}{31}, 
	  $self->{'digital'}{102}, 
	  $self->{'digital'}{103}
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

    }	
	
	# Now prepare the data record.
	my @dataline = ( $self->{'timestamp'} );
	foreach my $mykey ( sort {$a<=>$b} keys %{ $description->{'digital'} } ) { 
        push @dataline, $self->{'digital'}{$mykey};
    }
	foreach my $mykey ( sort {$a<=>$b} keys %{ $description->{'analog'} } ) { 
        push @dataline, $self->{'analog'}{$mykey};
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
	
	if    ( $self->{'digital'}->{103} != 0  ) { $status = "Critical"; }
	elsif ( $self->{'digital'}->{102} != 0  ) { $status = "Non-Critical"; }
	else                                      { $status = "Normal" };
	
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
	
	# Alarms are a consecutive list of keys from 102 to 164, but we decided
	# to go for a more generic code instead that doesn't require this.
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

