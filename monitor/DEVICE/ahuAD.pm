package ahuAD;

use IO::File;
use HTTP::Request;
use LWP::UserAgent;
use POSIX qw(strftime);

#use Data::Dumper qw(Dumper);


$description = {
  'digital' => { 
     21 => { info => 'fan operating ',      type => 'NoAlarm' },
     26 => { info => 'non-critical alarm ', type => 'SoftAlarm' },
     27 => { info => 'critical alarm ',     type => 'CriticalAlarm' },
    114 => { info => 'AHU enabled ',        type => 'NoAlarm' }
    } ,
  'analog' => {
      1 => { info => 'air return humidity ',    max => '' },
      4 => { info => 'air return temperature ', max => '' },
      5 => { info => 'air supply temperature ', max => '' },
     12 => { info => 'Temperature set point ',  max => '' },
     35 => { info => 'cooling 0-10vdc ',        max => '' }
    } 
  };

$OIDdigital = "1.";
$OIDanalog  = "2.";
$FS = "\t";  # Field separator for the log file output.

$webcache = {
    'epoch'   => 0,
    'webdata' => []
  };

#
# Constructor.
# - The first argument is the class, chillerAD04, or the object
# - The second argument is either 1 or 2, for chiller01 and chiller02.
#
sub New
{

    my $proto = shift;
    my $class = ref($proto) || $proto;

	my $ahu_offset = $_[0] - 1;
	my $label      = $_[1];

    #
    # Re-read the data if needed.
    #
    if ( time() - $webcache->{epoch} > 15 ) {

        # Store the time of the request.
        $webcache->{epoch}   = time();

        my $req = HTTP::Request->new( GET => 'http://10.28.243.234/administrator/body_airedale_ahu_s.html' );
        $req->authorization_basic('airegate', 'airegate');

        my $ua = LWP::UserAgent->new;
        my @webpage = split /\r\n/, $ua->request($req)->decoded_content;

        # First set of data: All variables except "Set point" and "Chiller enabled"
        # - Select the lines with actual data.
        @dataset = grep( /P STYLE=\"color: rgb\(.*SPAN STYLE/, @webpage );
        # - Omit HTML and unnecessary spaces.
        map { s/<[^>]*>//g ; s/&nbsp;//g ; s/ *//g ; s /\r//g ; $_ } @dataset;
        
        # Second set of data: Temperature set points
        # - Select the lines with actual data.
        @datalines = grep( /var\(\d,2,12,0,99\)/, @webpage );
        # - Extract the data.
        foreach (@datalines) {
        	s/Unit OFF-LINE/NaN/;
        	/.*VALUE=\"([0-9.Na]+)\".*/;
        	push @dataset, $1;
        }

        # Third set of data: Unit enabled
        # - Select the lines with actual data.
        @datalines = grep( /var\(\d,1,114,0,1\)/, @webpage );
        # - Extract the data.
        foreach (@datalines) {
        	s/Unit OFF-LINE/NaN/;
        	/.*VALUE=\"([01Na]+)\".*/;
        	push @dataset, $1;
        }
                
        # Store the data in the cache
        $webcache->{webdata} = \@dataset;

    }

    #
    # Now extract the data from webpage and store in the structure for further processing.
    #

    my $self = {
      'offset'      => $ahu_offset, 
      'label'       => $label,
      'description' => $description,
      'timestamp'   => strftime( "%y%m%d-%H%M", localtime( $webcache->{epoch} ) ), 
      'digital'     => {
          21 => $webcache->{webdata}[20+$ahu_offset],
          26 => $webcache->{webdata}[30+$ahu_offset],
          27 => $webcache->{webdata}[25+$ahu_offset],
         114 => $webcache->{webdata}[40+$ahu_offset]
         },
      'analog'      => {
          1 => $webcache->{webdata}[5 +$ahu_offset],
          4 => $webcache->{webdata}[   $ahu_offset],
          5 => $webcache->{webdata}[10+$ahu_offset],
         12 => $webcache->{webdata}[35+$ahu_offset],
         35 => $webcache->{webdata}[15+$ahu_offset]
        }
      };

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
	  $self->{'digital'}{21}, 
	  $self->{'digital'}{26}, 
	  $self->{'digital'}{27}
	  );

    # print( "To $filename: ", join(",", @logdata), "\n" ) ;
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
	
	if    ( $self->{'digital'}->{27} != 0  ) { $status = "Critical"; }
	elsif ( $self->{'digital'}->{26} != 0  ) { $status = "Non-Critical"; }
	else                                     { $status = "Normal" };
	
	return $status;
	
}


sub AVar
{
	
	my $self = $_[0];
	my $var  = $_[1];
	
	return $self->{'analog'}{$var} ;
	
}


sub DVar
{
	
	my $self = $_[0];
	my $var  = $_[1];
	
	return $self->{'digital'}{$var} ;
	
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

