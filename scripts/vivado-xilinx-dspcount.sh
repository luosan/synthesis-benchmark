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
    echo "read_vhdl {$1}" > ${topmodule}_vivado.tcl
else
    topmodule=$( basename -s .v "$1")
    echo "read_verilog {$1}" > ${topmodule}_vivado.tcl
fi
echo "synth_design -top $topmodule -part xcu250-figd2104-2L-e" >> ${topmodule}_vivado.tcl
echo "report_utilization" >> ${topmodule}_vivado.tcl
echo "write_verilog -force -include_xilinx_libs ${topmodule}_vivado_result.vv" >> ${topmodule}_vivado.tcl
echo "exit" >> ${topmodule}_vivado.tcl

logfile="${topmodule}_vivado.log"

# run tools
vivado -mode tcl -source ${topmodule}_vivado.tcl -log $logfile -verbose >/dev/null
dsps=$(sed -n '/Report Cell Usage:/,/Report Instance Areas:/ { /DSP48E2/ { s/.*DSP48E2[^|]*|[[:space:]]*//; s/[^0-9].*//; p; }; }' $logfile)
if [ -z "$dsps" ]; then
  echo 0
else
  echo $dsps
fi
rm -rf vivado*.jou
# rm -f ${topmodule}_vivado.tcl