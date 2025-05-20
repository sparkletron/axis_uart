//******************************************************************************
// file:    axis_uart_tx.v
//
// author:  JAY CONVERTINO
//
// date:    2021/06/24
//
// about:   Brief
// UART TX from AXIS bus.
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
 * Module: axis_uart_tx
 *
 * AXIS UART TX, simple UART TX from AXI Streaming interface.
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
module axis_uart_tx #(
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
  
  `include "util_helper_math.vh"
  
  //start bit size... :)
  localparam integer start_bit = 1;
  //bits per transmission
  localparam integer bits_per_trans = start_bit + DATA_BITS + PARITY_ENA + STOP_BITS;
  //states
  // data capture
  localparam data_cap     = 3'd1;
  // parity generator
  localparam parity_gen   = 3'd2;
  // command processor
  localparam process      = 3'd3;
  // transmit data
  localparam trans        = 3'd4;
  // someone made a whoops
  localparam error        = 3'd0;
  //DATA BUS SIZE FOR BITS PER TRANS
  localparam TRANS_WIDTH = 2**clogb2(bits_per_trans)/8;

  //data reg for generated serial data
  reg [bits_per_trans-1:0]r_tx_data;
  //state machine
  reg [2:0]  state = error;
  //Register axis data to transmit later
  reg [DATA_BITS-1:0] r_data;
  //Register axis valid for uart clock domain state machine start
  reg r_s_axis_tvalid;
  // Hold UART clock when not in transmit state.
  reg r_uart_hold;
  // Load values into piso when ready to transmit.
  reg r_load;
  // PISO transmit output
  wire s_txd;
  // PISO counter value for keeping track of the amount of data being sent.
  wire [BUS_WIDTH*8-1:0]  piso_counter;
  
  assign s_axis_tready = (state == data_cap ? arstn : 0);

  assign uart_hold = r_uart_hold;
  
  //axis data input
  always @(posedge aclk) begin
    if(arstn == 1'b0) begin
      r_data <= 0;
      r_s_axis_tvalid <= 1'b0;
    end else begin
      r_data <= r_data;
      r_s_axis_tvalid <= r_s_axis_tvalid;
      
      case (state)
        data_cap:
        begin
          if(s_axis_tvalid == 1'b1)
          begin
            r_data <= s_axis_tdata[DATA_BITS-1:0];
            r_s_axis_tvalid <= s_axis_tvalid;
          end
        end
        trans:
        begin
          r_data <= 0;
          r_s_axis_tvalid <= 1'b0;
        end
      endcase
    end
  end
  
  //data processing
  always @(posedge uart_clk) begin
    if(uart_rstn == 1'b0) begin
      state       <= error;
      r_tx_data   <= 0;

      r_uart_hold <= 1'b1;
      r_load      <= 1'b0;
    end else begin
      case (state)
        //capture data from axis interface
        data_cap: begin
          state       <= data_cap;
          r_tx_data   <= 0;
          r_uart_hold <= 1'b1;
          
          if(r_s_axis_tvalid == 1'b1) begin
            state <= (PARITY_ENA >= 1 ? parity_gen : process);
          end
        end
        //generate parity using reduction operator
        parity_gen: begin
          state <= process;
          
          case (PARITY_TYPE)
            //odd parity
            1:
              r_tx_data[bits_per_trans-STOP_BITS-1] <= ^r_data ^ 1'b1;
            //mark parity
            2:
              r_tx_data[bits_per_trans-STOP_BITS-1] <= 1'b1;
            //space parity
            3:
              r_tx_data[bits_per_trans-STOP_BITS-1] <= 1'b0;
            //even parity
            default:
              r_tx_data[bits_per_trans-STOP_BITS-1] <= ^r_data;
          endcase
            
        end
        //process command data to setup data transmission
        process: begin
          if(piso_counter == 0)
          begin
            state <= trans;

            //insert start bit
            r_tx_data[start_bit-1:0] <= 1'b0;

            //insert stop bits
            r_tx_data[bits_per_trans-1:bits_per_trans-STOP_BITS] <= {STOP_BITS{1'b1}};

            //insert data
            r_tx_data[bits_per_trans-STOP_BITS-PARITY_ENA-1:bits_per_trans-STOP_BITS-PARITY_ENA-DATA_BITS] <= r_data;

            r_load <= 1'b1;
            r_uart_hold <= 1'b0;
          end
        end
        //transmit data, actually done in data output process below.
        trans: begin
          state <= trans;

          r_load <= 1'b0;
          r_uart_hold <= 1'b0;
          
          if((piso_counter == 0) && (uart_ena == 1'b1))
          begin
            r_uart_hold <= 1'b1;

            state <= data_cap;
          end
        end
        default:
          state <= data_cap;
      endcase
    end
  end
  
  //DELAY output of data
  generate
    if(DELAY > 0) begin
      //DELAY tx data
      reg [DELAY:0] DELAY_data = ~0;
      
      assign txd = DELAY_data[DELAY];
      
      always @(posedge uart_clk) begin
        if(uart_rstn == 1'b0) begin
          DELAY_data <= ~0;
        end else begin
          DELAY_data <= {DELAY_data[DELAY-1:0], s_txd};
        end
      end
    end else begin
      assign txd = s_txd;
    end
  endgenerate

  piso #(
    .BUS_WIDTH(TRANS_WIDTH),
    .COUNT_AMOUNT(bits_per_trans),
    .DEFAULT_RESET_VAL(1),
    .DEFAULT_SHIFT_VAL(1)
  ) inst_piso (
    .clk(uart_clk),
    .rstn(uart_rstn),
    .ena(uart_ena),
    .rev(1'b1),
    .load(r_load),
    .pdata({{TRANS_WIDTH*8-bits_per_trans{1'b1}}, r_tx_data}),
    .sdata(s_txd),
    .dcount(piso_counter)
  );
endmodule
