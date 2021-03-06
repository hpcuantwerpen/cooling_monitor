package DEVICE::coolerAD;

use parent 'DEVICE::generic';
use DEVICE::deviceHelpers qw(RangeCheck);

use IO::File;
use Net::SNMP;
use POSIX qw(strftime);
use Try::Tiny;

#use Data::Dumper qw(Dumper);

# $description is a reference to an anonymous hash table...
# Note range field analog variables: CriticalAlarm Range[0] SoftAlarm Range[1] OK Range[2] Softalarm Range[3] CriticalAlarm
$description = {
  'digital' => { 
     11 => { info =>  'liquid pressure probe alarm',                                                type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     12 => { info =>  'return air humidity probe alarm',                                            type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     13 => { info =>  'supply air temperature probe alarm',                                         type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     14 => { info =>  'return air temperature probe alarm',                                         type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     15 => { info =>  'differential pressure probe alarm',                                          type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     16 => { info =>  'discharge line temperature probe alarm - fixed speed',                       type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     17 => { info =>  'liquid line temp probe alarm',                                               type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     18 => { info =>  'aisle pressure probe alarm',                                                 type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     19 => { info =>  'discharge line temperature probe alarm - inverter',                          type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     21 => { info =>  'alarm - backup power supply active',                                         type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     22 => { info =>  'refrig leak detected - alarm indication only - not used for alarm response', type => 'SoftAlarm',     value => ['No alarm', 'Alarm'], remark => '' },
     23 => { info =>  'high pressure alarm',                                                        type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     26 => { info =>  'specify if master offline',                                                  type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     31 => { info =>  'fan motor trip alarm',                                                       type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     35 => { info =>  'fire smoke detection alarm',                                                 type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     36 => { info =>  'water condensate pump status alarm',                                         type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     37 => { info =>  'water leak detection alarm',                                                 type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     54 => { info =>  'filter running hours - maintenance alarm',                                   type => 'NoAlarm',       value => ['No alarm', 'Alarm'], remark => '' }, # Set to NoAlarm since it is always on.
     55 => { info =>  'high humidity alarm',                                                        type => 'SoftAlarm',     value => ['No alarm', 'Alarm'], remark => '' },
     56 => { info =>  'low humidity alarm',                                                         type => 'NoAlarm',       value => ['No alarm', 'Alarm'], remark => '' }, # Set to NoAlarm since it is always on.
     57 => { info =>  'high return temp alarm',                                                     type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     58 => { info =>  'low return temp alarm',                                                      type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     59 => { info =>  'high supply temp alarm',                                                     type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     60 => { info =>  'low supply temp alarm',                                                      type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     73 => { info =>  'inlet water temp probe alarm',                                               type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     74 => { info =>  'inlet water temp circuit 1 probe alarm',                                     type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     75 => { info =>  'inlet water temp circuit 2 probe alarm',                                     type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     76 => { info =>  'inlet water temperature alarm',                                              type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     77 => { info =>  'inlet water temperature CCT2 alarm',                                         type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     78 => { info =>  'air flow fail alarm',                                                        type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     79 => { info =>  'Airflow_Trip_Count_Critical',                                                type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
     80 => { info =>  'BMS digital parameter sychronisation point',                                 type => 'NoAlarm',       value => ['Not OK', 'OK'],      remark => '' },
     81 => { info =>  'selected air temperature regulation',                                        type => 'NoAlarm',       value => ['Return', 'Supply'],  remark => '' },
    113 => { info =>  'selected air temperature regulation U1',                                     type => 'NoAlarm',       value => ['Return', 'Supply'],  remark => '' },
    114 => { info =>  'selected air temperature regulation U2',                                     type => 'NoAlarm',       value => ['Return', 'Supply'],  remark => '' },
    115 => { info =>  'selected air temperature regulation U3',                                     type => 'NoAlarm',       value => ['Return', 'Supply'],  remark => '' },
    116 => { info =>  'selected air temperature regulation U4',                                     type => 'NoAlarm',       value => ['Return', 'Supply'],  remark => '' },
    117 => { info =>  'selected air temperature regulation U5',                                     type => 'NoAlarm',       value => ['Return', 'Supply'],  remark => '' },
    118 => { info =>  'selected air temperature regulation U6',                                     type => 'NoAlarm',       value => ['Return', 'Supply'],  remark => '' },
    119 => { info =>  'selected air temperature regulation U7',                                     type => 'NoAlarm',       value => ['Return', 'Supply'],  remark => '' },
    120 => { info =>  'selected air temperature regulation U8',                                     type => 'NoAlarm',       value => ['Return', 'Supply'],  remark => '' },
    121 => { info =>  'refig leak detected input',                                                  type => 'CriticalAlarm', value => ['No alarm', 'Alarm'], remark => '' },
    122 => { info =>  'humidifier running hours - maintenance alarm',                               type => 'SoftAlarm',     value => ['No alarm', 'Alarm'], remark => '' },
    123 => { info =>  'close the water regulating valve if water leak detected',                    type => 'NoAlarm',       value => ['No', 'Yes'],         remark => '' },
    124 => { info =>  'Al_CLock',                                                                   type => 'SoftAlarm',     value => ['No alarm', 'Alarm'], remark => '' },
    125 => { info =>  'fan 1 motor trip alarm',                                                     type => 'SoftAlarm',     value => ['No alarm', 'Alarm'], remark => '' },
    126 => { info =>  'fan 2 motor trip alarm',                                                     type => 'SoftAlarm',     value => ['No alarm', 'Alarm'], remark => '' },
    127 => { info =>  'fan 3 motor trip alarm',                                                     type => 'SoftAlarm',     value => ['No alarm', 'Alarm'], remark => '' },
    128 => { info =>  'fan 4 motor trip alarm',                                                     type => 'SoftAlarm',     value => ['No alarm', 'Alarm'], remark => '' },
    131 => { info =>  'refrig leak detected on unit and not set to alarm only response',            type => 'SoftAlarm',     value => ['No alarm', 'Alarm'], remark => '' },
    132 => { info =>  'state of pCO clock',                                                         type => 'NoAlarm',       value => ['Disabled', 'Enabled'], remark => '' },
    154 => { info =>  'cooling active',                                                             type => 'NoAlarm',       value => ['No', 'Yes'],         remark => '' },
    155 => { info =>  'cooling possible',                                                           type => 'NoAlarm',       value => ['No', 'Yes'],         remark => '' },
    156 => { info =>  'CPY board in alarm',                                                         type => 'SoftAlarm',     value => ['No alarm', 'Alarm'], remark => '' },
    157 => { info =>  'critical alarm active',                                                      type => 'CriticalAlarm', value => ['Return', 'Supply'],  remark => '' }
    } ,
  'analog' => {
      2 => { info => 'evaporator fan speed ',                                    unit => '%',     remark => '??? Do we have an evaporator?' },
      4 => { info => 'regulation control temperature',                           unit => 'ºC',    remark => '' }, 
      6 => { info => "Temperature regulation set point",                         unit => 'ºC',    remark => '????' },
     20 => { info => 'HP fan min speed',                                         unit => '%',     remark => '' },
     21 => { info => 'HP fan max speed',                                         unit => '%',     remark => '' },
     22 => { info => 'head pressure setpoint',                                   unit => 'bar',   remark => 'Possibly something else...' },
     29 => { info => 'return air humidiy - abs or rel depending on selection',   unit => '%',     remark => '' },
     33 => { info => 'inlet water temperature ',                                 unit => 'ºC',    range => [  8, 10, 15, 17 ], remark => '' },
     34 => { info => 'return air humidity ',                                     unit => '%RH',   remark => '' },
     35 => { info => 'return air temperature ',                                  unit => 'ºC',    range => [  5, 10, 42, 45 ], remark => 'Hot aisle' },
     36 => { info => 'supply air temperature ',                                  unit => 'ºC',    range => [  5, 10, 27, 29 ], remark => 'Room, controlled by set point' },
     37 => { info => 'differential pressure',                                    unit => 'bar',   remark => '' },
     38 => { info => 'dewpoint chiller SP',                                      unit => 'ºC',    remark => '' },
     39 => { info => 'aisle differential pressure ',                             unit => 'Pa',    remark => '' },
     40 => { info => 'supply/return air temp sensor from pCO B9',                unit => 'ºC',    remark => '' },
     44 => { info => 'CW valve position ',                                       unit => '%',     remark => '' },
     48 => { info => 'Temperature set point',                                    unit => 'ºC',    remark => '' },
     49 => { info => 'humidity set point',                                       unit => '%',     remark => '' },
     51 => { info => 'SET_TEMP1',                                                unit => 'ºC',    remark => '' },
     52 => { info => 'SET_TEMP2',                                                unit => 'ºC',    remark => '' },
     53 => { info => 'SET_TEMP3',                                                unit => 'ºC',    remark => '' },
     54 => { info => 'SET_TEMP4',                                                unit => 'ºC',    remark => '' },
     55 => { info => 'control humidity',                                         unit => '%rH',   remark => '' },
     58 => { info => 'maximum network control temperature',                      unit => 'ºC',    remark => '' },
     59 => { info => 'Return air humidity - absolute value',                     unit => '',      remark => '' },
     73 => { info => 'analog input B1',                                          unit => '',      remark => '' },
     74 => { info => 'analog input 10 maximum value',                            unit => '',      remark => '' },
     75 => { info => 'analog input 10 minimum value',                            unit => '',      remark => '' },
     76 => { info => 'analog input 1a maximum value',                            unit => '',      remark => '' },
     77 => { info => 'analog input 1a minimum value',                            unit => '',      remark => '' },
     78 => { info => 'analog input 1b maximum value',                            unit => '',      remark => '' },
     79 => { info => 'analog input 1b minimum value',                            unit => '',      remark => '' },
     80 => { info => 'BMS analogue parameter synchronisation point',             unit => '',      remark => 'Normal value is 464.8', },
     81 => { info => 'analog input 2a maximum value',                            unit => '',      remark => '' },
     82 => { info => 'analog input 2a minimum value',                            unit => '',      remark => '' },
     83 => { info => 'analog input 2b maximum value',                            unit => '',      remark => '' },
     84 => { info => 'analog input 2b minimum value',                            unit => '',      remark => '' },
     85 => { info => 'analog input 2c maximum value',                            unit => '',      remark => '' },
     86 => { info => 'analog input 2c minimum value',                            unit => '',      remark => '' },
     87 => { info => 'analog input B3',                                          unit => 'ppm',   remark => '' },
     88 => { info => 'analog input 3 maximum value',                             unit => '',      remark => '' },
     89 => { info => 'analog input 3 minimum value',                             unit => '',      remark => '' },
     90 => { info => 'analog input B4',                                          unit => 'ºC',    remark => '' },
     91 => { info => 'analog input 4 maximum value',                             unit => '',      remark => '' },
     92 => { info => 'analog input 4 minimum value',                             unit => '',      remark => '' },
     93 => { info => 'analog input B5',                                          unit => 'ºC',    remark => '' },
     94 => { info => 'analog input 5 maximum value',                             unit => '',      remark => '' },
     95 => { info => 'analog input 5 minimum value',                             unit => '',      remark => '' },
     96 => { info => 'analog input B6',                                          unit => '',      remark => '' },
     97 => { info => 'analog input 6 maximum value',                             unit => '',      remark => '' },
     98 => { info => 'analog input 6 minimum value',                             unit => '',      remark => '' },
     99 => { info => 'analog input B7',                                          unit => '',      remark => '' },
    100 => { info => 'analog input 7 maximum value',                             unit => '',      remark => '' },
    101 => { info => 'analog input 7 minimum value',                             unit => '',      remark => '' },
    102 => { info => 'analog input B8',                                          unit => '',      remark => '' },
    103 => { info => 'analog input 8 maximum value',                             unit => '',      remark => '' },
    104 => { info => 'analog input 8 minimum value',                             unit => '',      remark => '' },
    105 => { info => 'analog input B9',                                          unit => 'ºC',    remark => '' },
    106 => { info => 'analog input 9 maximum value',                             unit => '',      remark => '' },
    107 => { info => 'analog input 9 minimum value',                             unit => '',      remark => '' },
    108 => { info => 'Air Flow Input',                                           unit => '',      remark => 'Different from sheet' },
    109 => { info => 'AV 109 (Air_set)',                                         unit => '',      remark => 'Meaning unclear' },
    110 => { info => 'AV 110 (Air_Vol_Time_Step)',                               unit => '',      remark => 'Meaning unclear' },
    111 => { info => 'AV 111 (Air_Vol_Volt_Step)',                               unit => '',      remark => 'Meaning unclear' },
    112 => { info => 'Airflow alarm differential',                               unit => '',      remark => 'Meaning unclear' },
    113 => { info => 'Airflow alarm setpoint',                                   unit => '',      remark => 'Meaning unclear' },
    114 => { info => 'AV 114 (AirFlow_Band_H)',                                  unit => '',      remark => 'Meaning unclear' },
    115 => { info => 'AV 115 (AirFLow_Band_L)',                                  unit => '',      remark => 'Meaning unclear' },
    116 => { info => 'Aisle maximum differential pressure limit',                unit => '',      remark => 'Meaning unclear' },
    117 => { info => 'Aisle minimum differential pressure limit',                unit => '',      remark => 'Meaning unclear' },
    118 => { info => 'Differential pressure regulation setpoint - dx units',     unit => '',      remark => 'Meaning unclear' },
    119 => { info => 'Aisle differential pressure setpoint',                     unit => '',      remark => 'Meaning unclear' },
    120 => { info => 'ambient temperature differential',                         unit => '',      remark => 'Meaning unclear' },
    122 => { info => "AV 122 (Aout_1)",                                          unit => '',      remark => '????' },
    124 => { info => "AV 124 (Aout_3)",                                          unit => '',      remark => '????' },
    129 => { info => 'Analogue output Y1',                                       unit => '',      remark => '???' },
    131 => { info => 'Analogue output Y3',                                       unit => '',      remark => '???' },
    134 => { info => 'AV 134 (Chiller_Max_Temp)',                                unit => '',      remark => '???' },
    135 => { info => 'AV 135 (Chiuller_Min_Temp)',                               unit => '',      remark => '???' },
    139 => { info => "AV 139 (Max_Hum)",                                         unit => '',      remark => '????' },
    141 => { info => 'AV 141 (Diff_Water_Temp)',                                 unit => '',      remark => '' },
    146 => { info => 'Max limit unit control hum is allowed to go below the maximum network hum before switching to standalone',   unit => '%',  remark => '???' },
    147 => { info => 'Maximum unit control hum is allowed to go below the average before switching to standalone',                 unit => '%',  remark => '???' },
    148 => { info => 'Maximum unit control hum is allowed to go above the average before switching to standalone',                 unit => '%',  remark => '???' },
    149 => { info => 'Max limit unit control temp is allowed to go below the maximum network temp before switching to standalone', unit => 'ºC', remark => '???' },
    150 => { info => 'Maximum unit control temp is allowed to go below the average before switching to standalone',                unit => 'ºC', remark => '???' },
    151 => { info => 'Maximum unit control temp is allowed to go above the average before switching to standalone',                unit => 'ºC', remark => '???' },
    152 => { info => 'selected unit control temp (return air or supply air)',     unit => 'ºC',    remark => '' },
    153 => { info => 'return air temperature from pCO',                           unit => 'ºC',    remark => '' },
    155 => { info => 'supply air temperature from pCO',                           unit => 'ºC',    remark => '' },
    157 => { info => 'maximum unir return air control temp - form pCO and pCOe',  unit => 'ºC',    remark => '' },
    159 => { info => "MAximum degrees evap temp can be below dew point temp during normal operation",                              unit => '',    remark => '????' },
    160 => { info => "Evaporation temperature setpoint if return temp hum alarm occurs",                                           unit => '',    remark => '????' },
    161 => { info => "Max. increase speed rte (goingto target speed in defrost)", unit => 'rps/s', remark => '????' },
    164 => { info => "AV 164 (Diff_Dehumid)",                                     unit => '',      remark => '????' },
    165 => { info => "AV 165 (Diff_Humid)",                                       unit => '',      remark => '????' },
    166 => { info => "AV 166 (Force_Diff_Low)",                                   unit => '',      remark => '????' },
    167 => { info => "AV 167 (Force_Low)",                                        unit => '',      remark => '????' },
    168 => { info => "AV 168 (Force_Diff_high)",                                  unit => '',      remark => '????' },
    169 => { info => "AV 169 (Diff_High)",                                        unit => '',      remark => '????' },
    170 => { info => "AV 170 (lim_max_set_h)",                                    unit => '',      remark => '????' },
    171 => { info => "AV 171 (lim_min_set_h)",                                    unit => '',      remark => '????' },
    172 => { info => "AV 172 (lim_max_set_t)",                                    unit => '',      remark => '????' },
    173 => { info => "AV 173 (lim_min_set_t)",                                    unit => '',      remark => '????' },
    174 => { info => 'humidity regulation setpoint',                              unit => '',      remark => '' },
    175 => { info => 'SET_HUMID4',                                                unit => '',      remark => '' },
    176 => { info => 'SET_HUMID3',                                                unit => '',      remark => '' },
    177 => { info => 'SET_HUMID2',                                                unit => '',      remark => '' },
    178 => { info => 'SET_HUMID1',                                                unit => '',      remark => '' },
    180 => { info => 'offset for analogue input B1',                              unit => '',      remark => '' },
    181 => { info => 'offset for analogue input B2',                              unit => '',      remark => '' },
    182 => { info => 'offset for analogue input B3',                              unit => '',      remark => '' },
    183 => { info => 'offset for analogue input B4',                              unit => '',      remark => '' },
    184 => { info => 'offset for analogue input B5',                              unit => '',      remark => '' },
    185 => { info => "High discharge temperature limit for alarm",                unit => '',      remark => '????' },
    186 => { info => "AV 186 (SET_COND2)",                                        unit => '',      remark => '????' },
    187 => { info => "AV 187 (lim_max_set_cd)",                                   unit => '',      remark => '????' },
    188 => { info => "AV 188 (lim_min_set_cd)",                                   unit => '',      remark => '????' },
    189 => { info => "AV 189 (SET_COND1)",                                        unit => '',      remark => '????' },
    190 => { info => "AV 190 (SET_COND4)",                                        unit => '',      remark => '????' },
    191 => { info => "AV 191 (SET_COND3)",                                        unit => '',      remark => '????' },
    196 => { info => 'Fan demand when liquid pressure sensor fails',              unit => '',      remark => '' },
    197 => { info => "High discharge temperature warning limit for alarm",        unit => '',      remark => '????' },
    198 => { info => "AV 198 (HP_Fan_Band)",                                      unit => '',      remark => '????' },
    199 => { info => "AV 199 (DIFF_HP_COND)",                                     unit => '',      remark => '????' },
    200 => { info => "AV 200 (SET_HP_COND)",                                      unit => '',      remark => '????' },
    201 => { info => "AV 201 (High_Dis_Temp_Diff)",                               unit => '',      remark => '????' },
    202 => { info => "AV 202 (HP_Max_Speed_Setp)",                                unit => '',      remark => '????' },
    203 => { info => "AV 203 (HP_Max_Speed_Diff)",                                unit => '',      remark => '????' },
    204 => { info => "Fan Speed Limit During Night Setback",                      unit => '%',     remark => '????' },
    205 => { info => "Liquid pressure converted to temperature",                  unit => 'ºC',    remark => '????' },
    206 => { info => "Pump down end treshold",                                    unit => 'barg',  remark => '????' }
    },
  'integer' => { 
      1 => { info => 'current hour',                                   unit => 'h',    remark => '' },
      3 => { info => 'current minute',                                 unit => 'm',    remark => '' },
      5 => { info => 'current day',                                    unit => '',     remark => '' },
      7 => { info => 'current month',                                  unit => '',     remark => '' },
      9 => { info => 'current year',                                   unit => '',     remark => '' },
     11 => { info => 'current day of week',                            unit => '',     remark => '1 - 7,Monday = 1' },
  	 15 => { info => 'application type',                               unit => '',     remark => '' },
  	 19 => { info => 'BMS baus rate',                                  unit => '',     remark => '' },
  	 24 => { info => 'state of unit',                                  unit => '',     remark => '' },
  	 34 => { info => 'status of fan 1',                                unit => '',     remark => '0: off, 1: on, 2: alarm' },
  	 35 => { info => 'status of fan 2',                                unit => '',     remark => '0: off, 1: on, 2: alarm' },
  	 36 => { info => 'status of fan 3',                                unit => '',     remark => '0: off, 1: on, 2: alarm' },
  	 37 => { info => 'status of fan 4',                                unit => '',     remark => '0: off, 1: on, 2: alarm' },
  	 38 => { info => 'air volume high value',                          unit => '',     remark => '' },
  	 39 => { info => 'air volume low value',                           unit => '',     remark => '' },
  	 51 => { info => 'number of network units with usable control humidity readings', unit => '',    remark => '' },
  	 59 => { info => 'Airflow_Set_H_Inv',                                             unit => '',    remark => '' },
  	 60 => { info => 'Airflow_Set_H_Inv',                                             unit => '',    remark => '' },
  	 61 => { info => 'analogue input 10 sensor type',                  unit => '',     remark => '' },
  	 62 => { info => 'analogue input 1a sensor type',                  unit => '',     remark => '' },
  	 63 => { info => 'analogue input 1b sensor type',                  unit => '',     remark => '' },
  	 64 => { info => 'analogue input 2a sensor type',                  unit => '',     remark => '' },
  	 65 => { info => 'analogue input 2b sensor type',                  unit => '',     remark => '' },
  	 66 => { info => 'analogue input 2b sensor type',                  unit => '',     remark => '' },
  	 67 => { info => 'analogue input 3 sensor type',                   unit => '',     remark => '' },
  	 68 => { info => 'analogue input 4 sensor type',                   unit => '',     remark => '' },
  	 69 => { info => 'analogue input 5 sensor type',                   unit => '',     remark => '' },
  	 70 => { info => 'analogue input 6 sensor type',                   unit => '',     remark => '' },
  	 71 => { info => 'analogue input 7 sensor type',                   unit => '',     remark => '' },
  	 72 => { info => 'analogue input 8 sensor type',                   unit => '',     remark => '' },
  	 73 => { info => 'analogue input 9 sensor type',                   unit => '',     remark => '' },
   	 80 => { info => 'transmission test variable',                     unit => '',     remark => 'Should be 4648' },
   	 81 => { info => 'airflow integral value',                         unit => '',     remark => '' },
   	 82 => { info => 'Airflow_Set_H',                                  unit => '',     remark => '' },
   	 83 => { info => 'Airflow_Set_H_Inv_SP',                           unit => '',     remark => '' },
   	 84 => { info => 'Airflow_Set_L',                                  unit => '',     remark => '' },
   	 85 => { info => 'Airflow_Set_L_Inv_SP',                           unit => '',     remark => '' },
   	 86 => { info => 'aisle pressure ramping decrease time (time to go from 1000 to 0)', unit => '',    remark => '' },
   	 87 => { info => 'aisle pressure ramping Increase time (time to go from 0 to 1000)', unit => '',    remark => '' },
   	105 => { info => 'leak detector response menu options',            unit => '',     remark => '0=alarm only, 1=alarm+shutdown, 2=alarm+pumpdown to outdoor coil' },
   	133 => { info => 'actual current temp control mode',               unit => '',     remark => '0=Standalone 1=Average 2=Maximum' },
   	144 => { info => 'Atmospheric pressure at current location',       unit => 'mbar', remark => 'required to calculate moisture content (absolute humidity' },
   	183 => { info => 'bios day',                                       unit => '',     remark => '' },
   	184 => { info => 'bios month',                                     unit => '',     remark => '' },
   	185 => { info => 'boot day',                                       unit => '',     remark => '' },
   	186 => { info => 'bios year',                                      unit => '',     remark => '' },
   	187 => { info => 'boot month',                                     unit => '',     remark => '' },
   	188 => { info => 'boot year',                                      unit => '',     remark => '' },
   	189 => { info => 'high part of bios version number',               unit => '',     remark => '' },
   	190 => { info => 'high part of boot version number',               unit => '',     remark => '' },
   	191 => { info => 'high part of software version number',           unit => '',     remark => '' },
   	192 => { info => 'low part of bios version number',                unit => '',     remark => '' },
   	193 => { info => 'low part of boot version number',                unit => '',     remark => '' },
   	194 => { info => 'low part of software version number',            unit => '',     remark => '' },
   	195 => { info => 'software month',                                 unit => '',     remark => '' },
   	196 => { info => 'software day',                                   unit => '',     remark => '' },
   	197 => { info => 'software beta',                                  unit => '',     remark => '' },
   	198 => { info => 'software year',                                  unit => '',     remark => '' },
    203 => { info => "???",                                            unit => '',     remark => '????' },
    204 => { info => "???",                                            unit => '',     remark => '????' },
    205 => { info => "???",                                            unit => '',     remark => '????' },
    206 => { info => "???",                                            unit => '',     remark => '????' },
    207 => { info => "???",                                            unit => '',     remark => '????' }
    },
  'computed' => {
     1 => { info => 'Temperature sensor 1', type => 'D', unit => 'ºC', remark => '' },
     2 => { info => 'Temperature sensor 2', type => 'D', unit => 'ºC', remark => '' },
    11 => { info => 'BIOS version',         type => 'S', unit => '',   remark => '' },
    12 => { info => 'Boot version',         type => 'S', unit => '',   remark => '' },
    13 => { info => 'Software version',     type => 'S', unit => '',   remark => '' },
    } 
  };

$OIDbase = "1.3.6.1.4.1.9839.2.1.";
$OIDdigital = "1.";
$OIDanalog  = "2.";
$OIDinteger = "3.";
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

	my $cooler_ip = $_[0];
	my $label     = $_[1];

    my $self = {
      'ip'          => $cooler_ip, 
      'label'       => $label,
      'description' => $description,
      'valid'       => 1,             # This object contains valid data.
      'digital'     => { },
      'analog'      => { },
      'integer'     => { }
      };

    try {
    	
    	# Open the SNMP-session
    	my ($session, $error) = Net::SNMP->session(
                 -hostname  => $cooler_ip,
                 -community => 'public',
                 -port      => 161,
                 -timeout   => 1,
                 -retries   => 3,
    			 -debug		=> 0x0,
    			 -version	=> 2,
                 -translate => [-timeticks => 0x0] 
    	         );
    
        # Read the keys, first the digital ones then the analog ones.
        foreach my $mykey ( sort keys %{ $description->{'digital'} } ) 
        { 
    	    my $oid = $OIDbase.$OIDdigital.$mykey.".0";
    	    my $result = $session->get_request( $oid )
                or die "SNMP service $oid is not available on the SNMP server $cooler_ip.\n";
            $self->{'digital'}{$mykey}{'value'} = $result->{$oid};       
            # print ( "Digital key ", $mykey, " has value ", $self->{'digital'}{$mykey}{'value'}, "\n" );
        }
    
        foreach my $mykey ( sort keys %{ $description->{'analog'} } ) 
        { 
        	my $oid = $OIDbase.$OIDanalog.$mykey.".0";
    	    my $result = $session->get_request( $oid )
                or die "SNMP service $oid is not available on the SNMP server $cooler_ip.\n";
            $self->{'analog'}{$mykey}{'value'} = $result->{$oid} / 10.; 
            if ( exists( $description->{'analog'}{$mykey}{'range'} ) ) { 
                $self->{'analog'}{$mykey}{'status'} = DEVICE::deviceHelpers::RangeCheck( $self->{'analog'}{$mykey}{'value'}, $description->{'analog'}{$mykey}{'range'} ); 
            }     
                  
        	# print ( "Analog key ", $mykey, " has value ", $self->{'analog'}{$mykey}{'value'}, "\n" );
        }
    
        foreach my $mykey ( sort keys %{ $description->{'integer'} } ) 
        { 
        	my $oid = $OIDbase.$OIDinteger.$mykey.".0";
    	    my $result = $session->get_request( $oid )
    	        or die "SNMP service $oid is not available on the SNMP server $cooler_ip.\n";
            $self->{'integer'}{$mykey}{'value'} = $result->{$oid};       
        	# print ( "Integer key ", $mykey, " has value ", $self->{'integer'}{$mykey}{'value'}, "\n" );
        }
    
        # Close the connection
        $session->close;

    } catch {
        warn "Failed to read device data: $_";
        $self->{'valid'} = 0;  # Something went wrong, the data is incomplete.
    };
    
    # Add the timestamp field
    $self->{'timestamp'} = strftime( "%Y%m%dT%H%MZ", gmtime );
    
    # Compute the computed variables
    $self->{'computed'}{1}{'value'}   = $self->{'analog'}{93}{'value'} + $self->{'analog'}{184}{'value'};
    $self->{'computed'}{1}{'status'}  = DEVICE::deviceHelpers::RangeCheck( $self->{'computed'}{1}{'value'}, $description->{'analog'}{36}{'range'} );
    $self->{'computed'}{2}{'value'}   = $self->{'analog'}{105}{'value'};
    $self->{'computed'}{2}{'status'}  = DEVICE::deviceHelpers::RangeCheck( $self->{'computed'}{2}{'value'}, $description->{'analog'}{36}{'range'} );
    $self->{'computed'}{11}{'value'}  = $self->{'integer'}{189}{'value'} . '.' . $self->{'integer'}{192}{'value'} . ' (' . (2000+$self->{'integer'}{186}{'value'}) . '-' . $self->{'integer'}{184}{'value'} . '-' . $self->{'integer'}{183}{'value'} . ')';
    $self->{'computed'}{12}{'value'}  = $self->{'integer'}{190}{'value'} . '.' . $self->{'integer'}{193}{'value'} . ' (' . (2000+$self->{'integer'}{188}{'value'}) . '-' . $self->{'integer'}{187}{'value'} . '-' . $self->{'integer'}{185}{'value'} . ')';
    $self->{'computed'}{13}{'value'}  = $self->{'integer'}{191}{'value'} . '.' . $self->{'integer'}{194}{'value'} . ' (' . (2000+$self->{'integer'}{198}{'value'}) . '-' . $self->{'integer'}{195}{'value'} . '-' . $self->{'integer'}{196}{'value'} . ')';

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

	# Order: Time stamp, Return Air Temperature, Return Air Humidity, Supply Air Temperature,
	# Aisle Differential Pressure, Inlet Water Temperature, Evaporator Fan Speed (%), CW Valve Position (%),
	# Fan Trip alarm, High Return Temperature alarm, Low Return Temperature alarm,
	# High Supply Temperature alarm, Low Supply Temperature alarm.
	my @logdata = (
	  $self->{'timestamp'},
	  $self->{'analog'}{35}{'value'}, 
	  $self->{'analog'}{34}{'value'}, 
	  $self->{'analog'}{36}{'value'}, 
	  $self->{'analog'}{48}{'value'}, 
	  $self->{'analog'}{39}{'value'}, 
	  $self->{'analog'}{33}{'value'}, 
	  $self->{'analog'}{2}{'value'}, 
	  $self->{'analog'}{44}{'value'}, 
	  $self->{'digital'}{31}{'value'}, 
	  $self->{'digital'}{57}{'value'}, 
	  $self->{'digital'}{58}{'value'}, 
	  $self->{'digital'}{59}{'value'}, 
	  $self->{'digital'}{60}{'value'}
	  );

	my $fh = IO::File->new( $filename, '>>' ) or die "Could not open file '$filename'";
	$fh->print( join($FS, @logdata), "\n" );
	$fh->close;
	
}


sub Status
{
	
	my $self = $_[0];
	
	my $status        = "";
	my $criticalAlarm = 0;
	my $softAlarm     = 0;
	
	if ( ! $self->{'valid'} ) {
        $status = "Offline";
    } else {
    	# Search for alarms
	    foreach my $key (keys %{$self->{'digital'}} ) {
		    if    ( $self->{'description'}{'digital'}{$key}{'type'} eq "SoftAlarm" )     { $softAlarm     = $softAlarm     || $self->{'digital'}{$key}{'value'}; }
		    elsif ( $self->{'description'}{'digital'}{$key}{'type'} eq "CriticalAlarm" ) { $criticalAlarm = $criticalAlarm || $self->{'digital'}{$key}{'value'}; }
	    } # end foreach my $key
	
	    # Summarise the result in status
	    if ( $criticalAlarm ) { $status = "Critical"; }
	    elsif ( $softAlarm )  { $status = "Non-Critical"; }
        else                  { $status = "Normal" }
    }
    
	return $status;

}


sub ObjDef
{
	
	return __FILE__;
	
}

#
# End of the package definition.
#
1; # Required to make sure the use or require commands succeed.

