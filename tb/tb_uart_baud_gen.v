//******************************************************************************
/// @file    tb_uart.v
/// @author  JAY CONVERTINO
/// @date    2021.06.23
/// @brief   SIMPLE TEST BENCH
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

module tb_uart_baud;
  
  reg         tb_data_clk = 0;
  reg         tb_rst = 0;
  reg         tb_random = 0;
  wire        tb_baud_ena;
  
  //1ns
  localparam CLK_PERIOD = 100;
  localparam RST_PERIOD = 1000;
  localparam CLK_SPEED_HZ = 1000000000/CLK_PERIOD;
  
  
  //device under test
  uart_baud_gen #(
    .BAUD_CLOCK_SPEED(CLK_SPEED_HZ),
    .BAUD_RATE(912600)
  ) dut (
    //clock and reset
    .uart_clk(tb_data_clk),
    .uart_rstn(~tb_rst),
    .uart_hold(tb_random),
    .uart_ena(tb_baud_ena)
  );
    
  //reset
  initial
  begin
    tb_rst <= 1'b1;
    
    #RST_PERIOD;
    
    tb_rst <= 1'b0;
  end
  
  //copy pasta, fst generation
  initial
  begin
    $dumpfile("tb_uart_baud.fst");
    $dumpvars(0,tb_uart_baud);
  end
  
  //clock
  always
  begin
    tb_data_clk <= ~tb_data_clk;
    
    tb_random   <= $random % 2;
    
    #(CLK_PERIOD/2);
  end
  
  //copy pasta, no way to set runtime... this works in vivado as well.
  initial begin
    #1_000_000; // Wait a long time in simulation units (adjust as needed).
    $display("END SIMULATION");
    $finish;
  end
endmodule

