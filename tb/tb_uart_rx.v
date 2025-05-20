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

module tb_uart_rx;
  
  reg         tb_data_clk = 0;
  reg         tb_baud_clk = 0;
  reg         tb_baud_ena = 0;
  reg         tb_rst = 0;
  wire        tb_rxd;
  wire [7:0]  tb_tdata;
  wire        tb_tvalid;
  wire        tb_tready;
  
  //1ns
  localparam CLK_PERIOD = 100;
  localparam BAUD_PERIOD = 1000;
  localparam RST_PERIOD = 500;
  //serial data, one parity, one stop, one start, eight data bits, one for holding at one.
  localparam SERIAL_BITS = 1 + 1 + 1 + 8 + 1;
  
  //reg
  //serial data, one parity, one stop, one start, eight data bits, one for holding at one.
  reg [SERIAL_BITS-1:0] serial_data;
  
  integer data_counter;
  integer baud_counter;
  
  //device under test
  axis_uart_rx #(
    .PARITY_ENA(0),
    .PARITY_TYPE(0),
    .STOP_BITS(1),
    .DATA_BITS(8),
    .DELAY(3),
    .BUS_WIDTH(1)
  ) dut (
    //clock and reset
    .aclk(tb_data_clk),
    .arstn(~tb_rst),
    //master output
    .m_axis_tdata(tb_tdata),
    .m_axis_tvalid(tb_tvalid),
    .m_axis_tready(tb_tready),
    //uart input
    .uart_clk(tb_data_clk),
    .uart_rstn(~tb_rst),
    .uart_ena(tb_baud_ena),
    .rxd(tb_rxd)
  );
  
  master_axis_stimulus #(
    .BUS_WIDTH(1),
    .USER_WIDTH(1),
    .DEST_WIDTH(1),
    .FILE("out.bin")
  ) master_axis_stim (
    // write
    .s_axis_aclk(tb_data_clk),
    .s_axis_arstn(~tb_rst),
    .s_axis_tvalid(tb_tvalid),
    .s_axis_tready(tb_tready),
    .s_axis_tdata(tb_tdata),
    .s_axis_tkeep(1'b1),
    .s_axis_tlast(1'b0),
    .s_axis_tuser(1'b0),
    .s_axis_tdest(1'b0)
  );
    
  //assign
  assign tb_rxd = serial_data[data_counter];
  
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
  
  //baud clock
  always
  begin
    tb_baud_clk <= ~tb_baud_clk;
    
    #(BAUD_PERIOD/2);
  end
  
  //baud enable
  always @(posedge tb_data_clk)
  begin
    if (tb_rst == 1'b1) begin
      baud_counter <= BAUD_PERIOD/CLK_PERIOD;
      tb_baud_ena <= 1'b1;
    end else begin
      baud_counter <= baud_counter + 1;
      tb_baud_ena <= 1'b0;
      
      if(baud_counter >= (BAUD_PERIOD/CLK_PERIOD-1)) begin
        baud_counter <= 0;
        tb_baud_ena <= 1'b1;
      end
    end
  end
  
  //produce data
  always @(posedge tb_baud_clk)
  begin
    if (tb_rst == 1'b1) begin
      data_counter  <= SERIAL_BITS-1;
      serial_data   <= 12'b100101010111;
    end else begin
      data_counter <= data_counter - 1;
      
      if(data_counter == 0) begin
        data_counter <= SERIAL_BITS - 1;
        serial_data[9:2] <= {serial_data[8:2], serial_data[9]};
      end
      
    end
  end
  
    //copy pasta, fst generation
  initial
  begin
    $dumpfile("tb_uart_rx.fst");
    $dumpvars(0,tb_uart_rx);
  end
  
  //copy pasta, no way to set runtime... this works in vivado as well.
  initial begin
    #1_000_000; // Wait a long time in simulation units (adjust as needed).
    $display("END SIMULATION");
    $finish;
  end
endmodule

