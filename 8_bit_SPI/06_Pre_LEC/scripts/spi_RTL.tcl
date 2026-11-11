set log file ./log/lec_rtl_syn.log -replace

read library -verilog -both \
    /home/hitech010/PROJ1/GPDK045/digital/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
    /home/hitech010/PROJ1/GPDK045/digital/giolib045_v3.5/vlog/pads_SS_s1vg.v

read design -verilog -golden \
    /home/hitech010/PROJ1/Proj1_make/TOP/RTL/Async_fifo.v \
    /home/hitech010/PROJ1/Proj1_make/TOP/RTL/Pulse_sync.v \
    /home/hitech010/PROJ1/Proj1_make/TOP/RTL/Register_block.v \
    /home/hitech010/PROJ1/Proj1_make/TOP/RTL/Reset_sync.v \
    /home/hitech010/PROJ1/Proj1_make/TOP/RTL/Sclk_gen.v \
    /home/hitech010/PROJ1/Proj1_make/TOP/RTL/Spi_master.v \
    /home/hitech010/PROJ1/Proj1_make/TOP/RTL/Spi_slave.v \
    /home/hitech010/PROJ1/Proj1_make/TOP/RTL/Spi_bridge_top.v

read design -verilog -revised \
    /home/hitech010/PROJ1/Proj1_make/TOP/SYN/mapped/spi_bridge_top_syn_final.v

set system mode lec
add compare points -all
compare

report verification
report statistics
report unmapped points -summary
