//******************************************************************************
// file:    tb_cocotb.v
//
// author:  JAY CONVERTINO
//
// date:    2025/01/21
//
// about:   Brief
// Test bench wrapper for cocotb
//
// license: License MIT
// Copyright 2025 Jay Convertino
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
 * Test bench for axis uart.
 *
 * AXIS UART DTE, a UART with AXI Streaming interface.
 *
 * Parameters:
 *
 *   CLOCK_SPEED           - This is the aclk frequency in Hz
 *   BUS_WIDTH             - AXIS data bus width in bytes.
 *   RX_BAUD_DELAY         - DELAY RX internal baud rate by CLOCK_SPEED number of cycles.
 *   TX_BAUD_DELAY         - DELAY TX internal baud rate by CLOCK_SPEED number of cycles.
 *
 * Ports:
 *
 *   aclk                  - Clock for AXIS
 *   arstn                 - Negative reset for AXIS
 *   reg_parity            - Set the parity type, 0 = none, 1 = odd, 2 = even, 3 = mark , 4 = space
 *   reg_stop_bits         - Set the number of stop bits (0 to 3, 0=0, 1=1, 2=2, 3=??).
 *   reg_data_bits         - Set the number of data bits up to the BUS_WIDTH*8 (1 to 16, all values are biased by 1, 0+1=1).
 *   reg_baud_rate         - Frequency in Hz for the output/input data rate. This can be up to half of AXIS clock (any 32 bit unsigned value in Hz).
 *   reg_istatus_bits      - Collection of input status bits for dtr,cts,dts,dcd.
 *   reg_ostatus_bits      - Collection of output status bits for rx/tx frame, rx parity.
 *   s_axis_tdata          - Input data for UART TX.
 *   s_axis_tvalid         - When set active high the input data is valid
 *   s_axis_tready         - When active high the device is ready for input data.
 *   m_axis_tdata          - Output data from UART RX
 *   m_axis_tvalid         - When active high the output data is valid
 *   m_axis_tready         - When set active high the output device is ready for data.
 *   uart_clk              - Clock used for BAUD rate generation
 *   uart_rstn             - Negative reset for UART, for anything clocked on uart_clk
 *   tx                    - transmit for UART (output to RX)
 *   rx                    - receive for UART (input from TX)
 *   rts                   - request to send is a loop with CTS
 *   dtr                   - data terminal ready
 *   cts                   - clear to send is a loop with RTS
 *   ri                    - ring indicator
 */
module tb_cocotb #(
    parameter CLOCK_SPEED  = 2000000,
    parameter BUS_WIDTH = 1,
    parameter RX_BAUD_DELAY = 0,
    parameter TX_BAUD_DELAY = 0
  ) 
  (
    input   wire                     aclk,
    input   wire                     arstn,
    input   wire  [ 2:0]             reg_parity,
    input   wire  [ 1:0]             reg_stop_bits,
    input   wire  [ 3:0]             reg_data_bits,
    input   wire  [31:0]             reg_baud_rate,
    input   wire  [ 7:0]             reg_istatus_bits,
    output  wire  [ 7:0]             reg_ostatus_bits,
    input   wire  [BUS_WIDTH*8-1:0]  s_axis_tdata,
    input   wire                     s_axis_tvalid,
    output  wire                     s_axis_tready,
    output  wire  [BUS_WIDTH*8-1:0]  m_axis_tdata,
    output  wire                     m_axis_tvalid,
    input   wire                     m_axis_tready,
    output  wire                     tx,
    input   wire                     rx,
    output  wire                     dtr,
    input   wire                     dcd,
    input   wire                     dsr,
    output  wire                     rts,
    input   wire                     cts,
    input   wire                     ri
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
   * Device under test, axis_uart
   */
  axis_uart #(
    .CLOCK_SPEED(CLOCK_SPEED),
    .BUS_WIDTH(BUS_WIDTH),
    .RX_BAUD_DELAY(0),
    .TX_BAUD_DELAY(0)
  ) dut (
    .aclk(aclk),
    .arstn(arstn),
    .reg_parity(reg_parity),
    .reg_stop_bits(reg_stop_bits),
    .reg_data_bits(reg_data_bits),
    .reg_baud_rate(reg_baud_rate),
    .reg_istatus_bits(reg_istatus_bits),
    .reg_ostatus_bits(reg_ostatus_bits),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .tx(tx),
    .rx(rx),
    .dtr(dtr),
    .dcd(dcd),
    .dsr(dsr),
    .rts(rts),
    .cts(cts),
    .ri(ri)
  );
  
endmodule

