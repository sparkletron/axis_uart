# UTIL AXIS UART
### UART TO AXIS
---

   author: Jay Convertino   
   
   date: 2021.06.23  
   
   details: Interface UART data at some baud to a axi streaming 8 bit interface.   
   
   license: MIT   
   
---

![rtl_img](./rtl.png)

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
* baud_clock_speed : DEFAULT = 2000000 : Clock speed of the baud clock. Best if it is a integer multiple of the baud rate, but does not have to be.
* baud_rate : DEFAULT = 2000000 : Baud rate of the input/output data for the core.
* parity_ena : DEFAULT = 1 : Enable parity check and generate.
* parity_type : DEFAULT = 1 : Set the parity type, 0 = even, 1 = odd, 2 = mark, 3 = space.
* stop_bits : DEFAULT = 1 : Number of stop bits, 0 to crazy non-standard amounts.
* data_bits : DEFAULT = 8 : Number of data bits, 1 to crazy non-standard amounts.
* rx_delay : DEFAULT = 0 : Delay in rx data input.
* rx_baud_delay : DEFAULT = 0 : Delay in rx baud enable. This will delay when we sample a bit (default is midpoint when rx delay is 0).
* tx_delay : DEFAULT = 0 : Delay in tx data output. Delays the time to output of the data.
* tx_baud_delay : DEFAULT = 0 : Delay in tx baud enable. This will delay the time the bit output starts.

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
