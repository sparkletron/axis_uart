//******************************************************************************
/// @FILE    tb_uart_tx.v
/// @AUTHOR  JAY CONVERTINO
/// @DATE    2021.06.23
/// @BRIEF   SIMPLE TEST BENCH FOR UART TX
///
/// @LICENSE MIT
///  Copyright 2021 Jay Convertino
///
///  Permission is hereby granted, free of charge, to any person obtaining a copy
///  of this software and associated documentation files (the "Software"), to 
///  deal in the Software without restriction, including without limitation the
///  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
///  sell copies of the Software, and to permit persons to whom the Software is 
///  furnished to do so, subject to the following conditions:
///
///  The above copyright notice and this permission notice shall be included in 
///  all copies or substantial portions of the Software.
///
///  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
///  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
///  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
///  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
///  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
///  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
///  IN THE SOFTWARE.
//******************************************************************************

`timescale 1 ns/10 ps

module tb_uart_tx;
  
  reg         tb_data_clk = 0;
  reg         tb_baud_ena = 0;
  wire        tb_baud_hold;
  reg         tb_rst = 0;
  wire        tb_txd;
  wire [7:0]  tb_tdata;
  wire        tb_tvalid;
  wire        tb_tready;
  
  //1ns
  localparam CLK_PERIOD   = 100;
  localparam BAUD_PERIOD  = 10000;
  localparam RST_PERIOD   = 1000;
  localparam DELAY_COUNT  = 50;
  
  integer counter;
  
  slave_axis_stimulus #(
    .BUS_WIDTH(1),
    .USER_WIDTH(1),
    .DEST_WIDTH(1),
    .FILE("const_data.bin")
  ) slave_axis_stim (
    // output to slave
    .m_axis_aclk(tb_data_clk),
    .m_axis_arstn(~tb_rst),
    .m_axis_tvalid(tb_tvalid),
    .m_axis_tready(tb_tready),
    .m_axis_tdata(tb_tdata),
    .m_axis_tkeep(),
    .m_axis_tlast(),
    .m_axis_tuser(),
    .m_axis_tdest()
  );
  
  //UART
  axis_uart_tx #(
      .PARITY_ENA(1),
      .PARITY_TYPE(1),
      .STOP_BITS(1),
      .DATA_BITS(8),
      .BUS_WIDTH(1)
    ) dut (
      //clock and reset
      .aclk(tb_data_clk),
      .arstn(~tb_rst),
      //slave input
      .s_axis_tdata(tb_tdata),
      .s_axis_tvalid(tb_tvalid),
      .s_axis_tready(tb_tready),
      //uart
      .uart_clk(tb_data_clk),
      .uart_rstn(~tb_rst),
      .uart_ena(tb_baud_ena),
      .uart_hold(tb_baud_hold),
      .txd(tb_txd)
    );
    
  //reset
  initial
  begin
    tb_rst <= 1'b1;
    
    #RST_PERIOD;
    
    tb_rst <= 1'b0;
  end
  
  //axis clock
  always
  begin
    tb_data_clk <= ~tb_data_clk;
    
    #(CLK_PERIOD/2);
  end
  
  //baud enable
  always @(posedge tb_data_clk)
  begin
    if (tb_rst == 1'b1) begin
      counter <= 0;
      tb_baud_ena <= 1'b0;
    end else begin
      counter <= counter + 1;
      tb_baud_ena <= 1'b0;
      
      if(counter >= (BAUD_PERIOD/CLK_PERIOD-1)) begin
        counter <= 0;
        tb_baud_ena <= 1'b1;
      end
    end
  end
  
  //copy pasta, fst generation
  initial
  begin
    $dumpfile("tb_uart_tx.fst");
    $dumpvars(0,tb_uart_tx);
  end
  
  //copy pasta, no way to set runtime... this works in vivado as well.
  initial begin
    #1_000_000; // Wait a long time in simulation units (adjust as needed).
    $display("END SIMULATION");
    $finish;
  end
endmodule

