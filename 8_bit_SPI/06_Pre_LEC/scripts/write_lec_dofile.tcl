#----------------------------------------------------------------------
# write_lec_dofile.tcl - make the RTL -> synthesized-netlist LEC dofile (Genus)
#   Add after write_hdl in the synthesis script, or run on a saved DB:
#     genus
#     read_db mapped/syn_opt.db
#     source write_lec_dofile.tcl
#   Then (in the SYN directory, the dofile uses relative paths):
#     lec -XL -nogui -dofile mapped/rtl2final_lec.do
#   PASS = "Non-equivalent 0" and "Abort 0" in log/rtl2final_lec.log
#----------------------------------------------------------------------
write_do_lec -revised_design mapped/spi_bridge_top_syn_final.v \
             -logfile log/rtl2final_lec.log \
             > mapped/rtl2final_lec.do
