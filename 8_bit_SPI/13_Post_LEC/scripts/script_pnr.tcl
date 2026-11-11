set log file ./log/spi_bridge_PNR_lec.log -replace

read library -verilog -both \
        /home/hitech010/PROJ1/GPDK045/digital/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
        /home/hitech010/PROJ1/GPDK045/digital/gsclib045_all_v4.4/gsclib045/verilog/fast_vdd1v0_basicCells.v \
        /home/hitech010/PROJ1/GPDK045/digital/giolib045_v3.5/vlog/pads_SS_s1vg.v


read design \
        /home/hitech010/PROJ1/Proj1_make/TOP/SYN/mapped/spi_bridge_top_syn_final.v \
        -verilog -revised

read design \
	/home/hitech010/PROJ1/Proj1_make/TOP/PNR/spi_bridge_top_pnr.v -verilog -golden

set system mode lec

add compare points -all

compare

report verification
report statistics




