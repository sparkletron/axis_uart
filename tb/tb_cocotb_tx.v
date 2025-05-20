//******************************************************************************
// file:    tb_coctb.v
//
// author:  JAY CONVERTINO
//
// date:    2024/12/10
//
// about:   Brief
// Test bench wrapper for cocotb
//
// license: License MIT
// Copyright 2024 Jay Convertino
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
 * Module: tb_cocotb
 *
 * Test bench for AXIS UART TX, simple UART TX from AXI Streaming interface.
 *
 * Parameters:
 *
 *   PARITY_ENA       - Enable Parity for the data in and out.
 *   PARITY_TYPE      - Set the parity type, 0 = even, 1 = odd, 2 = mark, 3 = space.
 *   STOP_BITS        - Number of stop bits, 0 to crazy non-standard amounts.
 *   DATA_BITS        - Number of data bits, 1 to crazy non-standard amounts.
 *   DELAY            - Delay in tx data output. Delays the time to output of the data.
 *   BUS_WIDTH        - BUS_WIDTH for axis bus in bytes.
 *
 * Ports:
 *
 *   aclk           - Clock for AXIS
 *   arstn          - Negative reset for AXIS
 *   s_axis_tdata   - Input data for UART TX.
 *   s_axis_tvalid  - When set active high the input data is valid
 *   s_axis_tready  - When active high the device is ready for input data.
 *   uart_clk       - Clock used for BAUD rate generation
 *   uart_rstn      - Negative reset for UART, for anything clocked on uart_clk
 *   uart_ena       - When active high enable UART transmit state.
 *   uart_hold      - Output to hold back clock in reset state till uart is in transmit state.
 *   txd            - transmit for UART (output to RX)
 */
module tb_cocotb #(
    parameter PARITY_ENA  = 0,
    parameter PARITY_TYPE = 1,
    parameter STOP_BITS   = 1,
    parameter DATA_BITS   = 8,
    parameter DELAY       = 0,
    parameter BUS_WIDTH   = 1
  )
  (
    input                     aclk,
    input                     arstn,
    input  [BUS_WIDTH*8-1:0]  s_axis_tdata,
    input                     s_axis_tvalid,
    output                    s_axis_tready,
    input                     uart_clk,
    input                     uart_rstn,
    input                     uart_ena,
    output                    uart_hold,
    output                    txd
  );
  // fst dump command
  initial begin
    $dumpfile ("tb_cocotb.fst");
    $dumpvars (0, tb_cocotb);
    #1;
  end
  
  //Group: Instantiated Modules

  /*
   * Module: dut
   *
   * Device under test, axis_uart_tx
   */
  axis_uart_tx #(
    .PARITY_ENA(PARITY_ENA),
    .PARITY_TYPE(PARITY_TYPE),
    .STOP_BITS(STOP_BITS),
    .DATA_BITS(DATA_BITS),
    .DELAY(DELAY),
    .BUS_WIDTH(BUS_WIDTH)
  ) dut (
    .aclk(aclk),
    .arstn(arstn),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .uart_clk(uart_clk),
    .uart_rstn(uart_rstn),
    .uart_ena(uart_ena),
    .uart_hold(uart_hold),
    .txd(txd)
  );
  
endmodule

