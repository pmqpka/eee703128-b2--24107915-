// =============================================================================
// tb.v - khung testbench cho cocotb (cau truc chuan cua kho mau Tiny Tapeout)
// CI chay: test/test.py (cocotb) dieu khien cac tin hieu o day.
// Testbench tu kiem tra bang Verilog nam o test/tb_selfcheck.v (chay bang iverilog).
// =============================================================================
`default_nettype none
`timescale 1ns / 1ps

module tb ();

  // Xuat waveform (CI va cocotb doc file nay)
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  reg        clk;
  reg        rst_n;
  reg        ena;
  reg  [7:0] ui_in;
  reg  [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  tt_um_eee703128_24107915 user_project (
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (ena),
      .clk    (clk),
      .rst_n  (rst_n)
  );

endmodule
