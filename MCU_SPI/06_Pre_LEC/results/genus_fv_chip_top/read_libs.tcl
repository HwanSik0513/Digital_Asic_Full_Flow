add_search_path /home/hah003/PROJ1/GPDK045/digital/gsclib045_all_v4.4/gsclib045/lef /home/hah003/PROJ1/GPDK045/digital/gsclib045_all_v4.4/gsclib045_tech/lef /home/hah003/PROJ1/GPDK045/digital/giolib045_v3.5/lef -library -both
read_library -liberty -both \
    /home/hah003/PROJ1/GPDK045/digital/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib \
    /home/hah003/PROJ1/GPDK045/digital/giolib045_v3.5/timing/pads_SS_s1vg.lib \
    /home/hah003/PROJ1/GPDK045/digital/gsclib045_all_v4.4/gsclib045/timing/fast_vdd1v0_basicCells.lib \
    /home/hah003/PROJ1/GPDK045/digital/giolib045_v3.5/timing/pads_FF_s1vg.lib

