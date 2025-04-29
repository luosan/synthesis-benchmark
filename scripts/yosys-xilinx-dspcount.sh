#!/bin/bash

#
# mode script for Xilinx FPGA DSP48E2 count
#

scriptpath=$( pwd )

# create synthesis script
myfile="$1"
celllibpath="$2"  

if [ ${myfile: -5} == ".vhdl" ]
then
    topmodule=$( basename -s .vhdl "$1" )
    echo "read -vhdl $1" > script_$topmodule.yos
else
    topmodule=$( basename -s .v "$1")
    echo "read -vlog2k $1" > script_$topmodule.yos
fi
echo "synth_xilinx -arch xcup -top $topmodule" >> script_$topmodule.yos
echo "write_verilog yosys_result_$topmodule.vv" >> script_$topmodule.yos

logfile="yosys_$topmodule.log"

# run tools
yosys -ql $logfile -p "script $scriptpath/script_$topmodule.yos" >/dev/null
dsps=$(sed -n '/Number of cells:/,/Estimated number of LCs:/ { /DSP48E2/ { s/.*DSP48E2[[:space:]]*//; s/[^0-9].*//; p; }; }' $logfile)
if [ -z "$dsps" ]; then
  echo 0
else
  echo $dsps
fi
# rm -f $logfile
# rm -f script_$topmodule.yos