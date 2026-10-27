# Cadence Genus(TM) Synthesis Solution, Version 22.17-s071_1, built Sep 12 2024 12:37:05

# Date: Wed Oct 28 03:13:35 2026
# Host: kopo-seongnam (x86_64 w/Linux 3.10.0-1160.el7.x86_64) (20cores*80cpus*2physical cpus*Intel(R) Xeon(R) Gold 5218R CPU @ 2.10GHz 28160KB)
# OS:   CentOS Linux release 7.9.2009 (Core)

source ./script/spi_bridge_top_45nm_SLOW.tcl
get_db [get_db library_sets] .library_files
get_db [get_db opconds] .*
get_db analysis_views
get_db [get_db analysis_views] .*
get_db [get_db delay_corners] .*
report_timing -from [all_registers] -to [all_registers] -nworst 5
report_timing -from [all_registers] -to [all_registers] -nworst 5 -net
quit
