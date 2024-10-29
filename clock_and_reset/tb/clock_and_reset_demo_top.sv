`timescale 1ns/1ns

module demo_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import clock_and_reset_pkg::*;
  `include "clock_and_reset_demo_tb.sv"
  `include "clock_and_reset_test_lib.sv"
  
  parameter int             CLK_WIDTH  = 32;

  // Clock and reset signals
  logic [CLK_WIDTH-1:0]     clock_period;
  logic                     run_clock;
  logic                     clock;
  logic                     reset;

  clkgen clkgen (.clock(clock), .run_clock(run_clock), .clock_period(clock_period));

  clock_and_reset_if  clock_and_reset_if (.clock(clock), .reset(reset), .run_clock(run_clock), .clock_period(clock_period));
  
  initial begin
    clock_and_reset_vif_config::set(null,"*.tb.clock_and_reset.*","vif", clock_and_reset_if);
    run_test();
  end

endmodule