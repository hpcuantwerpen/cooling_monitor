#! /usr/bin/env perl
#

#use Data::Dumper qw(Dumper);

&convert_chiller1to3 ;
&convert_chiller4;
&convert_cooler( "cooler01.data" );
&convert_cooler( "cooler02.data" );
&convert_ahu;

exit(0);



#
# Convert the data from chiller01-03
#
# * Input format: See also OneNote cluster: File with 52 values per line, comma-separated.
#	* Column 1: Time stamp yymmdd-hhmm
#	* Other columns:
#		                    Chiller 1  Chiller 2  Chiller 3
#	  Return Water Temp             2          3          4
#	  Supply Water Temp             5          6          7
#     Ambient                       8          9         10
#     Circ 1 Suction Press         11         12         13
#     Circ 2 Liquid Press          14         15         16
#     Circ 2 Suction Press         17         18         19
#     Circ 2 Liquid Press          20         21         22
#     Water Flow Rate              23         24         25
#     Compressor 1                 26         27         28
#     Compressor 2                 29         30         31
#     Compressor 3                 32         33         34
#     Compressor 4                 35         36         37
#     Pump 1                       38         39         40
#     Pump 2                       41         42         43
#     Circuit 1 alarm              44         45         46
#     Circuit 2 alarm              47         48         49
#     Flow alarm                   50         51         52
# * Output format: See get_Data.pl or OneNote cluster. Fields are tab-separated.
sub convert_chiller1to3 {

    open( $inputfile, "<", "chiller/chiller01-03.data" )
	  or die "Could not open the input file chiller/chiller01-03.data";
    open( $chiller1file, ">", "chiller01.data" );
    open( $chiller2file, ">", "chiller02.data" );

    $linenum = 0;   # We need to count lines since the first 3218 lines contain useless data for chiller02
    while ($line = <$inputfile>) {
        $linenum++;
        $line =~ s/\n//;
        $line =~ s/\r//;
        $line =~ s/Unit OFF-LINE/NaN/g;
        @fields = split /,/, $line ;
        print $chiller1file "$fields[ 0]\t$fields[ 7]\t$fields[ 1]\t$fields[ 4]\tNaN\tNaN\t" .
                            "$fields[13]\t$fields[19]\t$fields[10]\t$fields[16]\tNaN\tNaN\tNaN\tNaN\tNaN\t".
                            "$fields[22]\tNaN\t$fields[25]\t$fields[28]\t$fields[31]\t$fields[34]\t".
                            "NaN\tNaN\t0\t".
                            ( ( $fields[43] || $fields[46] || $fields[49] ) ? "1" : "0" )."\n";
        if ( $linenum > 3218 ) {
            print $chiller2file "$fields[ 0]\t$fields[ 8]\t$fields[ 2]\t$fields[ 5]\tNaN\tNaN\t" .
                                "$fields[14]\t$fields[20]\t$fields[11]\t$fields[17]\tNaN\tNaN\tNaN\tNaN\tNaN\t".
                                "$fields[23]\tNaN\t$fields[26]\t$fields[29]\t$fields[32]\t$fields[35]\t".
                                "NaN\tNaN\t0\t".
                                ( ( $fields[44] || $fields[47] || $fields[50] ) ? "1" : "0" )."\n";
        }
    }

    close( $inputfile );
    close( $chiller1file );
    close( $chiller2file );

}



# Convert data for chiller04
# * Input format: 
#   Column  Var	                      Format
#        1 Time stamp                 yymmdd-hhmm
#        2 Ambient temperature	
#        3 Return water temperature	
#        4 Supply water temperature	
#        5 Temperature set point	
#        6 Circuit 1 liquid pressure	
#        7 Circuit 2 liquid pressure	
#        8 Water inlet temperature	
#        9 Head pressure control      Float (%)
#       10 Circuit 1 suction temperature	
#       11 Circuit 2 suction temperature	
#       12 Circuit 1 suction pressure	
#       13 Circuit 2 suction pressure	
#       14 Circuit 1 superheat	
#       15 Circuit 2 superheat	
#       16 Water flow	
# * Output format: See get_data.pl or OneNote cluster. Fields are tab-separated

sub convert_chiller4 {
	
	open( $inputfile, "<", "chiller/chiller04.data" )
	  or die "Could not open the input file chiller/chiller04.data";
	open( $chiller4file, ">", "chiller04.data" );

    while ($line = <$inputfile>) {
        $line =~ s/\n//;
        $line =~ s/\r//;
        @fields = split /,/, $line ;
    	print $chiller4file "$fields[ 0]\t$fields[ 1]\t$fields[ 2]\t$fields[ 3]\t".
    	                    "$fields[ 4]\t$fields[ 7]\t$fields[ 5]\t$fields[ 6]\t".
    	                    "$fields[11]\t$fields[12]\t$fields[ 9]\t$fields[10]\t".
    	                    "$fields[13]\t$fields[14]\t$fields[ 8]\t$fields[15]\t".
    	                    "NaN\tNaN\tNaN\tNaN\tNaN\tNaN\tNaN\tNaN\tNaN\n";
    }
	
    close( $inputfile );
    close( $chiller4file );

}


# Convert data for the coolers.
# * Input format: we start from the files cooler01.data and cooler02.data.
#   These are comma-separated files with 8 data fields:
#   1  Time stamp
#   2  Return air temperature
#   3  Return air humidity
#   4  Supply air temperature
#   5  Aisle differential pressure
#   6  Inlet water temperature
#   7  Evaporator fan speed
#   8  CW valve position
# * Output format: See get_data.pl.
#   Fields for which we have no data are set to NaN.
#
# The subroutine had 1 input argument which is the name of the data file
# without the directory prefix.
#
sub convert_cooler {

    my $fname = $_[0];

    open( $inputfile, "<", "cooler/$fname" )
	  or die "Could not open the input file cooler/$fname";
	open( $outputfile, ">", $fname );
	
    while ($line = <$inputfile>) {
        $line =~ s/\n//;
        $line =~ s/\r//;
        @fields = split /,/, $line ;
	    print $outputfile "$fields[0]\t$fields[1]\t$fields[2]\t$fields[3]\t".
	                      "NaN\t$fields[4]\t$fields[5]\t$fields[6]\t$fields[7]\t".
	                      "NaN\tNaN\tNaN\tNaN\tNaN\n"
    }
	
	close( $inputfile );
	close( $outputfile );

}


# Convert data for the air handling units.
# * Input: The dumps of the original HTML-files as they contain more information
#   then the .data file.
# * Output format: See get_data.pl, tab-separated file.

sub convert_ahu {
	
	open( ahu01file, ">", "ahu01.data" );
	open( ahu02file, ">", "ahu02.data" );
	open( ahu03file, ">", "ahu03.data" );
	open( ahu04file, ">", "ahu04.data" );
	open( ahu05file, ">", "ahu05.data" );
	
	my @files = glob( './ahu/*.html' );
	
	foreach my $file (sort @files) {
	
	    open( my $inputfile, "<", $file ) or die "Cannot open the input file $file";
	    my @webpage = <$inputfile>;
	    close( $inputfile );
	    
	    $file =~ /.*(\d\d\d\d\d\d-\d\d\d\d).*/;
	    $timestamp = $1;

        # First set of data: All variables except "Set point" and "Chiller enabled"
        # - Select the lines with actual data.
        @dataset = grep( /P STYLE=\"color: rgb\(.*SPAN STYLE/, @webpage );
        # - Omit HTML and unnecessary spaces.
        map { s/<[^>]*>//g ; s/&nbsp;//g ; s/ *//g ; s /\n//g ; s /\r//g ; $_ } @dataset;
        
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

       print ahu01file "$timestamp\t$dataset[0]\t$dataset[5]\t$dataset[10]\t$dataset[35]\t$dataset[20]\t$dataset[30]\t$dataset[25]\n";
       print ahu02file "$timestamp\t$dataset[1]\t$dataset[6]\t$dataset[11]\t$dataset[36]\t$dataset[21]\t$dataset[31]\t$dataset[26]\n";
       print ahu03file "$timestamp\t$dataset[2]\t$dataset[7]\t$dataset[12]\t$dataset[37]\t$dataset[22]\t$dataset[32]\t$dataset[27]\n";
       print ahu04file "$timestamp\t$dataset[3]\t$dataset[8]\t$dataset[13]\t$dataset[38]\t$dataset[23]\t$dataset[33]\t$dataset[28]\n";
       print ahu05file "$timestamp\t$dataset[4]\t$dataset[9]\t$dataset[14]\t$dataset[39]\t$dataset[24]\t$dataset[34]\t$dataset[29]\n";
		
	}
		
	close( ahu01file );
	close( ahu02file );
	close( ahu03file );
	close( ahu04file );
	close( ahu05file );
	
}
