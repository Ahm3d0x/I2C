# I2C Master Controller (Verilog)

This project is an implementation of an I²C Master Controller using Verilog HDL. It was developed as the final project for the NTI Digital Design training.

## Team

- Ahmed Mohamed Attia
- Mohamed ...
- ...
- ...

## Project Overview

The project implements the master side of the I²C protocol as a finite state machine (FSM). The design is responsible for controlling the communication sequence between the processor and an external I²C slave device.

The implemented controller supports:

- Start condition generation
- 7-bit slave addressing
- Read / Write operation selection
- Byte transmission
- Byte reception
- ACK/NACK handling
- Multi-byte transfer
- Stop condition generation
- Busy, Ready and Error status signals
- Configurable SCL clock divider

## Files

```
master.v      -> I²C Master implementation
master_tb.v   -> Testbench with a simulated slave
```

## Testing

A complete testbench was written to verify the design.

The testbench covers:

- Write transaction
- Read transaction
- Multi-byte write
- Multi-byte read
- ACK response
- NACK response
- Error handling
- Start and Stop conditions

A simple slave model was created inside the testbench to generate ACKs and provide data during read operations.

## Notes

- Only the I²C Master was implemented.
- The I²C Slave device is not implemented as a standalone module.
- Slave behavior is emulated inside the testbench for verification purposes.

## Tools

- Verilog HDL
- ModelSim
