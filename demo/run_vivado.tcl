create_project proj ./proj -part xcu250-figd2104-2L-e -force
add_files {top.v}
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs 4 -verbose
wait_on_run synth_1
report_utilization
write_verilog -force -include_xilinx_libs top_synth_vivado.v
