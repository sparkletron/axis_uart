# AXIS UART
### UART TO AXIS
---

   author: Jay Convertino   
   
   date: 2021.06.23  
   
   details: Interface UART data at some baud to a axi streaming 8 bit interface.   
   
   license: MIT   
   
---

### Version
#### Current
  - V1.0.0 - initial release

#### Previous
  - none

### Dependencies
#### Build
  - AFRL:utility:helper:1.0.0
  
#### Simulation
  - AFRL:simulation:axis_stimulator

### IP USAGE
#### INSTRUCTIONS

Simple UART core for TTL rs232 software mode data communications. No hardware handshake.  
This contains its own internal baud rate generator that creates an enable to allow data output  
or sampling. Baud clock and aclk can be the same clock.  

RTS/CTS is not implemented, it simply asserts it as if its always ready, and ignores CTS.

#### PARAMETERS
* BAUD_CLOCK_SPEED : DEFAULT = 2000000 : Clock speed of the baud clock. Best if it is a integer multiple of the baud rate, but does not have to be.
* BAUD_RATE : DEFAULT = 2000000 : Baud rate of the input/output data for the core.
* PARITY_ENA : DEFAULT = 1 : Enable parity check and generate.
* PARITY_TYPE : DEFAULT = 1 : Set the parity type, 0 = even, 1 = odd, 2 = mark, 3 = space.
* STOP_BITS : DEFAULT = 1 : Number of stop bits, 0 to crazy non-standard amounts.
* DATA_BITS : DEFAULT = 8 : Number of data bits, 1 to crazy non-standard amounts.
* RX_DELAY : DEFAULT = 0 : Delay in rx data input.
* RX_BAUD_DELAY : DEFAULT = 0 : Delay in rx baud enable. This will delay when we sample a bit (default is midpoint when rx delay is 0).
* TX_DELAY : DEFAULT = 0 : Delay in tx data output. Delays the time to output of the data.
* TX_BAUD_DELAY : DEFAULT = 0 : Delay in tx baud enable. This will delay the time the bit output starts.

### COMPONENTS
#### SRC

* axis_uart.v
* axis_uart_tx.v
* axis_uart_rx.v
* uart_baud_gen.v
  
#### TB

* tb_uart.v
* tb_uart_tx.v
* tb_uart_rx.v
* tb_uart_baud_gen.v
  
### fusesoc

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core.

#### TARGETS

* RUN WITH: (fusesoc run --target=sim VENDER:CORE:NAME:VERSION)
  - default (for IP integration builds)
  - sim
  - sim_rand_data
  - sim_rand_ready_rand_data
  - sim_8bit_count_data
  - sim_rand_ready_8bit_count_data
  - sim_baud
  - sim_rx
  - sim_tx
