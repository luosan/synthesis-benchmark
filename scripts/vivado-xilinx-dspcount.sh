#!/bin/bash

#
# mode script for Xilinx FPGA DSP48E2 count
#

scriptpath=$( pwd )

# create synthesis script
myfile="$1"
celllibpath="$2"  

echo "create_project proj ./proj -part xcu250-figd2104-2L-e -force" >> vivado_script_$topmodule.tcl

if [ ${myfile: -5} == ".vhdl" ]
then
    topmodule=$( basename -s .vhdl "$1" )
    echo "add_files {$1}" > vivado_script_$topmodule.tcl
else
    topmodule=$( basename -s .v "$1")
    echo "add_files {$1}" > vivado_script_$topmodule.tcl
fi
echo "update_compile_order -fileset sources_1" >> vivado_script_$topmodule.tcl
echo "launch_runs synth_1 -jobs 4 -verbose" >> vivado_script_$topmodule.tcl
echo "wait_on_run synth_1" >> vivado_script_$topmodule.tcl
echo "report_utilization" >> vivado_script_$topmodule.tcl
echo "write_verilog -force -include_xilinx_libs vivado_result_$topmodule.vv" >> vivado_script_$topmodule.tcl

logfile="vivado_$topmodule.log"

# run tools
vivado -mode batch -source vivado_script_$topmodule.tcl -log $logfile -verbose >/dev/null
dsps=$(sed -n '/Report Cell Usage:/,/^$/ { /DSP48E2/ { s/.*DSP48E2[[:space:]]*//; s/[^0-9].*//; p; }; }' $logfile)
if [ -z "$dsps" ]; then
  echo 0
else
  echo $dsps
fi
rm -f ./proj
# rm -f vivado_script_$topmodule.tcl