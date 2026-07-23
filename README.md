# I2C Master Controller

An implementation of an **I²C Master Controller** using **Verilog HDL**. This project was developed as the final project for the **NTI Digital Design Training**.
The design implements the master side of the I²C protocol and was verified using a self-developed Verilog testbench with a simulated slave device.

---
Name : Ahmed Mohamed Attia Mohamed
---

## Features

- I²C Start Condition
- 7-bit Slave Address + R/W Bit
- Write Transaction
- Read Transaction
- Multi-byte Transfer
- ACK / NACK Detection
- Error Handling
- Busy & Data Ready Flags
- Stop Condition
- Configurable SCL Clock Divider
- FSM-Based Architecture

---

## Project Structure

```
.
├── master.v              # I2C Master
├── master_tb.v           # Testbench
├── RTL_view.pdf          # RTL schematic
├── i2c con output.txt    # Simulation log
├── tb_result/
│   ├── test1_w.png
│   ├── test1_con.png
│   ├── test2_w.png
│   ├── test2_con.png
│   ├── test3_w.png
│   ├── test3_con.png
│   ├── test4_w.png
│   ├── test4_con.png
│   ├── test5_w.png
│   └── test5_con.png
└── README.md
```

---

## Design Overview

The controller is implemented as a **Finite State Machine (FSM)** that manages the complete I²C communication sequence.

Implemented states include:

- Idle
- Start Condition
- Address Transmission
- Address ACK
- Data Write
- Data Read
- Data ACK
- Multiple Byte Transfer
- Stop Condition

---

## Verification

A complete Verilog testbench was developed to verify the controller functionality.

Instead of implementing a complete I²C Slave module, a simple slave model was created inside the testbench to emulate:

- Address ACK
- Data ACK
- Read Data Generation
- NACK Generation

This allows the master to be fully verified without requiring a separate slave implementation.

---

# Test Results

## Test 1 — Single Write Transaction

### Waveform

![Test 1 Write](tb_result/test1_w.png)

### Console Output

![Test 1 Console](tb_result/test1_con.png)

---

## Test 2 — Multi-byte Write Transaction

### Waveform

![Test 2 Write](tb_result/test2_w.png)

### Console Output

![Test 2 Console](tb_result/test2_con.png)

---

## Test 3 — Single Read Transaction

### Waveform

![Test 3 Read](tb_result/test3_w.png)

### Console Output

![Test 3 Console](tb_result/test3_con.png)

---

## Test 4 — Multi-byte Read Transaction

### Waveform

![Test 4 Read](tb_result/test4_w.png)

### Console Output

![Test 4 Console](tb_result/test4_con.png)

---

## Test 5 — NACK and Error Handling

### Waveform

![Test 5 Error](tb_result/test5_w.png)

### Console Output

![Test 5 Console](tb_result/test5_con.png)

---

## Tools
- ModelSim
- Intel Quartus Prime Lite 
- GitHub
---


## Notes

- This repository contains **only the I²C Master implementation**.
- Due to the limited project time, the I²C Slave was not implemented as a standalone module.
- A simple slave model was created inside the testbench to emulate slave behavior for verification.
- The testbench covers write, read, multi-byte transfer, ACK/NACK handling, and error scenarios.

---

## Author

**Ahmed Mohamed Attia**

Faculty of Engineering, Zagazig University  
Electronics and Communications Engineering

Email: ahm3d.m.attia@gmail.com

Electronics and Communications Engineering

GitHub: https://github.com/Ahm3d0x
