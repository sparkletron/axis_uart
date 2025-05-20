//******************************************************************************
// file:    tb_coctb.v
//
// author:  JAY CONVERTINO
//
// date:    2025/01/23
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
 * Test bench for axis_uart_rx.
 *
 * Parameters:
 *
 *   PARITY_ENA       - Enable Parity for the data in and out.
 *   PARITY_TYPE      - Set the parity type, 0 = even, 1 = odd, 2 = mark, 3 = space.
 *   STOP_BITS        - Number of stop bits, 0 to crazy non-standard amounts.
 *   DATA_BITS        - Number of data bits, 1 to crazy non-standard amounts.
 *   DELAY            - Delay in rx data input.
 *   BUS_WIDTH        - BUS_WIDTH for axis bus in bytes.
 *
 * Ports:
 *
 *   aclk           - Clock for AXIS
 *   arstn          - Negative reset for AXIS
 *   parity_err     - Indicates error with parity check (active high)
 *   frame_err      - Indicates error with frame (active high)
 *   m_axis_tdata   - Output data from UART RX
 *   m_axis_tvalid  - When active high the output data is valid
 *   m_axis_tready  - When set active high the output device is ready for data.
 *   uart_clk       - Clock used for BAUD rate generation
 *   uart_rstn      - Negative reset for UART, for anything clocked on uart_clk
 *   uart_ena       - Enable UART data processing from RX.
 *   uart_hold      - Output to hold back clock in reset state till uart is in receive state.
 *   rxd            - receive for UART (input from TX)
 */
module tb_cocotb #(
    parameter PARITY_ENA  = 0,
    parameter PARITY_TYPE = 0,
    parameter STOP_BITS   = 1,
    parameter DATA_BITS   = 8,
    parameter DELAY       = 0,
    parameter BUS_WIDTH   = 1
  )
  (
    input                       aclk,
    input                       arstn,
    output                      parity_err,
    output                      frame_err,
    output  [BUS_WIDTH*8-1:0]   m_axis_tdata,
    output                      m_axis_tvalid,
    input                       m_axis_tready,
    input                       uart_clk,
    input                       uart_rstn,
    input                       uart_ena,
    output                      uart_hold,
    input                       rxd
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
   * Device under test, axis_uart_rx
   */
   axis_uart_rx #(
      .PARITY_ENA(PARITY_ENA),
      .PARITY_TYPE(PARITY_TYPE),
      .STOP_BITS(STOP_BITS),
      .DATA_BITS(DATA_BITS),
      .DELAY(DELAY),
      .BUS_WIDTH(BUS_WIDTH)
    ) dut (
      .aclk(aclk),
      .arstn(arstn),
      .parity_err(parity_err),
      .frame_err(frame_err),
      .m_axis_tdata(m_axis_tdata),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tready(m_axis_tready),
      .uart_clk(uart_clk),
      .uart_rstn(uart_rstn),
      .uart_ena(uart_ena),
      .uart_hold(uart_hold),
      .rxd(rxd)
  );
  
endmodule

