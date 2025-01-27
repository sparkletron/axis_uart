//******************************************************************************
// file:    axis_uart.v
//
// author:  JAY CONVERTINO
//
// date:    2021/06/24
//
// about:   Brief
// Core for interfacing with simple UART communications. Output is
// always the size of DATA_BITS.
//
// license: License MIT
// Copyright 2021 Jay Convertino
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
//******************************************************************************

`timescale 1ns/100ps

/*
 * Module: axis_uart
 *
 * AXIS UART, simple UART with AXI Streaming interface.
 *
 * Parameters:
 *
 *   BAUD_CLOCK_SPEED - This is the aclk frequency in Hz
 *   BAUD_RATE        - Serial Baud, this can be any value including non-standard.
 *   PARITY_ENA       - Enable Parity for the data in and out.
 *   PARITY_TYPE      - Set the parity type, 0 = even, 1 = odd, 2 = mark, 3 = space.
 *   STOP_BITS        - Number of stop bits, 0 to crazy non-standard amounts.
 *   DATA_BITS        - Number of data bits, 1 to crazy non-standard amounts.
 *   RX_DELAY         - Delay in rx data input.
 *   RX_BAUD_DELAY    - Delay in rx baud enable. This will delay when we sample a bit (default is midpoint when rx delay is 0).
 *   TX_DELAY         - Delay in tx data output. Delays the time to output of the data.
 *   TX_BAUD_DELAY    - Delay in tx baud enable. This will delay the time the bit output starts.
 *
 * Ports:
 *
 *   aclk           - Clock for AXIS
 *   arstn          - Negative reset for AXIS
 *   parity_err     - Indicates error with parity check (active high)
 *   frame_err      - Indicates error with frame (active high)
 *   s_axis_tdata   - Input data for UART TX.
 *   s_axis_tvalid  - When set active high the input data is valid
 *   s_axis_tready  - When active high the device is ready for input data.
 *   m_axis_tdata   - Output data from UART RX
 *   m_axis_tvalid  - When active high the output data is valid
 *   m_axis_tready  - When set active high the output device is ready for data.
 *   uart_clk       - Clock used for BAUD rate generation
 *   uart_rstn      - Negative reset for UART, for anything clocked on uart_clk
 *   tx             - transmit for UART (output to RX)
 *   rx             - receive for UART (input from TX)
 *   rts            - request to send is a loop with CTS
 *   cts            - clear to send is a loop with RTS
 */
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
    input                   aclk,
    input                   arstn,
    output                  parity_err,
    output                  frame_err,
    input  [DATA_BITS-1:0]  s_axis_tdata,
    input                   s_axis_tvalid,
    output                  s_axis_tready,
    output [DATA_BITS-1:0]  m_axis_tdata,
    output                  m_axis_tvalid,
    input                   m_axis_tready,
    input                   uart_clk,
    input                   uart_rstn,
    output                  tx,
    input                   rx,
    output                  rts,
    input                   cts
  );
  
  wire uart_ena_tx;
  wire uart_ena_rx;
  wire uart_hold_rx;
  
  assign rts = 1'b1;
  
  //Group: Instantiated Modules
  /*
   * Module: uart_baud_gen_tx
   *
   * Generates TX BAUD rate for UART modules using modulo divide method.
   */
  mod_clock_ena_gen #(
    .CLOCK_SPEED(BAUD_CLOCK_SPEED),
    .START_AT_ZERO(1),
    .DELAY(TX_BAUD_DELAY)
  ) uart_baud_gen_tx (
    .clk(uart_clk),
    .rstn(uart_rstn),
    .hold(1'b0),
    .rate(BAUD_RATE),
    .ena(uart_ena_tx)
  );
  
  /*
   * Module: uart_baud_gen_rx
   *
   * Generates RX BAUD rate for UART modules using modulo divide method.
   */
  mod_clock_ena_gen #(
    .CLOCK_SPEED(BAUD_CLOCK_SPEED),
    .START_AT_ZERO(0),
    .DELAY(RX_BAUD_DELAY)
  ) uart_baud_gen_rx (
    .clk(uart_clk),
    .rstn(uart_rstn),
    .hold(uart_hold_rx),
    .rate(BAUD_RATE),
    .ena(uart_ena_rx)
  );
  
  /*
   * Module: uart_tx
   *
   * Produces transmit data for tx UART from AXIS.
   */
  axis_uart_tx #(
    .PARITY_ENA(PARITY_ENA),
    .PARITY_TYPE(PARITY_TYPE),
    .STOP_BITS(STOP_BITS),
    .DATA_BITS(DATA_BITS),
    .DELAY(TX_DELAY)
  ) uart_tx (
    .aclk(aclk),
    .arstn(arstn),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .uart_clk(uart_clk),
    .uart_rstn(uart_rstn),
    .uart_ena(uart_ena_tx),
    .txd(tx)
  );
  
  /*
   * Module: uart_rx
   *
   * Consumes receive data for rx UART to AXIS.
   */
  axis_uart_rx #(
    .PARITY_ENA(PARITY_ENA),
    .PARITY_TYPE(PARITY_TYPE),
    .STOP_BITS(STOP_BITS),
    .DATA_BITS(DATA_BITS),
    .DELAY(RX_DELAY)
  ) uart_rx (
    .aclk(aclk),
    .arstn(arstn),
    .parity_err(parity_err),
    .frame_err(frame_err),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .uart_clk(uart_clk),
    .uart_rstn(uart_rstn),
    .uart_ena(uart_ena_rx),
    .uart_hold(uart_hold_rx),
    .rxd(rx)
  );
 
endmodule
