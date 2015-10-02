#! /usr/bin/env perl
#
# Convert the data files (but not the log files at the moment) to use a Zulu time timestamp.
##! /usr/bin/env perl
#

use Data::Dumper qw(Dumper);
use POSIX qw(strftime);
use Time::Local;


my $infile  = $ARGV[0];
my $outfile = $ARGV[1];

@transition = ( 1203250200, 1210280300, 1303310200, 1310270300, 1403300200, 
                1410260300, 1503290200, 1510250300, 1603270200, 1610300300, 
                9912312499 );  # Last element is a sentinel.
my $winter_offset  = 1; # Offset in hours from GMT for winter time
my $summer_offset  = 2; # Offset in hours from GMT for summer time
my $int0_offset    = 2; # First interval is summer time
my $current_offset = 0;
my $current_cor    = 0;

my $recordnum = -1; # Number of the current record being processed. 0 is the first record in the file.
my $interval  = -1; # Start point of the interval in @transition of the current record. 
                    # E.g., 0 means the interval between the first two entries of @transition
my $current_last = 0;
my @output = ( );

open( INFILE, '<', $infile ) or die "Cannot open the input file $infile\n";

while ( <INFILE> ) {

	$recordnum++;
	@fields = split( "\t", $_ );
	$date_time = $fields[0];
	$date_time =~ s/\-//;

	if ( $recordnum == 0 ) {
		# This is the first record, we need to do some extra initialisations.
        $current_offset = ($int0_offset == $winter_offset) ? $summer_offset : $winter_offset; # Time offset for interval "-1"
		while ( $date_time >= $transition[$interval+1] ) { 
			$interval++; 
			$current_offset = ($current_offset == $winter_offset) ? $summer_offset : $ winter_offset;
		}
		# Now $transition[$interval] <= $date_time < $transition[$interval+1]
		($interval >= 0) or die "First date/time in file outside the supported range.\n";
	}
	
	# Detect if we should move up to the next interval.
	if ( $date_time >= $transition[$interval+1] ) {
		$interval++;
		$current_offset = ($current_offset == $winter_offset) ? $summer_offset : $winter_offset;
	}
	
	# During the transition hour from summer time to winter time, we don't really now for a time
	# stamp between 2 and 3 hour if it was in winter- or summer time. 
	# Our trick is: If we have already had a later time, we now for sure that we should interpret
	# the time stamp as a time in winter time.
	($current_cor, $current_last) = ($date_time > $current_last) ? (0, $date_time) : (1, $current_last);
    #if ( $current_cor == 1 ) { print "Overlapping time stamp $fields[0] found.\n" }	
	
	# Time::Local::timelocal doesn't seem to be properly dealing with winter- and summertime transitions,
	# so we convert the time stamp to EPOCH time as if it were in GMT and do the time zone correction 
	# ourselves to get the correct EPOCH time.
	# Note that we could use: 
	# POSIX::strptime qw(strptime);
	# my @current_time  = strptime( $date_time, "%y%m%d%H%M" );
	# But we avoid this since strptime is not a core routine and is easy to avoid in our case.
	$fields[0] =~ /(\d\d)(\d\d)(\d\d)-(\d\d)(\d\d)/;
	@current_time = ( 0, $5, $4, $3, $2 - 1, $1 + 100 );
	my $current_epoch = timegm( @current_time ) - ($current_offset - $current_cor) * 3600;
	
	# Now create the new time stamp in GMT = Zulu time, in ISO8601-format
	my $timestamp = strftime(  "%Y%m%dT%H%MZ", gmtime( $current_epoch ) );
	#unshift @fields, $timestamp;
	$fields[0] = $timestamp;
	
	# Push to the contents of the output file.
	push @output, join( "\t", @fields );
	
}

close( INFILE );

open( OUTFILE, '>', $outfile ) or die "Failed to open the output file $outfile";
print OUTFILE @output;
close( OUTFILE )