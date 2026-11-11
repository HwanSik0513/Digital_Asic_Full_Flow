########################################
# capture.tcl - Innovus layout screenshot helper (GUI session required)
#
# Usage (inside a stage script, after the stage is done, before saveDesign):
#   source capture.tcl
#   snap 02_place place
#
# view : fplan | place | ameba
# Output: ./capture/<name>.gif
# [TO VERIFY] dumpToGIF / setDrawView availability: help dumpToGIF
########################################

proc snap {name {view place}} {
    file mkdir capture
    setDrawView $view
    fit
    dumpToGIF capture/${name}.gif
    puts "INFO: captured capture/${name}.gif ($view view)"
}
