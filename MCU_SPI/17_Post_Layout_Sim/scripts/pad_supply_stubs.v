// pad_supply_stubs.v - simulation-only empty models of the giolib045 supply pads
//   The giolib045 vlog directory has behavioral models for the signal pads
//   (PADDI / PADDO) only. The supply pads were added to the PnR netlist by
//   make_pnr_netlist.sh (add_pad_chip) and have no signal pins: in the
//   netlist they appear as  PADVDD u_pad_vdd0 ();  so an empty module is a
//   complete functional model. Power is not simulated in GLS.
`timescale 1ns / 1ps
module PADVDD    (); endmodule
module PADVSS    (); endmodule
module PADVDDIOR (); endmodule
module PADVSSIOR (); endmodule
