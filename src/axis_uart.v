//******************************************************************************
// file:    axis_uart.v
//
// author:  JAY CONVERTINO
//
// date:    2021/06/24
//
// about:   Brief
// V2 upgrade to UART that will create a full UART compatible IP DTE device.
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

`resetall
`default_nettype none

`timescale 1ns/100ps

/*
 * Module: axis_uart
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
module axis_uart #(
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
  
  localparam uart_state_idle = 1'b0;
  localparam uart_state_busy = 1'b1;
  
  wire  s_parity_ena;
  
  wire  [31:0]  s_rx_dcount;
  wire  [31:0]  s_tx_dcount;
  
  wire  [BUS_WIDTH*8-1:0] s_rx_buffer;
  
  wire  s_tx_uart_ena;
  wire  s_rx_uart_ena;
  
  wire  [31:0] temp;
  
  wire  s_rx_hold;
  
  reg   r_rx;
  
  reg   r_tx_uart_clr;
  reg   r_rx_uart_clr;
  
  reg   r_tx_load;
  reg   r_rx_load;
  
  reg   r_tx_hold;
  reg   r_rx_hold;
  
  reg   r_tx_frame_error;
  reg   r_rx_frame_error;
  reg   r_rx_parity_error;
  reg   r_rx_stop_bit_error;
  
  reg   [BUS_WIDTH*8-1:0] r_tx_buffer;
  
  reg   [31:0] r_baud_rate;
  
  reg   [BUS_WIDTH*8-1:0] r_m_axis_tdata;
  reg                     r_m_axis_tvalid;
  
  reg   r_tx_state;
  reg   r_rx_state;
  
  reg   rr_temp;
  
  assign s_axis_tready = (r_tx_state == uart_state_idle ? cts: 1'b0) & arstn;
  
  assign s_parity_ena = (reg_parity > 0 ? 1'b1 : 1'b0);
  
  assign s_rx_hold = rx & r_rx_hold;
  
  assign rts = m_axis_tready;
  
  assign m_axis_tdata = r_m_axis_tdata;
  
  assign m_axis_tvalid = r_m_axis_tvalid;
  
  assign reg_ostatus_bits = {1'b0, r_rx_stop_bit_error, r_tx_frame_error, r_rx_frame_error, r_rx_parity_error, dcd, dsr, ri};
  
  assign dtr = reg_istatus_bits[0];
  
  assign temp = (reg_stop_bits+reg_data_bits+s_parity_ena+1);

  //Group: Instantiated Modules
  /*
   * Module: uart_baud_gen_tx
   *
   * Generates TX BAUD rate for UART modules using modulo divide method.
   */
  mod_clock_ena_gen #(
    .CLOCK_SPEED(CLOCK_SPEED),
    .DELAY(TX_BAUD_DELAY)
  ) uart_baud_gen_tx (
    .clk(aclk),
    .rstn(arstn),
    .start0(1'b1),
    .clr(s_axis_tready),
    .hold(r_tx_hold),
    .rate(r_baud_rate),
    .ena(s_tx_uart_ena)
  );
  
  /*
   * Module: uart_baud_gen_rx
   *
   * Generates RX BAUD rate for UART modules using modulo divide method.
   */
  mod_clock_ena_gen #(
    .CLOCK_SPEED(CLOCK_SPEED),
    .DELAY(RX_BAUD_DELAY)
  ) uart_baud_gen_rx (
    .clk(aclk),
    .rstn(arstn),
    .start0(1'b0),
    .clr(r_rx_uart_clr),
    .hold(s_rx_hold),
    .rate(r_baud_rate),
    .ena(s_rx_uart_ena)
  );
  
  /*
   * Module: inst_piso
   *
   * take axis input parallel data at bus size, and output the word to the UART TX
   */
  piso #(
    .BUS_WIDTH(BUS_WIDTH),
    .DEFAULT_RESET_VAL(1),
    .DEFAULT_SHIFT_VAL(1)
  ) inst_piso (
    .clk(aclk),
    .rstn(arstn),
    .ena(s_tx_uart_ena),
    .rev(1'b1),
    .load(r_tx_load),
    .pdata(r_tx_buffer),
    .sdata(tx),
    .dcount(s_tx_dcount)
  );

  /*
   * Module: inst_sipo
   *
   * take UART RX data, and output the word to the parallel data bus.
   */
  sipo #(
    .BUS_WIDTH(BUS_WIDTH)
  ) inst_sipo (
    .clk(aclk),
    .rstn(arstn),
    .ena(s_rx_uart_ena),
    .rev(1'b1),
    .load(r_rx_load),
    .pdata(s_rx_buffer),
    .sdata(rx),
    .dcount(s_rx_dcount)
  );
  
  //set baud rate when idle
  always @(posedge aclk)
  begin
    if(arstn == 1'b0)
    begin
      r_baud_rate <= reg_baud_rate;
    end else begin
      if(s_tx_dcount <= (BUS_WIDTH*8-(reg_stop_bits+reg_data_bits+s_parity_ena+1))) 
      begin
        r_baud_rate <= reg_baud_rate;
      end
      
      if(s_rx_dcount >= (BUS_WIDTH*8-(reg_stop_bits+reg_data_bits+s_parity_ena+1)))
      begin
        r_baud_rate <= reg_baud_rate;
      end
    end
  end
  
  //TX data transmit
  always @(posedge aclk)
  begin
    if(arstn == 1'b0)
    begin
      r_tx_load         <= 1'b0;
      r_tx_hold         <= 1'b1;
      r_tx_frame_error  <= 1'b0;
      
      r_tx_state  <= uart_state_idle;
      
      r_tx_buffer <= 0;
    end else begin      
      case (r_tx_state)
        uart_state_idle:
        begin
          r_tx_frame_error <= (reg_stop_bits+reg_data_bits+s_parity_ena+1 > BUS_WIDTH*8 ? 1'b1 : 1'b0);
          
          r_tx_state <= uart_state_idle;
          
          if(s_axis_tvalid == 1'b1 && cts == 1'b1)
          begin
            r_tx_state <= uart_state_busy;
            
            r_tx_load   <= 1'b1;
            r_tx_hold   <= 1'b0;
            
            //insert data bits with and fill with ones for stop bits
            r_tx_buffer[BUS_WIDTH*8-1:1] <= s_axis_tdata[BUS_WIDTH*8-2:0] | (~0 << reg_data_bits + s_parity_ena);;
            //insert start bit
            r_tx_buffer[0] <= 1'b0;
            
            //insert parity if enabled
            if(s_parity_ena == 1'b1)
            begin
              case (reg_parity)
                //odd parity
                1:
                begin
                  r_tx_buffer[reg_data_bits+1] <= ^(s_axis_tdata & ~(~0 << reg_data_bits)) ^ 1'b1;
                end
                //even parity
                2:
                begin
                  r_tx_buffer[reg_data_bits+1] <= ^(s_axis_tdata & ~(~0 << reg_data_bits));
                end
                //mark parity
                3:
                begin
                  r_tx_buffer[reg_data_bits+1] <= 1'b1;
                end
                //space parity
                default:
                begin
                  r_tx_buffer[reg_data_bits+1] <= 1'b0;
                end
              endcase
            end
          end
        end
        //uart busy state
        default:
        begin
          r_tx_state <= uart_state_busy;
          
          r_tx_load <= 1'b0;
          
          //check to see if we have pushed out all data, counter starts at full BUS_WIDTH not word transmit length.
          if(s_tx_dcount <= (BUS_WIDTH*8-(reg_stop_bits+reg_data_bits+s_parity_ena+1)) && (s_tx_uart_ena == 1'b1))
          begin
            r_tx_hold  <= 1'b1;
            r_tx_state <= uart_state_idle;
          end
        end
      endcase
    end
  end
  
  //RX data receive
  always @(posedge aclk)
  begin
    if(arstn == 1'b0)
    begin
      r_rx_uart_clr <= 1'b1;
      r_rx_load     <= 1'b0;
      r_rx_hold     <= 1'b1;
      
      r_m_axis_tdata  <= 0;
      r_m_axis_tvalid <= 1'b0;
      
      r_rx_parity_error   <= 1'b0;
      r_rx_frame_error    <= 1'b0;
      r_rx_stop_bit_error <= 1'b0;
      
      r_rx <= 1'b1;
      r_rx_state <= uart_state_idle;
    end else begin      
      r_rx <= rx;
      
      r_rx_uart_clr <= 1'b0;
      
      case (r_rx_state)
        uart_state_idle:
        begin
          
          r_rx_state <= uart_state_idle;
          
          r_rx_frame_error <= (reg_stop_bits+reg_data_bits+s_parity_ena+1 > BUS_WIDTH*8 ? 1'b1 : 1'b0);
      
          if(m_axis_tready == 1'b1)
          begin
            r_m_axis_tdata      <= 0;
            r_m_axis_tvalid     <= 1'b0;
            r_rx_parity_error   <= 1'b0;
            r_rx_stop_bit_error <= 1'b0;
          end
          
          if(r_rx == 1'b1 && rx == 1'b0)
          begin
            r_rx_hold     <= 1'b0;
            r_rx_load     <= 1'b0;
            r_rx_state <= uart_state_busy;
          end
        end
        //uart busy state
        default:
        begin
          r_rx_state <= uart_state_busy;
          
          if((s_rx_dcount >= reg_stop_bits+reg_data_bits+s_parity_ena+1) && (s_rx_uart_ena == 1'b1))
          begin
            r_rx_state <= uart_state_idle;
            
            r_m_axis_tdata  <= (s_rx_buffer >> (BUS_WIDTH*8-(reg_data_bits+1))) & ~(~0 << reg_data_bits);
            r_m_axis_tvalid <= 1'b1;
            
            r_rx_uart_clr <= 1'b1;
            r_rx_hold     <= 1'b1;
            r_rx_load     <= 1'b1;
            
            r_rx_parity_error  <= 1'b0;
            
            //stop bit should be 1, if its 0 then an error has happened.
            r_rx_stop_bit_error <= ~s_rx_buffer[reg_stop_bits+reg_data_bits+s_parity_ena];

            //insert parity if enabled
            if(s_parity_ena == 1'b1)
            begin
              //check if parity matches, if not do not output data.
              case (reg_parity)
                //odd parity
                1:
                begin
                  if(^(s_rx_buffer & ~(~0 << reg_data_bits)) ^ 1'b1 ^ s_rx_buffer[reg_data_bits+1])
                  begin
                    r_rx_parity_error <= 1'b1;
                  end
                end
                //even parity
                2: 
                begin
                  if(^(s_rx_buffer & ~(~0 << reg_data_bits))  ^ s_rx_buffer[reg_data_bits+1])
                  begin
                    r_rx_parity_error <= 1'b1;
                  end
                end
                //mark parity
                3:
                begin
                  if(s_rx_buffer[reg_data_bits+1] != 1'b1)
                  begin
                    r_rx_parity_error <= 1'b1;
                  end
                end
                //space parity
                default:
                begin
                  if(s_rx_buffer[reg_data_bits+1] != 1'b0)
                  begin
                    r_rx_parity_error <= 1'b1;
                  end
                end
              endcase
            end
          end
        end
      endcase
    end
  end

endmodule

`resetall
