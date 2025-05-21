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
module axis_uart_rx #(
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
  // parity generator
  localparam parity_gen   = 3'd3;
  // transmit data
  localparam trans        = 3'd4;
  // someone made a whoops
  localparam error        = 0;
  //DATA BUS SIZE FOR BITS PER TRANS
  localparam TRANS_WIDTH = 2**clogb2(bits_per_trans)/8;
  
  //s_rxd
  wire s_rxd;
  //wire_uart_rstn
  wire wire_uart_rstn;
  // SIPO counter value for keeping track of the amount of data being sent.
  wire [BUS_WIDTH*8-1:0]  sipo_counter;
  //data from SIPO
  wire [bits_per_trans-1:0] s_data;

  //parity bit storage
  reg parity_bit;
  //parity error storage
  reg r_parity_err;
  reg r_frame_err;
  //state machine
  reg [2:0]  state = error;
  //data to transmit
  reg [DATA_BITS-1:0] data;
  //positive sample of the rxd signal
  reg r_ps_rxd;
  //negedge sample of the rxd signal
  reg r_ns_rxd;
  //SIPO control
  reg r_load;

  //reg to wire
  reg [BUS_WIDTH*8-1:0] r_m_axis_tdata;
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
          r_m_axis_tdata  <= {{BUS_WIDTH*8-DATA_BITS{1'b0}}, data};
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
      state           <= start_wait;
      data            <= 0;
      parity_bit      <= 0;
      r_parity_err    <= 0;
      r_frame_err     <= 0;
      r_uart_hold     <= 1'b1;
      r_load          <= 1'b1;
    end else begin
      case (state)
        start_wait: begin
          state         <= start_wait;
          data          <= 0;
          parity_bit    <= 0;
          r_load        <= 1'b1;
          r_uart_hold   <= r_uart_hold;

          // watch for falling edge for start bit
          if((r_ps_rxd == 1'b1) && (s_rxd == 1'b0) && (sipo_counter == 0)) begin
            state       <= data_cap;
            r_uart_hold <= 1'b0;
          end
        end
        //capture data from interface (rx input below)
        data_cap: begin
          state         <= data_cap;
          data          <= 0;
          parity_bit    <= 0;
          r_load        <= 1'b0;
          r_uart_hold   <= r_uart_hold;
          
          //once we hit bits_per_trans, we can goto data combine.
          if(sipo_counter == bits_per_trans)
          begin
            state <= (PARITY_ENA >= 1'b1 ? parity_gen : trans);

            data <= s_data[start_bit+DATA_BITS-1:start_bit];

            parity_bit <= s_data[bits_per_trans-STOP_BITS-1];

            //pull stop bit, if it is zero, frame error.
            r_frame_err <= ~s_data[bits_per_trans-1];

            r_load      <= 1'b1;
            r_uart_hold <= 1'b1;
          end
        end
        //compare to parity bit of incomming data and store in command
        parity_gen: begin
          state <= trans;

          r_parity_err  <= 1'b0;

          //check if parity matches, if not do not output data.
          case (PARITY_TYPE)
            //odd parity
            1:
              if(^data ^ 1'b1 ^ parity_bit)
              begin
                r_parity_err <= 1'b1;
              end
            //mark parity
            2:
              if(parity_bit != 1'b1)
              begin
                r_parity_err <= 1'b1;
              end
            //space parity
            3:
              if(parity_bit != 1'b0)
              begin
                r_parity_err <= 1'b1;
              end
            //even parity
            default:
              if(^data ^ parity_bit)
              begin
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

  //always sample rx data on negedge clock, feed into SIPO which always does posedge
  always @(negedge uart_clk)
  begin
    r_ns_rxd <= s_rxd;
  end

  always @(posedge uart_clk)
  begin
    r_ps_rxd <= s_rxd;
  end
  
  //DELAY input of data
  generate
    if(DELAY > 0) begin : gen_DELAY_ENABLED
      //DELAYs
      reg [DELAY:0] DELAY_rx;
      
      assign s_rxd = DELAY_rx[DELAY];
      
      always @(posedge uart_clk) begin
        if(uart_rstn == 1'b0) begin
          DELAY_rx <= ~0;
        end else begin
          DELAY_rx <= {DELAY_rx[DELAY-1:0], rxd};
        end
      end
    end else begin : gen_DELAY_DISABLED
      assign s_rxd = rxd;
    end
  endgenerate

  sipo #(
    .BUS_WIDTH(TRANS_WIDTH),
    .COUNT_AMOUNT(bits_per_trans)
  ) inst_sipo (
    .clk(uart_clk),
    .rstn(uart_rstn),
    .ena(uart_ena),
    .rev(1'b1),
    .load(r_load),
    .pdata(s_data),
    .sdata(r_ns_rxd),
    .dcount(sipo_counter)
  );

endmodule
