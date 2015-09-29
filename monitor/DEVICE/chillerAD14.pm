package chillerAD14;

use IO::File;
use Net::SNMP;
use POSIX qw(strftime);

#use Data::Dumper qw(Dumper);

# $description is a reference to an anonymous hash table...
$description = {
  'digital' => { 
     19 => { info =>  'status of remote on/off by digital input (option) ',                type => 'NoAlarm' },
     20 => { info =>  'status of 2nd temperature setpoint by digital input (option) ',     type => 'NoAlarm' },
     21 => { info =>  'unit on/off by keyboard ',                                          type => 'NoAlarm' },
     22 => { info =>  'phase monitor status ',                                             type => 'NoAlarm' },
     23 => { info =>  'MCCB status ',                                                      type => 'NoAlarm' },
     24 => { info =>  'emergency stop status ',                                            type => 'NoAlarm' },
     25 => { info =>  'evaporator flow switch status ',                                    type => 'NoAlarm' },
     26 => { info =>  'pad heater status ',                                                type => 'NoAlarm' },
     27 => { info =>  'unit enabled by sequencer ',                                        type => 'NoAlarm' },
     28 => { info =>  'remote pumps on via digital output ',                               type => 'NoAlarm' },
     29 => { info =>  'pump 1 on/off ',                                                    type => 'NoAlarm' },
     30 => { info =>  'pump 1 contactor status ',                                          type => 'NoAlarm' },
     31 => { info =>  'pump 2 on/off ',                                                    type => 'NoAlarm' },
     32 => { info =>  'chilled water valve on/off ',                                       type => 'NoAlarm' },
     33 => { info =>  'chilled water valve end position ',                                 type => 'NoAlarm' },
     34 => { info =>  '',                                                                  type => 'NoAlarm' },
     35 => { info =>  'compressor 1 on/off ',                                              type => 'NoAlarm' },
     36 => { info =>  'compressor 1 contactor status ',                                    type => 'NoAlarm' },
     37 => { info =>  'compressor 2 on/off ',                                              type => 'NoAlarm' },
     38 => { info =>  'compressor 2 contactor status ',                                    type => 'NoAlarm' },
     39 => { info =>  'compressor 3 on/off ',                                              type => 'NoAlarm' },
     40 => { info =>  'compressor 3 contactor status ',                                    type => 'NoAlarm' },
     41 => { info =>  'compressor 4 on/off ',                                              type => 'NoAlarm' },
     42 => { info =>  'compressor 4 contactor status ',                                    type => 'NoAlarm' },
     43 => { info =>  'compressor 5 on/off ',                                              type => 'NoAlarm' },
     44 => { info =>  'compressor 5 contactor status ',                                    type => 'NoAlarm' },
     45 => { info =>  'compressor 6 on/off ',                                              type => 'NoAlarm' },
     46 => { info =>  'compressor 6 contactor status ',                                    type => 'NoAlarm' },
     47 => { info =>  'circuit 1 low pressure switch status ',                             type => 'NoAlarm' },
     48 => { info =>  'circuit 2 low pressure switch status ',                             type => 'NoAlarm' },
     49 => { info =>  'circuit 1 condenser by pass 1 ',                                    type => 'NoAlarm' },
     50 => { info =>  'circuit 1 condenser by pass 2 ',                                    type => 'NoAlarm' },
     51 => { info =>  'circuit 1 condenser by pass 3 ',                                    type => 'NoAlarm' },
     52 => { info =>  'circuit 2 condenser by pass 1 ',                                    type => 'NoAlarm' },
     53 => { info =>  'circuit 2 condenser by pass 2 ',                                    type => 'NoAlarm' },
     54 => { info =>  'circuit 2 condenser by pass 3 ',                                    type => 'NoAlarm' },
     55 => { info =>  'pump enabled by outdoor ambient temperature ',                      type => 'NoAlarm' },
     56 => { info =>  'sequence manager on/off ',                                          type => 'NoAlarm' },
     80 => { info =>  'test variable ',                                                    type => 'NoAlarm' },
    101 => { info =>  'manual override mode alarm, unit in manual operation ',             type => 'NoAlarm' },
    102 => { info =>  'non-critical alarm ',                                               type => 'SoftAlarm' },
    103 => { info =>  'critical alarm ',                                                   type => 'CriticalAlarm' },
    104 => { info =>  'controller real time clock failure alarm ',                         type => 'SoftAlarm' },
    105 => { info =>  'PLAN network disconnection alarm (1 or more units not connected) ', type => 'SoftAlarm' },
    106 => { info =>  'system maintenance hours alarm ',                                   type => 'SoftAlarm' },
    107 => { info =>  'password alarm - password entered wrong 3 times ',                  type => 'SoftAlarm' },
    108 => { info =>  'return water temperature probe fault alarm ',                       type => 'SoftAlarm' },
    109 => { info =>  'supply water temperature probe fault alarm ',                       type => 'SoftAlarm' },
    110 => { info =>  'ambient air temperature probe fault alarm ',                        type => 'SoftAlarm' },
    111 => { info =>  'liquid pressure alarm ',                                            type => 'SoftAlarm' },
    112 => { info =>  'circuit 2 liquid pressure alarm ',                                  type => 'SoftAlarm' },
    113 => { info =>  'circuit 1 liquid pressure sensor faulty without EVD ',              type => 'SoftAlarm' },
    114 => { info =>  'circuit 2 liquid pressure sensor faulty without EVD ',              type => 'SoftAlarm' },
    115 => { info =>  'inlet water temperature probe faulty alarm ',                       type => 'SoftAlarm' },
    116 => { info =>  'water differential pressure probe faulty alarm ',                   type => 'SoftAlarm' },
    117 => { info =>  'condenser water temperature faulty ',                               type => 'SoftAlarm' },
    118 => { info =>  'alarm: remote setpoint adjust 0- 10vdc input faulty ',              type => 'SoftAlarm' },
    119 => { info =>  'alarm: refrigerant leak detector faulty ',                          type => 'SoftAlarm' },
    120 => { info =>  'refrigerant leak detected ',                                        type => 'SoftAlarm' },
    121 => { info =>  'refrigerant leak detected, compressors disabled alarm ',            type => 'CriticalAlarm' },
    122 => { info =>  'MCCB status alarm, unit isolator off/tripped ',                     type => 'SoftAlarm' },
    123 => { info =>  'emergency stop alarm ',                                             type => 'CriticalAlarm' },
    124 => { info =>  'Phase alarm ',                                                      type => 'SoftAlarm' },
    125 => { info =>  'frost protection alarm ',                                           type => 'SoftAlarm' },
    126 => { info =>  'high return water temperature alarm ',                              type => 'SoftAlarm' },
    127 => { info =>  'pump contactor status 1 alarm ',                                    type => 'SoftAlarm' },
    128 => { info =>  'pump contactor status 2 alarm ',                                    type => 'SoftAlarm' },
    129 => { info =>  'no evaporator flow alarm ',                                         type => 'CriticalAlarm' },
    130 => { info =>  'flow switch stuck (n/c) alarm ',                                    type => 'SoftAlarm' },
    131 => { info =>  'evaporator differential pressure alarm ',                           type => 'SoftAlarm' },
    132 => { info =>  'chilled water valve faulty alarm ',                                 type => 'SoftAlarm' },
    133 => { info =>  '3 way free cooling valve alarm valve in wrong position',            type => 'SoftAlarm' },
    134 => { info =>  'serious flow alarm within 24 hours ',                               type => 'SoftAlarm' },
    135 => { info =>  'compressors oil pre- heater timer disabled ',                       type => 'SoftAlarm' },
    136 => { info =>  'compressor 1 contactor status alarm ',                              type => 'SoftAlarm' },
    137 => { info =>  'compressor 2 contactor status alarm ',                              type => 'SoftAlarm' },
    138 => { info =>  'compressor 3 contactor status alarm ',                              type => 'SoftAlarm' },
    139 => { info =>  'compressor 4 contactor status alarm ',                              type => 'SoftAlarm' },
    140 => { info =>  'compressor 5 contactor status alarm ',                              type => 'SoftAlarm' },
    141 => { info =>  'compressor 6 contactor status alarm ',                              type => 'SoftAlarm' },
    143 => { info =>  'circuit 1 common alarm ',                                           type => 'SoftAlarm' },
    144 => { info =>  'circuit 2 common alarm ',                                           type => 'SoftAlarm' },
    145 => { info =>  'circuit 1 low pressure switch alarm ',                              type => 'SoftAlarm' },
    146 => { info =>  'circuit 2 low pressure switch alarm ',                              type => 'SoftAlarm' },
    147 => { info =>  'circuit 1 low pressure transducer alarm ',                          type => 'SoftAlarm' },
    148 => { info =>  'circuit 2 low pressure transducer alarm ',                          type => 'SoftAlarm' },
    149 => { info =>  'circuit 1 high pressure transducer alarm ',                         type => 'SoftAlarm' },
    150 => { info =>  'circuit 2 high pressure transducer alarm ',                         type => 'SoftAlarm' },
    151 => { info =>  'circuit 1 compressors differential pressure alarm ',                type => 'SoftAlarm' },
    152 => { info =>  'circuit 2 compressors differential pressure alarm ',                type => 'SoftAlarm' },
    153 => { info =>  'circuit 1 common EEV driver alarm ',                                type => 'SoftAlarm' },
    154 => { info =>  'circuit 1 EEV network failure alarm ',                              type => 'SoftAlarm' },
    155 => { info =>  'circuit 1 EEV suction pressure or temperature alarm ',              type => 'SoftAlarm' },
    156 => { info =>  'circuit 1 EEV stepper motor alarm ',                                type => 'SoftAlarm' },
    157 => { info =>  'circuit 1 EEV valve not closed alarm ',                             type => 'SoftAlarm' },
    158 => { info =>  'circuit 2 common EEV driver alarm ',                                type => 'SoftAlarm' },
    159 => { info =>  'circuit 2 EEV network failure alarm ',                              type => 'SoftAlarm' },
    160 => { info =>  'circuit 2 EEV suction pressure or temperature alarm ',              type => 'SoftAlarm' },
    161 => { info =>  'circuit 2 EEV stepper motor alarm ',                                type => 'SoftAlarm' },
    162 => { info =>  'circuit 2 EEV valve not closed alarm ',                             type => 'SoftAlarm' },
    163 => { info =>  'power meter off line ',                                             type => 'SoftAlarm' },
    164 => { info =>  'power meter low voltage alarm ',                                    type => 'SoftAlarm' },
    181 => { info =>  'enable remote on/off access ',                                      type => 'NoAlarm' },
    182 => { info =>  'reset alarms ',                                                     type => 'NoAlarm' }
    } ,
  'analog' => {
    19 => { info => 'chiller outside ambient ',             max => '' },
    20 => { info => 'chiller return water temperature ',    max => '' },
    21 => { info => 'chiller supply water temperature ',    max => '' },
    23 => { info => 'chiller actual temperature setpoint ', max => '' },
    24 => { info => 'circuit 1 liquid pressure ',           max => '' },
    25 => { info => 'circuit 2 liquid pressure ',           max => '' },
    30 => { info => 'evaporator water inlet temperature ',  max => '' },
    34 => { info => 'free cooling valve position ',         max => '' },
    36 => { info => 'head pressure control ',               max => '' },
    38 => { info => 'eev1 suction temperature circuit 1 ',  max => '' },
    39 => { info => 'eev2 suction temperature circuit 2 ',  max => '' },
    40 => { info => 'eev1 suction pressure circuit 1 ',     max => '' },
    41 => { info => 'eev2 suction pressure circuit 2 ',     max => '' },
    42 => { info => 'eev1 actual superheat 1 ',             max => '' },
    43 => { info => 'eev2 actual superheat 2 ',             max => '' },
    54 => { info => 'water flow',                           max => '' }
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
	
	return $self->{'analog'}{$var};
	
}


sub DVar
{
	
	my $self = $_[0];
	my $var  = $_[1];
	
	return $self->{'digital'}{$var};
	
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

