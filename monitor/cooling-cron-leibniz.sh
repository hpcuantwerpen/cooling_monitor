#!/bin/bash -l

if (( $# == 1 )); then
  interval=$1
else
  interval=310
fi

module load calcua/2018b gnuplot/5.2.4-intel-2018b
# module load Perl/5.26.1-intel-2018b


installdir=/failover/cooling
export PERL5LIB=$installdir/monitor
$installdir/monitor/get_data.pl -D $installdir/data -W $installdir/www -I $interval

