//******************************************************************************
/// @FILE    axis_uart.v
/// @AUTHOR  JAY CONVERTINO
/// @DATE    2021.06.24
/// @BRIEF   AXIS UART
/// @DETAILS Core for interfacing with simple UART communications. Output is
///          always the size of DATA_BITS.
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

`timescale 1ns/100ps

//UART
module axis_uart #(
    parameter BAUD_CLOCK_SPEED  = 2000000,
    parameter BAUD_RATE   = 2000000,
    parameter PARITY_ENA  = 0,
    parameter PARITY_TYPE = 0,
    parameter STOP_BITS   = 1,
    parameter DATA_BITS   = 8,
    parameter RX_DELAY    = 0,
    parameter RX_BAUD_DELAY = 0,
    parameter TX_DELAY    = 0,
    parameter TX_BAUD_DELAY = 0
  ) 
  (
    //axis clock and reset
    input aclk,
    input arstn,
    //slave input
    input  [DATA_BITS-1:0]  s_axis_tdata,
    input                   s_axis_tvalid,
    output                  s_axis_tready,
    //master output
    output [DATA_BITS-1:0]  m_axis_tdata,
    output                  m_axis_tvalid,
    input                   m_axis_tready,
    //UART
    input   uart_clk,
    input   uart_rstn,
    output  tx,
    input   rx,
    output  rts,
    input   cts
  );
  
  wire uart_ena_tx;
  wire uart_ena_rx;
  wire uart_hold_rx;
  
  assign rts = 1'b1;
  
  //baud enable generator for tx, enable blocks when data i/o is needed at set rate.
  uart_baud_gen #(
    .BAUD_CLOCK_SPEED(BAUD_CLOCK_SPEED),
    .BAUD_RATE(BAUD_RATE),
    .DELAY(TX_BAUD_DELAY)
  ) uart_baud_gen_tx (
    .uart_clk(uart_clk),
    .uart_rstn(uart_rstn),
    .uart_hold(1'b0),
    .uart_ena(uart_ena_tx)
  );
  
  uart_baud_gen #(
    .BAUD_CLOCK_SPEED(BAUD_CLOCK_SPEED),
    .BAUD_RATE(BAUD_RATE),
    .DELAY(RX_BAUD_DELAY)
  ) uart_baud_gen_rx (
    .uart_clk(uart_clk),
    .uart_rstn(uart_rstn),
    .uart_hold(uart_hold_rx),
    .uart_ena(uart_ena_rx)
  );
  
  axis_uart_tx #(
    .PARITY_ENA(PARITY_ENA),
    .PARITY_TYPE(PARITY_TYPE),
    .STOP_BITS(STOP_BITS),
    .DATA_BITS(DATA_BITS),
    .DELAY(TX_DELAY)
  ) uart_tx (
    //clock and reset
    .aclk(aclk),
    .arstn(arstn),
    //slave input
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    //UART
    .uart_clk(uart_clk),
    .uart_rstn(uart_rstn),
    .uart_ena(uart_ena_tx),
    .txd(tx)
  );
  
  axis_uart_rx #(
    .PARITY_ENA(PARITY_ENA),
    .PARITY_TYPE(PARITY_TYPE),
    .STOP_BITS(STOP_BITS),
    .DATA_BITS(DATA_BITS),
    .DELAY(RX_DELAY)
  ) uart_rx (
    //clock and reset
    .aclk(aclk),
    .arstn(arstn),
    //master output
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    //UART
    .uart_clk(uart_clk),
    .uart_rstn(uart_rstn),
    .uart_ena(uart_ena_rx),
    .uart_hold(uart_hold_rx),
    .rxd(rx)
  );
 
endmodule
