package chillerAD04;

use IO::File;
use HTTP::Request;
use LWP::UserAgent;
use POSIX qw(strftime);

#use Data::Dumper qw(Dumper);


$description = {
  'digital' => { 
    15 => { info =>  'compressor 1 on/off ', type => 'NoAlarm' },
    16 => { info =>  'compressor 2 on/off ', type => 'NoAlarm' },
    17 => { info =>  'compressor 3 on/off ', type => 'NoAlarm' },
    18 => { info =>  'compressor 4 on/off ', type => 'NoAlarm' },
    21 => { info =>  'pump 1 on/off ',       type => 'NoAlarm' },
    22 => { info =>  'pump 2 on/off ',       type => 'NoAlarm' },
    23 => { info =>  'circuit 1 alarm ',     type => 'CriticalAlarm' },
    24 => { info =>  'circuit 2 alarm ',     type => 'CriticalAlarm' },
    28 => { info =>  'cooler disabled',      type => 'NoAlarm' },         # Not sure that we read the correct value.
    54 => { info =>  'flow alarm ',          type => 'CriticalAlarm' }
    } ,
  'analog' => {
      1 => { info => 'circuit 1 liquid pressure ',        max => '' },
      2 => { info => 'circuit 2 liquid pressure ',        max => '' },
      4 => { info => 'chiller return water temperature ', max => '' },
      5 => { info => 'chiller supply water temperature ', max => '' },
     11 => { info => 'eev1 suction pressure circuit 1 ',  max => '' },
     12 => { info => 'eev2 suction pressure circuit 2 ',  max => '' },
     13 => { info => 'Temperature set point ',            max => '' },
     17 => { info => 'chiller outside ambient ',          max => '' },
    122 => { info => 'water flow ',                       max => '' }
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

	my $chiller_offset = $_[0] - 1;  # 0, 1 or 2 expected for $chiller_offset.
	my $label          = $_[1];

    #
    # Read the data via the web page.
    #
    if ( time() - $webcache->{epoch} > 15 ) {

        # Store the time of the request.
        $webcache->{epoch}   = time();

        my $req = HTTP::Request->new( GET => 'http://10.28.243.234/administrator/body_airedale_chillers.html' );
        $req->authorization_basic('airegate', 'airegate');

        my $ua = LWP::UserAgent->new;
        my @webpage = split /\r\n/, $ua->request($req)->decoded_content;

        # First set of data: All variables except "Set point" and "Chiller enabled"
        # - Select the lines with actual data.
        @dataset = grep( /P STYLE=\"color: rgb\(.*SPAN STYLE/, @webpage );
        # - Transform "Unit OFF-LINE" and omit HTML and unnecessary spaces.
        map { s/Unit OFF-LINE/NaN/ ; s/<[^>]*>//g ; s/&nbsp;//g ; s/ *//g ; s /\r//g ; $_ } @dataset;
        
        # Second set of data: Temperature set points
        # - Select the lines with actual data.
        @datalines = grep( /var\(\d,2,13,0,99\)/, @webpage );
        # - Extract the data.
        foreach (@datalines) {
        	s/Unit OFF-LINE/NaN/;
        	/.*VALUE=\"([0-9.Na]+)\".*/;
        	push @dataset, $1;
        }

        # Third set of data: Unit disabled
        # - Select the lines with actual data.
        @datalines = grep( /var\(\d,1,28,0,1\)/, @webpage );
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
      'offset'      => $chiller_offset, 
      'label'       => $label,
      'description' => $description,
      'timestamp'   => strftime( "%y%m%d-%H%M", localtime( $webcache->{epoch} ) ), 
      'digital'     => {
         15 => $webcache->{webdata}[24+$chiller_offset],
         16 => $webcache->{webdata}[27+$chiller_offset],
         17 => $webcache->{webdata}[30+$chiller_offset],
         18 => $webcache->{webdata}[33+$chiller_offset],
         21 => $webcache->{webdata}[36+$chiller_offset],
         22 => $webcache->{webdata}[39+$chiller_offset],
         23 => $webcache->{webdata}[42+$chiller_offset],
         24 => $webcache->{webdata}[45+$chiller_offset],
         28 => $webcache->{webdata}[54+$chiller_offset],
         54 => $webcache->{webdata}[48+$chiller_offset]  	
         },
      'analog'      => {
      	  1 => $webcache->{webdata}[12+$chiller_offset], 
          2 => $webcache->{webdata}[18+$chiller_offset],
          4 => $webcache->{webdata}[0 +$chiller_offset],
          5 => $webcache->{webdata}[3 +$chiller_offset],
         11 => $webcache->{webdata}[9 +$chiller_offset],
         12 => $webcache->{webdata}[15+$chiller_offset],
         13 => $webcache->{webdata}[51+$chiller_offset],
         17 => $webcache->{webdata}[6 +$chiller_offset],
        122 => $webcache->{webdata}[21+$chiller_offset]
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
	
	if    ( $self->{'digital'}->{23} || $self->{'digital'}->{24} || $self->{'digital'}->{54} ) { 
		$status = "Critical"; 
	} else { $status = "Normal" }
	
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

