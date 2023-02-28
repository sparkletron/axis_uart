//******************************************************************************
/// @file    tb_uart_rx.v
/// @author  JAY CONVERTINO
/// @date    2021.06.23
/// @brief   SIMPLE TEST BENCH FOR UART RX
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

module tb_uart #(
  parameter IN_FILE_NAME = "in.bin",
  parameter OUT_FILE_NAME = "out.bin",
  parameter RAND_READY = 0);
  
  reg         tb_data_clk = 0;
  reg         tb_rst = 0;
  reg         tb_r_eof = 0;

  wire [7:0]  tb_m_tdata;
  wire        tb_m_tvalid;
  wire        tb_m_tready;

  wire [7:0]  tb_s_tdata;
  wire        tb_s_tvalid;
  wire        tb_s_tready;
  wire        tb_uart_loop;
  
  wire        tb_eof;
  
  //1ns
  localparam CLK_PERIOD = 20;

  localparam RST_PERIOD = 500;
  localparam CLK_SPEED_HZ = 1000000000/CLK_PERIOD;

  slave_axis_stimulus #(
    .BUS_WIDTH(1),
    .USER_WIDTH(1),
    .DEST_WIDTH(1),
    .FILE(IN_FILE_NAME)
  ) slave_axis_stim (
    // output to slave
    .m_axis_aclk(tb_data_clk),
    .m_axis_arstn(~tb_rst),
    .m_axis_tvalid(tb_s_tvalid),
    .m_axis_tready(tb_s_tready),
    .m_axis_tdata(tb_s_tdata),
    .m_axis_tkeep(),
    .m_axis_tlast(),
    .m_axis_tuser(),
    .m_axis_tdest(),
    .eof(tb_eof)
  );
  
  //device under test
  axis_uart #(
    .BAUD_CLOCK_SPEED(CLK_SPEED_HZ),
    .BAUD_RATE(4000000),
    .PARITY_ENA(0),
    .PARITY_TYPE(0),
    .STOP_BITS(1),
    .DATA_BITS(8),
    .RX_DELAY(6),
    .RX_BAUD_DELAY(2),
    .TX_DELAY(2),
    .TX_BAUD_DELAY(0)
  ) dut (
    //clock and reset
    .aclk(tb_data_clk),
    .arstn(~tb_rst),
    //master output
    .m_axis_tdata(tb_m_tdata),
    .m_axis_tvalid(tb_m_tvalid),
    .m_axis_tready(tb_m_tready),
    //slave input
    .s_axis_tdata(tb_s_tdata),
    .s_axis_tvalid(tb_s_tvalid),
    .s_axis_tready(tb_s_tready),
    //uart input
    .uart_clk(tb_data_clk),
    .uart_rstn(~tb_rst),
    .tx(tb_uart_loop),
    .rx(tb_uart_loop)
  );
  
  master_axis_stimulus #(
    .BUS_WIDTH(1),
    .USER_WIDTH(1),
    .DEST_WIDTH(1),
    .RAND_READY(RAND_READY),
    .FILE(OUT_FILE_NAME)
  ) master_axis_stim (
    // write
    .s_axis_aclk(tb_data_clk),
    .s_axis_arstn(~tb_rst),
    .s_axis_tvalid(tb_m_tvalid),
    .s_axis_tready(tb_m_tready),
    .s_axis_tdata(tb_m_tdata),
    .s_axis_tkeep(1'b1),
    .s_axis_tlast(1'b0),
    .s_axis_tuser(1'b0),
    .s_axis_tdest(1'b0),
    .eof(tb_r_eof)
  );
  
  //axis clock
  always
  begin
    tb_data_clk <= ~tb_data_clk;
    
    #(CLK_PERIOD/2);
  end
  
  //reset
  initial
  begin
    tb_rst <= 1'b1;
    
    #RST_PERIOD;
    
    tb_rst <= 1'b0;
  end
  
  // works for continuous, haven't tested random 
  always @(posedge tb_data_clk) begin
    if((tb_m_tvalid == 1'b1) && (dut.uart_tx.state != 3'd4)) begin
      tb_r_eof <= tb_eof;
    end
  end
  
  //copy pasta, fst generation
  initial
  begin
    $dumpfile("tb_uart.fst");
    $dumpvars(0,tb_uart);
  end
endmodule
