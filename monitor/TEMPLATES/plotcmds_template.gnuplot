#
# Template for the GNUplot command file to generate the plots about
# the cooling infrastructure, to be used in combination with
# updata_data.pl.
#
# 2015-09, S. Becuwe and K. Lust
#
# Script for GNUplot 5
#

datadir = "../data/TEST"
webdir  = "../www/TEST"

set terminal svg size 900,400 dynamic enhanced mouse standalone

# Color coding:
# + Temperatures:
#   - Return temperature: Light red   => Linetype 1
#   - Supply temperature: Dark blue   => Linetype 2
#   - Ambient temperature: Dark green => Linetype 3
# + Circuit 1: Magenta/purple tints   => Linetype 11/12
# + Circuit 2: Orange/brown           => Linetype 21/22

set linetype   1 lc rgb "#00F03232" lw 1  # light-red
set linetype 101 lc rgb "#40F03232" lw 1  # light-red transparent
set linetype   2 lc rgb "#0000008B" lw 1  # dark-blue
set linetype 102 lc rgb "#8000008B" lw 1  # dark-blue transparent
set linetype   3 lc rgb "#00006400" lw 1  # dark-green
set linetype 103 lc rgb "#80006400" lw 1  # dark-green transparent
set linetype  11 lc rgb "#00C000FF" lw 1  # dark-magenta
set linetype 111 lc rgb "#80C000FF" lw 1  # dark-magenta transparent
set linetype  12 lc rgb "#00F055F0" lw 1  # light-magenta
set linetype 112 lc rgb "#80F055F0" lw 1  # light-magenta transparent
set linetype  21 lc rgb "#00884014" lw 1  # sienna4
set linetype 121 lc rgb "#20884014" lw 1  # sienna4 transparent
set linetype  22 lc rgb "#00A52A2A" lw 1  # brown
set linetype 122 lc rgb "#20A52A2A" lw 1  # brown transparent

set macros
data_critical = "behind fc rgb \"0xe0ff0000\" fs noborder"
data_warning  = "behind fc rgb \"0xe0ff9900\" fs noborder"
data_safe     = "behind fc rgb \"0xe000ff00\" fs noborder"

set datafile separator "\t"
set xdata time
set timefmt "%Y%m%dT%H%MZ"

# Common to all plots
set key left top            # Set the graph legend position
set grid


#########################################################################################################
#########################################################################################################
#
# Plots for the chillers
#
#########################################################################################################
#########################################################################################################

datafile(n) = sprintf( "%s/chiller%02d.data", datadir, n )
# CHILLERS = "1 2 4"
CHILLERS = ""

#########################################################################################################
#
# Water and ambient temperatures
#
#########################################################################################################

set yrange [0:40]
set ylabel "Temperature (°C)"
svgfile( n, range ) = sprintf( "%s/chiller%02d-temperatures-%s.svg", webdir, n, range )
title(n)            = sprintf( "Chiller%02d Water and ambient temperatures", n )

set object 1 rectangle from graph 0,0          to graph 1,(6./40.)   @data_critical
set object 2 rectangle from graph 0,(6./40.)   to graph 1,(8.5/40.)  @data_warning
set object 3 rectangle from graph 0,(8.5/40.)  to graph 1,(13.5/40.) @data_safe
set object 4 rectangle from graph 0,(13.5/40.) to graph 1,(16./40.)  @data_warning
set object 5 rectangle from graph 0,(16./40.)  to graph 1,1          @data_critical

do for [ns in CHILLERS] {
  n = ns+0   # A trick to force conversion to a number.
  set title  title( n )
  set output svgfile( n, "all" )
  set format x "%m/%d"        # Label format for x-axis
  set xlabel "Date"
  plot \
    datafile(n) using 1:2 with lines lw 1 lt 3 title 'Ambient Temperature', \
    datafile(n) using 1:3 with lines lw 1 lt 1 title 'Return Water Temperature', \
    datafile(n) using 1:4 with lines lw 1 lt 2 title '* Supply Water Temperature'
  set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "365d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "50d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "7d" )
  replot;
  set format x "%h"        # Label format for x-axis
  set xlabel "Time"
  set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "24u" )
  replot;
  unset xrange
}

unset object 1 ; unset object 2 ; unset object 3 ; unset object 4 ; unset object 5

#########################################################################################################
#
# Suction and liquid pressures
#
#########################################################################################################

set ylabel  "Pressure (bar)"
set yrange  [0:27]
set y2label "Temperature (°C)"
set y2range [0:54]
set y2tics  numeric
svgfile( n, range ) = sprintf( "%s/chiller%02d-pressures-%s.svg", webdir, n, range )
title(n)            = sprintf( "Chiller%02d Suction and liquid pressures", n )

set object 1 rectangle from graph 0,0         to graph 1,(1.5/27.) @data_critical
set object 2 rectangle from graph 0,(1.5/27.) to graph 1,(2.5/27.) @data_warning
set object 3 rectangle from graph 0,(2.5/27.) to graph 1,(20./27.) @data_safe
set object 4 rectangle from graph 0,(20./27.) to graph 1,(25./27.) @data_warning
set object 5 rectangle from graph 0,(25./27.) to graph 1,1         @data_critical

do for [ns in CHILLERS] {
  n = ns+0   # A trick to force conversion to a number.
  set title  title( n )
  set output svgfile( n, "all" )
  set format x "%m/%d"        # Label format for x-axis
  set xlabel "Date"
  plot \
    datafile(n) using 1:7  with lines lw 1 lt  11 axes x1y1 title "* Circuit 1 liquid pressure (bar)", \
    datafile(n) using 1:9  with lines lw 1 lt  12 axes x1y1 title "* Circuit 1 suction pressure (bar)", \
    datafile(n) using 1:8  with lines lw 1 lt 121 axes x1y1 title "* Circuit 2 liquid pressure (bar)", \
    datafile(n) using 1:10 with lines lw 1 lt 122 axes x1y1 title "* Circuit 2 suction pressure (bar)", \
    datafile(n) using 1:2  with lines lw 1 lt 103 axes x1y2 title 'Ref.: Ambient Temperature  (°C)'
  set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "365d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "50d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "7d" )
  replot;
  set format x "%h"        # Label format for x-axis
  set xlabel "Time"
  set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "24u" )
  replot;
  unset xrange
}

unset object 1 ; unset object 2 ; unset object 3 ; unset object 4 ; unset object 5
unset y2label ; unset y2range ; unset y2tics

#########################################################################################################
#
# Compressor pressure raise
#
#########################################################################################################

set ylabel  "Compressor pressure raise (bar)"
set yrange  [0:20]
set y2label "Temperature (°C)"
set y2range [0:40]
set y2tics  numeric
svgfile( n, range ) = sprintf( "%s/chiller%02d-pressure-raise-%s.svg", webdir, n, range )
title(n)            = sprintf( "Chiller%02d Compressor pressure raise", n )

set object 1 rectangle from graph 0,0         to graph 1,(1./20.)  @data_critical
set object 2 rectangle from graph 0,(1./20.)  to graph 1,(3./20.)  @data_warning
set object 3 rectangle from graph 0,(3./20.)  to graph 1,(16./20.) @data_safe
set object 4 rectangle from graph 0,(16./20.) to graph 1,(18./20.) @data_warning
set object 5 rectangle from graph 0,(18./20.) to graph 1,1         @data_critical

do for [ns in CHILLERS] {
  n = ns+0   # A trick to force conversion to a number.
  set title  title( n )
  set output svgfile( n, "all" )
  set format x "%m/%d"        # Label format for x-axis
  set xlabel "Date"
  plot \
    datafile(n) using 1:($7-$9)   with lines lw 1 lt  11 axes x1y1 title "* Circuit 1 pressure raise", \
    datafile(n) using 1:($8-$10)  with lines lw 1 lt 121 axes x1y1 title "* Circuit 2 pressure raise", \
    datafile(n) using 1:2         with lines lw 1 lt 103 axes x1y2 title 'Ref.: Ambient Temperature'
  set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "365d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "50d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "7d" )
  replot;
  set format x "%h"        # Label format for x-axis
  set xlabel "Time"
  set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "24u" )
  replot;
  unset xrange
}

unset object 1 ; unset object 2 ; unset object 3 ; unset object 4 ; unset object 5
unset y2label ; unset y2range ; unset y2tics

#########################################################################################################
#
# Suction temperatures
#
#########################################################################################################

# CHILLERS = "4"
CHILLERS = ""

set ylabel "Temperature (°C)"
set yrange [0:35]
svgfile( n, range ) = sprintf( "%s/chiller%02d-suction-temp-%s.svg", webdir, n, range )
title(n)            = sprintf( "Chiller%02d Suction temperatures", n )

set object 3 rectangle from graph 0,0         to graph 1,(10./35.) @data_safe
set object 4 rectangle from graph 0,(10./35.) to graph 1,(12./35.) @data_warning
set object 5 rectangle from graph 0,(12./35.) to graph 1,1         @data_critical

do for [ns in CHILLERS] {
  n = ns+0   # A trick to force conversion to a number.
  set title  title( n )
  set output svgfile( n, "all" )
  set format x "%m/%d"        # Label format for x-axis
  set xlabel "Date"
  plot \
    datafile(n) using 1:11 with lines lw 1 lt  11 title "* Circuit 1 suction temperature", \
    datafile(n) using 1:12 with lines lw 1 lt  21 title "* Circuit 2 suction temperature", \
    datafile(n) using 1:4  with lines lw 1 lt 102 title 'Reference: Supply Water Temperature'
  set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "365d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "50d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "7d" )
  replot;
  set format x "%h"        # Label format for x-axis
  set xlabel "Time"
  set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "24u" )
  replot;
  unset xrange
}

unset object 3 ; unset object 4 ; unset object 5

#########################################################################################################
#
# Superheat
#
#########################################################################################################

set ylabel "Superheat (°C)"
set yrange [-5:25]
svgfile( n, range ) = sprintf( "%s/chiller%02d-superheat-%s.svg", webdir, n, range )
title(n)            = sprintf( "Chiller%02d Superheat", n )

set object 1 rectangle from graph 0,0         to graph 1,(6./30.)  @data_critical
set object 2 rectangle from graph 0,(6./30.)  to graph 1,(8./30.)  @data_warning
set object 3 rectangle from graph 0,(8./30.)  to graph 1,(20./30.) @data_safe
set object 4 rectangle from graph 0,(20./30.) to graph 1,1         @data_warning

do for [ns in CHILLERS] {
  n = ns+0   # A trick to force conversion to a number.
  set title  title( n )
  set output svgfile( n, "all" )
  set format x "%m/%d"        # Label format for x-axis
  set xlabel "Date"
  plot \
    datafile(n) using 1:13 with lines lw 1 lt 11 title "* Circuit 1 superheat", \
    datafile(n) using 1:14 with lines lw 1 lt 21 title "* Circuit 2 superheat"
  set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "365d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "50d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "7d" )
  replot;
  set format x "%h"        # Label format for x-axis
  set xlabel "Time"
  set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "24u" )
  replot;
  unset xrange
}

unset object 1 ; unset object 2 ; unset object 3 ; unset object 4

#########################################################################################################
#
# Chillers compared: Supply temperature
#
#########################################################################################################

# set ylabel "Supply temperature (°C)"
# set yrange [7:15]
# svgfile( range ) = sprintf( "%s/chillers-supply-temp-%s.svg", webdir, range )
# set title "Supply temperature
# set key left bottom            # Set the graph legend position
# 
# set output svgfile( "all" )
# set format x "%m/%d"        # Label format for x-axis
# set xlabel "Date"
# plot \
#   datafile(1) using 1:4 with lines lw 1 lt   2 title "Chiller01", \
#   datafile(2) using 1:4 with lines lw 1 lt 101 title "Chiller02", \
#   datafile(4) using 1:4 with lines lw 1 lt 103 title "Chiller04"
# set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
# set output svgfile( "365d" )
# replot;
# set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
# set output svgfile( "50d" )
# replot;
# set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
# set output svgfile( "7d" )
# replot;
# set format x "%h"        # Label format for x-axis
# set xlabel "Time"
# set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
# set output svgfile( "24u" )
# replot;
# unset xrange



#########################################################################################################
#########################################################################################################
#
# Plots for the coolers
#
#########################################################################################################
#########################################################################################################

datafile(n) = sprintf( "%s/cooler%02d.data", datadir, n )
COOLERS = "1 2"

#########################################################################################################
#
# Temperatures and valve position
#
#########################################################################################################

set yrange  [0:52.5]
set y2range [0:105]
set ylabel  "temperature (°C)"
set y2label "percentage (%)"
set y2tics  numeric
svgfile( n, range ) = sprintf( "%s/cooler%02d-%s.svg", webdir, n, range )
title(n)            = sprintf( "Cooler%02d Temperatures (degC) and CW valve position (%)", n )

do for [ns in COOLERS] {
  n = ns+0   # A trick to force conversion to a number.
  set title  title( n )
  set output svgfile( n, "all" )
  set format x "%m/%d"        # Label format for x-axis
  set xlabel "Date"
  plot \
    datafile(n) using 1:2 with lines lw 1 lt 1 axes x1y1 title 'Return Air Temperature (°C)', \
    datafile(n) using 1:4 with lines lw 1 lt 3 axes x1y1 title 'Supply Air Temperature (°C)', \
    datafile(n) using 1:7 with lines lw 1 lt 4 axes x1y1 title 'Inlet Water Temperature (°C)', \
    datafile(n) using 1:9 with lines lw 1 lt 5 axes x1y2 title 'CW Valve Position (%)'
  set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "365d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "50d" )
  replot;
  set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "7d" )
  replot;
  set format x "%h"        # Label format for x-axis
  set xlabel "Time"
  set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
  set output svgfile( n, "24u" )
  replot;
  unset xrange
}

unset y2range ; unset y2label ; unset y2tics


#########################################################################################################
#
# Coolers compared: Supply temperature
#
#########################################################################################################

set yrange  [10:40]
set ylabel  "temperature (°C)"
svgfile( range ) = sprintf( "%s/coolers-supply-temp-%s.svg", webdir, range )
set title          "Coolers: Supply temperature (degC)"

set object 1 rectangle from graph 0,0          to graph 1,(17./30.)  @data_safe
set object 2 rectangle from graph 0,(17./30.)  to graph 1,(19./30.)  @data_warning
set object 3 rectangle from graph 0,(19./30.)  to graph 1,1          @data_critical


set output svgfile( "all" )
set format x "%m/%d"        # Label format for x-axis
set xlabel "Date"
plot \
  datafile(1) using 1:4 with lines lw 1 lt   2 title 'cooler01', \
  datafile(2) using 1:4 with lines lw 1 lt 101 title 'cooler02'
set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "365d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "50d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "7d" )
replot;
set format x "%h"        # Label format for x-axis
set xlabel "Time"
set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "24u" )
replot;
unset xrange
unset object 1; unset object 2; unset object 3


#########################################################################################################
#
# Coolers compared: Return temperature
#
#########################################################################################################

set yrange  [20:50]
set ylabel  "temperature (°C)"
svgfile( range ) = sprintf( "%s/coolers-return-temp-%s.svg", webdir, range )
set title          "Coolers: Return temperature (degC)"

set object 1 rectangle from graph 0,0          to graph 1,(22./30.)  @data_safe
set object 2 rectangle from graph 0,(22./30.)  to graph 1,(25./30.)  @data_warning
set object 3 rectangle from graph 0,(25./30.)  to graph 1,1          @data_critical


set output svgfile( "all" )
set format x "%m/%d"        # Label format for x-axis
set xlabel "Date"
plot \
  datafile(1) using 1:2 with lines lw 1 lt   2 title 'cooler01', \
  datafile(2) using 1:2 with lines lw 1 lt 101 title 'cooler02'
set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "365d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "50d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "7d" )
replot;
set format x "%h"        # Label format for x-axis
set xlabel "Time"
set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "24u" )
replot;
unset xrange
unset object 1; unset object 2; unset object 3


#########################################################################################################
#
# Coolers compared: Inlet water temperature
#
#########################################################################################################

set yrange  [5:20]
set ylabel  "temperature (°C)"
svgfile( range ) = sprintf( "%s/coolers-inlet-temp-%s.svg", webdir, range )
set title          "Coolers: Inlet water temperature (degC)"

set object 1 rectangle from graph 0,0         to graph 1,(3./15.)  @data_critical
set object 2 rectangle from graph 0,(3./15.)  to graph 1,(5./15.)  @data_warning
set object 3 rectangle from graph 0,(5./15.)  to graph 1,(10./15.) @data_safe
set object 4 rectangle from graph 0,(10./15.) to graph 1,(12./15.) @data_warning
set object 5 rectangle from graph 0,(12./15.) to graph 1,1         @data_critical


set output svgfile( "all" )
set format x "%m/%d"        # Label format for x-axis
set xlabel "Date"
plot \
  datafile(1) using 1:7 with lines lw 1 lt   2 title 'cooler01', \
  datafile(2) using 1:7 with lines lw 1 lt 101 title 'cooler02'
set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "365d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "50d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "7d" )
replot;
set format x "%h"        # Label format for x-axis
set xlabel "Time"
set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "24u" )
replot;
unset xrange
unset object 1; unset object 2; unset object 3; unset object 4; unset object 5


#########################################################################################################
#########################################################################################################
#
# Plots for the Air Handling Units
#
#########################################################################################################
#########################################################################################################

datafile(n) = sprintf( "%s/ahu%02d.data", datadir, n )

#########################################################################################################
#
# Return temperature
#
#########################################################################################################

set ylabel "Return temperature (°C)"
set yrange [10:35]
set title "AHU Return temperature"
svgfile( range ) = sprintf( "%s/ahu-return-temp-%s.svg", webdir, range )

set output svgfile( "all" )
set format x "%m/%d"        # Label format for x-axis
set xlabel "Date"
plot \
  datafile(3) using 1:2 with lines lw 1 lt 3 title 'AHU 3', \
  datafile(4) using 1:2 with lines lw 1 lt 4 title 'AHU 4', \
  datafile(5) using 1:2 with lines lw 1 lt 5 title 'AHU 5'
set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "365d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "50d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "7d" )
replot;
set format x "%h"        # Label format for x-axis
set xlabel "Time"
set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "24u" )
replot;
unset xrange


#########################################################################################################
#
# Supply temperature
#
#########################################################################################################

set ylabel "Supply temperature (°C)"
set yrange [10:35]
set title "AHU Supply temperature"
svgfile( range ) = sprintf( "%s/ahu-supply-temp-%s.svg", webdir, range )

set output svgfile( "all" )
set format x "%m/%d"        # Label format for x-axis
set xlabel "Date"
plot \
  datafile(3) using 1:4 with lines lw 1 lt 3 title 'AHU 3', \
  datafile(4) using 1:4 with lines lw 1 lt 4 title 'AHU 4', \
  datafile(5) using 1:4 with lines lw 1 lt 5 title 'AHU 5'
set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "365d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "50d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "7d" )
replot;
set format x "%h"        # Label format for x-axis
set xlabel "Time"
set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "24u" )
replot;
unset xrange


#########################################################################################################
#
# Valve status (Cooling 0-10vdc)
#
#########################################################################################################

set ylabel "Supply temperature (°C)"
set yrange [-0.5:10.5]
set title "AHU cooling 0-10vdc"
svgfile( range ) = sprintf( "%s/ahu-valve-%s.svg", webdir, range )

set output svgfile( "all" )
set format x "%m/%d"        # Label format for x-axis
set xlabel "Date"
plot \
  datafile(3) using 1:6 with lines lw 1 lt 3 title 'AHU 3', \
  datafile(4) using 1:6 with lines lw 1 lt 4 title 'AHU 4', \
  datafile(5) using 1:6 with lines lw 1 lt 5 title 'AHU 5'
set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "365d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "50d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "7d" )
replot;
set format x "%h"        # Label format for x-axis
set xlabel "Time"
set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "24u" )
replot;
unset xrange


#########################################################################################################
#
# Return humidity
#
#########################################################################################################

set ylabel "Return humidity (%)"
set yrange [0:100]
set title "AHU Return humidity"
svgfile( range ) = sprintf( "%s/ahu-return-hum-%s.svg", webdir, range )

set output svgfile( "all" )
set format x "%m/%d"        # Label format for x-axis
set xlabel "Date"
plot \
  datafile(3) using 1:3 with lines lw 1 lt 3 title 'AHU 3', \
  datafile(4) using 1:3 with lines lw 1 lt 4 title 'AHU 4', \
  datafile(5) using 1:3 with lines lw 1 lt 5 title 'AHU 5'
set xrange [ ((GPVAL_DATA_X_MAX-365*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-365*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "365d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-50*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-50*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "50d" )
replot;
set xrange [ ((GPVAL_DATA_X_MAX-7*24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-7*24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "7d" )
replot;
set format x "%h"        # Label format for x-axis
set xlabel "Time"
set xrange [ ((GPVAL_DATA_X_MAX-24*3600 > GPVAL_DATA_X_MIN) ? GPVAL_DATA_X_MAX-24*3600 : GPVAL_DATA_X_MIN ) : GPVAL_DATA_X_MAX]
set output svgfile( "24u" )
replot;
unset xrange


