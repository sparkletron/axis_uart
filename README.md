# AXIS UART
### UART TO AXIS

![image](docs/manual/img/AFRL.png)

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

### DOCUMENTATION
  For detailed usage information, please navigate to one of the following sources. They are the same, just in a different format.

  - [axis_uart.pdf](docs/manual/axis_uart.pdf)
  - [github page](https://johnathan-convertino-afrl.github.io/axis_uart/)

### DEPENDENCIES
#### Build
  - AFRL:utility:helper:1.0.0
  
#### Simulation
  - AFRL:simulation:axis_stimulator

#### PARAMETERS

  * BAUD_CLOCK_SPEED  - Clock speed of the baud clock. Best if it is a integer multiple of the baud rate, but does not have to be.
  * BAUD_RATE         - Baud rate of the input/output data for the core.
  * PARITY_ENA        - Enable parity check and generate.
  * PARITY_TYPE       - Set the parity type, 0 = even, 1 = odd, 2 = mark, 3 = space.
  * STOP_BITS         - Number of stop bits, 0 to crazy non-standard amounts.
  * DATA_BITS         - Number of data bits, 1 to crazy non-standard amounts.
  * RX_DELAY          - Delay in rx data input.
  * RX_BAUD_DELAY     - Delay in rx baud enable. This will delay when we sample a bit (default is midpoint when rx delay is 0).
  * TX_DELAY          - Delay in tx data output. Delays the time to output of the data.
  * TX_BAUD_DELAY     - Delay in tx baud enable. This will delay the time the bit output starts.

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
  
### FUSESOC

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core.

#### targets

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
