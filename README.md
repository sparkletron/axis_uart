# AXIS UART
### UART TO AXIS
---

![image](docs/manual/img/AFRL.png)

---

  author: Jay Convertino   
  
  date: 2021.06.23  
  
  details: Interface UART data at some baud to a axi streaming 8 bit interface.   
  
  license: MIT   
   
  Actions:  

  [![Lint Status](../../actions/workflows/lint.yml/badge.svg)](../../actions)  
  [![Manual Status](../../actions/workflows/manual.yml/badge.svg)](../../actions)  
  
---

### Version
#### Current
  - v1.5.0 - update to SIPO/PISO core for serial in/out.

#### Previous
  - V1.0.0 - initial release
  - none

### DOCUMENTATION
  For detailed usage information, please navigate to one of the following sources. They are the same, just in a different format.

  - [axis_uart.pdf](docs/manual/axis_uart.pdf)
  - [github page](https://johnathan-convertino-afrl.github.io/axis_uart/)

### PARAMETERS

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
  * BUS_WIDTH         - AXIS data width in bytes.

### COMPONENTS
#### SRC

* axis_uart.v
* axis_uart_tx.v
* axis_uart_rx.v
  
#### TB

* tb_uart_tx.v
* tb_uart_rx.v
* tb_cocotb_rx
* tb_cocotb_tx
* tb_cocotb_full
  
### FUSESOC

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core.

#### targets

* RUN WITH: (fusesoc run --target=sim VENDER:CORE:NAME:VERSION)
  - default (for IP integration builds)
  - lint
  - sim_cocotb_full
  - sim_cocotb_rx
  - sim_cocotb_tx
  - sim_rx
  - sim_tx

