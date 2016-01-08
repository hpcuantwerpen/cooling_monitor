package DEVICE::generic;


$description = {
  'digital' => { } ,
  'analog'  => {  },
  'integer' => { } 
  };
  
$OIDdigital = "1.";
$OIDanalog  = "2.";
$OIDinteger = "3.";
$FS = "\t";  # Field separator for the log file output.
  
  


#
# Generic constructor, doesn't really do anything useful.
#
sub New
{

    my $proto = shift;
    my $class = ref($proto) || $proto;

	
    my $self = {
      'description' => $description,
      'digital'     => { },
      'analog'      => { },
      'integer'     => { }
      };

    # Add the timestamp field
    $self->{'timestamp'} = strftime( "%Y%m%dT%H%MZ", gmtime );

    # Finalise the object creation
    bless( $self, $class );
    return $self;
	
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
    	
    	foreach my $mykey ( sort {$a<=>$b} keys %{ $self->{'description'}{'digital'} } ) { 
    		push @labelline, "\"$OIDdigital$mykey\"";
        }

        foreach my $mykey ( sort {$a<=>$b} keys %{ $self->{'description'}{'analog'} } ) { 
    		push @labelline, "\"$OIDanalog$mykey\"";
        }    	

        foreach my $mykey ( sort {$a<=>$b} keys %{ $self->{'description'}{'integer'} } ) { 
    		push @labelline, "\"$OIDinteger$mykey\"";
        }    	

    }	
	
	# Now prepare the data record.
	my @dataline = ( $self->{'timestamp'} );
	foreach my $mykey ( sort {$a<=>$b} keys %{ $self->{'description'}{'digital'} } ) { 
        push @dataline, $self->{'digital'}{$mykey};
    }
	foreach my $mykey ( sort {$a<=>$b} keys %{ $self->{'description'}{'analog'} } ) { 
        push @dataline, $self->{'analog'}{$mykey};
    }
	foreach my $mykey ( sort {$a<=>$b} keys %{ $self->{'description'}{'integer'} } ) { 
        push @dataline, $self->{'integer'}{$mykey};
    }

    my $fh = IO::File->new( $logfilename, '>>' ) or die "Could not open file '$logfilename'";
    if ( $#labelline > 0 ) { $fh->print( join($FS, @labelline), "\n" ); }
    $fh->print( join($FS, @dataline), "\n" );
    $fh->close;
	
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
		if ( $self->{'description'}{'digital'}{$key}{'type'} ne "NoAlarm" ) { # We have an alarm, could be SoftAlarm or CriticalAlarm but that doesn't matter.
			if ( $self->{'digital'}{$key} != 0 ) {
				push @alarmlist, ( { source => $self->{'label'}, 
					                 message => $self->{'description'}{'digital'}{$key}{'info'}, 
					                 level => $self->{'description'}{'digital'}{$key}{'type'},
					                 ID => join(  '.', $self->{'label'}, 1, $key ),
					                 timestamp => $self->{'timestamp'} } );
			} # end if
		} # end if
	} # end foreach
	
	return @alarmlist;
} # end sub


sub ObjDef
{
	
	return __FILE__;
	
}

#
# End of the package definition.
#
1; # Required to make sure the use or require commands succeed.




