//******************************************************************************
// file:    uart_baud_gen.v
//
// author:  JAY CONVERTINO
//
// date:    2021/06/24
//
// about:   Brief
// Generate UART BAUD rate by dividing input clock rate using modulo divide (subtract and carry remainder)
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
 * Module: uart_baud_gen
 *
 * Baud rate generator
 *
 * Parameters:
 *
 *   BAUD_CLOCK_SPEED - This is the aclk frequency in Hz
 *   BAUD_RATE        - Serial Baud, this can be any value including non-standard.
 *   DELAY            - Delay in rx data input.
 *
 * Ports:
 *
 *   uart_clk       - Clock used for BAUD rate generation
 *   uart_rstn      - Negative reset for UART, for anything clocked on uart_clk
 *   uart_hold      - Output to hold clock till in receive state.
 *   uart_ena       - Enable UART data processing from RX.
 */
module uart_baud_gen #(
    parameter BAUD_CLOCK_SPEED = 2000000,
    parameter BAUD_RATE   = 115200,
    parameter DELAY       = 0
  ) 
  (
    input   uart_clk,
    input   uart_rstn,
    input   uart_hold,
    output  uart_ena
  );
  
  `include "util_helper_math.vh"
  
  reg [clogb2(BAUD_CLOCK_SPEED):0] counter;
  
  reg r_uart_ena = 0;
  
  //baud enable generator
  always @(posedge uart_clk) begin
    if(uart_rstn == 1'b0) begin
      counter     <= BAUD_CLOCK_SPEED/2;
      r_uart_ena  <= 0;
    end else begin
      counter     <= (uart_hold == 1'b1 ? (BAUD_CLOCK_SPEED-BAUD_RATE) : counter + BAUD_RATE);
      r_uart_ena  <= 1'b0;
      
      if(counter >= (BAUD_CLOCK_SPEED-BAUD_RATE)) begin
        counter     <= counter % ((BAUD_CLOCK_SPEED-BAUD_RATE) == 0 ? 1 : (BAUD_CLOCK_SPEED-BAUD_RATE));
        r_uart_ena  <= ~uart_hold;
      end
    end
  end
  
  //DELAY output of uart_ena
  generate
    if(DELAY > 0) begin
      //DELAYs
      reg [DELAY:0] DELAY_uart_ena;
      
      assign uart_ena = DELAY_uart_ena[DELAY];
      
      always @(posedge uart_clk) begin
        if(uart_rstn == 1'b0) begin
          DELAY_uart_ena <= 0;
        end else begin
          DELAY_uart_ena <= {DELAY_uart_ena[DELAY-1:0], r_uart_ena};
        end
      end
    end else begin
      assign uart_ena = r_uart_ena;
    end
  endgenerate
endmodule
