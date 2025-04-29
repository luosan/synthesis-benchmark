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
    echo "read -vhdl $1" > ${topmodule}_yosys.tcl
else
    topmodule=$( basename -s .v "$1")
    echo "read -vlog2k $1" > ${topmodule}_yosys.tcl
fi
echo "synth_xilinx -arch xcup -top $topmodule" >> ${topmodule}_yosys.tcl
echo "write_verilog ${topmodule}_yosys_result.vv" >> ${topmodule}_yosys.tcl

logfile="${topmodule}_yosys.log"

# run tools
yosys -ql $logfile -p "script $scriptpath/${topmodule}_yosys.tcl" >/dev/null
dsps=$(sed -n '/Number of cells:/,/Estimated number of LCs:/ { /DSP48E2/ { s/.*DSP48E2[[:space:]]*//; s/[^0-9].*//; p; }; }' $logfile)
if [ -z "$dsps" ]; then
  echo 0
else
  echo $dsps
fi
# rm -f $logfile
# rm -f ${topmodule}_yosys.tcl