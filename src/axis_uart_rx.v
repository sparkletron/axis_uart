//******************************************************************************
// file:    axis_uart_rx.v
//
// author:  JAY CONVERTINO
//
// date:    2021/06/24
//
// about:   Brief
// UART RX to AXIS bus.
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
 * Module: axis_uart_rx
 *
 * AXIS UART, simple UART with AXI Streaming interface.
 *
 * Parameters:
 *
 *   PARITY_ENA       - Enable Parity for the data in and out.
 *   PARITY_TYPE      - Set the parity type, 0 = even, 1 = odd, 2 = mark, 3 = space.
 *   STOP_BITS        - Number of stop bits, 0 to crazy non-standard amounts.
 *   DATA_BITS        - Number of data bits, 1 to crazy non-standard amounts.
 *   DELAY            - Delay in rx data input.
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
 *   uart_hold      - Output to hold clock till in receive state.
 *   rxd            - receive for UART (input from TX)
 */
module axis_uart_rx #(
    parameter PARITY_ENA  = 0,
    parameter PARITY_TYPE = 0,
    parameter STOP_BITS   = 1,
    parameter DATA_BITS   = 8,
    parameter DELAY       = 0
  ) 
  (
    input                       aclk,
    input                       arstn,
    output                      parity_err,
    output                      frame_err,
    output  [DATA_BITS-1:0]     m_axis_tdata,
    output                      m_axis_tvalid,
    input                       m_axis_tready,
    input                       uart_clk,
    input                       uart_rstn,
    input                       uart_ena,
    output                      uart_hold,
    input                       rxd
  );
  
  `include "util_helper_math.vh"
  
  //start bit size... :)
  localparam integer start_bit = 1;
  //bits per transmission
  localparam integer bits_per_trans = start_bit + DATA_BITS + PARITY_ENA + STOP_BITS;
  //states
  // start bit detect
  localparam start_wait   = 3'd1;
  // data capture
  localparam data_cap     = 3'd2;
  // reduce data
  localparam data_reduce  = 3'd3;
  // parity generator
  localparam parity_gen   = 3'd4;
  // transmit data
  localparam trans        = 3'd5;
  // someone made a whoops
  localparam error        = 0;
  
  //wire_rxd
  wire wire_rxd;
  //wire_uart_rstn
  wire wire_uart_rstn;

  //data reg
  reg [bits_per_trans-1:0]reg_data;
  //parity bit storage
  reg parity_bit;
  //parity error storage
  reg r_parity_err;
  reg r_frame_err;
  //state machine
  reg [2:0]  state = error;
  //data to transmit
  reg [DATA_BITS-1:0] data;
  //counters
  reg [clogb2(bits_per_trans)-1:0]  trans_counter;
  reg [clogb2(bits_per_trans)-1:0]  prev_trans_counter;
  //previous states
  reg r_rxd;

  //reg to wire
  reg [DATA_BITS-1:0]   r_m_axis_tdata;
  reg                   r_m_axis_tvalid;
  reg                   r_uart_hold;

  //registers to external wires
  assign parity_err     = r_parity_err;
  assign frame_err      = r_frame_err;
  assign m_axis_tdata   = r_m_axis_tdata;
  assign m_axis_tvalid  = r_m_axis_tvalid;
  assign uart_hold      = r_uart_hold;

  //axis data output
  always @(posedge aclk) begin
    if(arstn == 1'b0) begin
      r_m_axis_tdata  <= 0;
      r_m_axis_tvalid <= 0;
    end else begin
      r_m_axis_tdata <= r_m_axis_tdata;
      r_m_axis_tvalid<= r_m_axis_tvalid;
      case (state)
        //once the state machine is in transmisson state, begin data output
        trans: begin
          r_m_axis_tdata  <= data;
          r_m_axis_tvalid <= 1'b1;
        end
        //are we ready kids???? EYYY EYYY CAPTIAN....OHHHHH WHO LIVES IN A PINEAPPLE UNDER THE SEA.
        //...*cough* if we are ready, the data was captured. 0 it out to avoid duplicates.
        default: begin
          if(m_axis_tready == 1'b1) begin
            r_m_axis_tdata  <= 0;
            r_m_axis_tvalid <= 0;
          end
        end
        endcase
    end
  end
            
  //data processing
  always @(posedge aclk) begin
    if(arstn == 1'b0) begin
      state           <= error;
      data            <= 0;
      parity_bit      <= 0;
      r_parity_err    <= 0;
      r_frame_err     <= 0;
      r_rxd           <= 1'b1;
      r_uart_hold     <= 1'b1;
    end else begin
      r_rxd <= wire_rxd;

      case (state)
        start_wait: begin
          state         <= start_wait;
          data          <= 0;
          parity_bit    <= 0;
          r_uart_hold   <= r_uart_hold;

          // watch for falling edge for start bit
          if((r_rxd == 1'b1) && (wire_rxd == 1'b0) && (trans_counter == 0)) begin
            state <= data_cap;
            r_uart_hold <= 1'b0;
          end
        end
        //capture data from interface (rx input below)
        data_cap: begin
          state         <= data_cap;
          data          <= 0;
          parity_bit    <= 0;
          r_uart_hold   <= r_uart_hold;
          
          //once we hit bits_per_trans-1, we can goto data combine.
          if((trans_counter == bits_per_trans-1) && (prev_trans_counter == bits_per_trans-1)) begin
            state       <= data_reduce;
            r_uart_hold <= 1'b1;
          end
        end
        data_reduce: begin
          state <= (PARITY_ENA >= 1'b1 ? parity_gen : trans);
          
          data <= reg_data[start_bit+DATA_BITS-1:start_bit];
          
          parity_bit <= reg_data[bits_per_trans-STOP_BITS-1];

          //pull stop bit, if it is zero, frame error.
          r_frame_err <= ~reg_data[bits_per_trans-1];
        end
        //compare to parity bit of incomming data and store in command
        parity_gen: begin
          state <= trans;
          
          r_parity_err <= 1'b0;

          //check if parity matches, if not do not output data.
          case (PARITY_TYPE)
            //odd parity
            1:
              if(^data ^ 1'b1 ^ parity_bit)
              begin
                state <= data_cap;
                r_parity_err <= 1'b1;
              end
            //mark parity
            2:
              if(parity_bit != 1'b1)
              begin
                state <= data_cap;
                r_parity_err <= 1'b1;
              end
            //space parity
            3:
              if(parity_bit != 1'b0)
              begin
                state <= data_cap;
                r_parity_err <= 1'b1;
              end
            //even parity
            default:
              if(^data ^ parity_bit)
              begin
                state <= data_cap;
                r_parity_err <= 1'b1;
              end
          endcase
        end
        //transmit data, actually done in data output process below.
        trans:
          state <= start_wait;
        //error state, goto data_cap
        default:
          state <= start_wait;
      endcase
    end
  end
  
  //DELAY input of data
  generate
    if(DELAY > 0) begin
      //DELAYs
      reg [DELAY:0] DELAY_rx;
      
      assign wire_rxd = DELAY_rx[DELAY];
      
      always @(negedge uart_clk) begin
        if(uart_rstn == 1'b0) begin
          DELAY_rx <= ~0;
        end else begin
          DELAY_rx <= {DELAY_rx[DELAY-1:0], rxd};
        end
      end
    end else begin
      assign wire_rxd = rxd;
    end
  endgenerate

  //Sample data, with a aync clear high using r_uart_hold
  always @(negedge uart_clk or posedge r_uart_hold) begin
    if(uart_rstn == 1'b0) begin
      reg_data            <= 0;
      trans_counter       <= 0;
      prev_trans_counter  <= 0;
    end else if(r_uart_hold == 1'b1) begin
      trans_counter <= 0;
      prev_trans_counter <= 0;
    end else begin
      // capture data in data_cap state only
      case(state)
        data_cap: begin
          if(uart_ena == 1'b1) begin
            reg_data[trans_counter] <= wire_rxd;

            trans_counter <= trans_counter + 1;

            prev_trans_counter <= trans_counter;
          end

          //once bits_per_trans-1 hold counter
          if(trans_counter == bits_per_trans-1) begin
            trans_counter <= bits_per_trans-1;
          end
        end
        default: begin
          trans_counter <= 0;
          prev_trans_counter <= 0;
        end
      endcase
    end
  end

endmodule
