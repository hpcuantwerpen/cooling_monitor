package DEVICE::deviceHelpers;

#use Data::Dumper qw(Dumper);

sub RangeCheck
{
	
	my $val   = shift;
	my $range = shift;
	
	my $status;
	
	if ( ( $val >= $range->[1] ) && ( $val <= $range->[2] ) )    { $status = 'Normal'; }
	elsif ( ( $val >= $range->[0] ) && ( $val <= $range->[3] ) ) { $status = 'SoftAlarm'; }
	else                                                         { $status = 'CriticalAlarm'; };
	
	return $status;

}



# [end DEVICE::deviceHelpers code] -------------------------------------------------------
1;
__END__
