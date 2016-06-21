#! /usr/bin/env perl
#
# This script adds the "Cooling 0-10Vdc" field to the AHU data file.
#
# First argument: The AHU .data file to update
# Second and following 

use IO::File;
use Data::Dumper qw(Dumper);

#
# Set some locations etc.
#
#my $datadir    = "./data";
my $datadir    = ".";

my $datafile   = $ARGV[0];
shift @ARGV;
print( "Modifying data in $datadir/$datafile\n" );

#
# Read the log file, we'll use this data to update the 
#

$logdata = {};

while ( @ARGV ) {
    
    my $filename = "$datadir/$ARGV[0]";
    shift @ARGV;
    print( "Reading the log file $filename\n" );
    
    open( FH, $filename ) or die "Could not open the input file $filename";
    
    while ( <FH> ) {
        chomp $_;
        @line = split( /\t/, $_ );
        #$logdata{$line[0]} = $line[1];      
        $logdata{$line[0]} = [ $line[1], $line[2], $line[3], $line[4], $line[5], $line[6], $line[7], $line[8], $line[9] ];      
        }  # End while ( <FH> )
    
    close( FH );
    
    }  # End while (@ARGV ), reading of the data.

#
# Now we'll read the log file and rewrite it shifting the 6th to 8th filed one position
# and adding a new field (analog variable 2.35) on position 6. It is put to zero unless
# we've just read a matching value from the data files.
# We also check if the field has already been added in an earlier iteration. In that case
# we might still overwrite the data if we have newer data.
#

my $INdata  = "$datadir/$datafile";
my $OUTdata = "$datadir/$datafile.new";
my $FHin  = IO::File->new( $INdata,  '<' ) or die "Fail to open the input data file $INdata\n";
my $FHout = IO::File->new( $OUTdata, '>' ) or die "Fail to open the output data file $OUTdata\n";

while ( <$FHin> ) {
    
    @line = split( /\t/, $_ );
    my $key = $line[0];
    if ( $#line == 7 ) {
        # 8-field line, need to add the new field.
        my $newval;
        if ( defined $logdata{$key} ) { $newval = $logdata{$key}[8]; }
        else { $newval = 0.0; }
        $FHout->print( join( "\t", $key, $line[1], $line[2], $line[3], $line[4], $newval, $line[5], $line[6], $line[7] ) );
        } 
    else {
        # Must be a 9-field line; we might overwrite the sixth field.
        if ( defined $logdata{$key} ) {
            my $newval = $logdata{$key}[8];
            $FHout->print( join( "\t", $key, $line[1], $line[2], $line[3], $line[4], $newval, $line[6], $line[7], $line[8] ) );
         }
         else {
         	$FHout->print( $_ );
         }
        }  # End else-part if ( $#line == 8 ).       
    }  # End while(<FHin>)

$FHin->close();
$FHout->close();

