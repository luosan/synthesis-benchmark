read_verilog top.v

synth_xilinx -arch xcup -top top

write_json result.json
write_verilog result.v