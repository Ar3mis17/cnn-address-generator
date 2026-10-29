# CNN Address Generator and Verification

A SystemVerilog design that generates bank selections and local memory addresses for a three-pixel window while scanning a 256-row image using a four-bank memory organization.

## Overview

The address generator produces three consecutive pixel addresses per window position. Global columns are mapped to one of four memory banks, with the local address calculated from the row and bank-local column. The design also provides `pixel_out`, `out_valid`, `busy`, and `done` status signals.

## Design Features

- Four-bank memory mapping using the global column modulo four
- Local address generation using row and bank-local column
- Three consecutive pixel values assembled into a 24-bit output
- Active-low asynchronous reset
- `start`, `busy`, `out_valid`, and `done` control signals
- Testbench checks for bank and address mapping and full-scan completion

## Files

| File | Description |
|---|---|
| `cnn_addr_gen.sv` | RTL implementation of the CNN address generator |
| `tb_cnn_addr_gen.sv` | SystemVerilog testbench with behavioral four-bank SRAM and verification checks |

## Simulation

The testbench was run with Cadence Xcelium.

From the directory containing both source files, run:

```bash
xrun -sv cnn_addr_gen.sv tb_cnn_addr_gen.sv -top tb_cnn_addr_gen
```

To launch the simulator with the graphical interface, add `-gui`:

```bash
xrun -sv cnn_addr_gen.sv tb_cnn_addr_gen.sv -top tb_cnn_addr_gen -gui
```

## Verification Results

The supplied simulation log reports five successful bank/address mapping checks and successful completion of the full scan.

```text
PASS col=0 banks=0,1,2 addresses=320,320,320
PASS col=1 banks=1,2,3 addresses=320,320,320
PASS col=2 banks=2,3,0 addresses=320,320,321
PASS col=3 banks=3,0,1 addresses=320,321,321
PASS col=4 banks=0,1,2 addresses=321,321,321
FINAL STATE: row=0 col=253 busy=0 done=1 out_valid=0
PASS: scan completed in 65024 cycles
PASS: 5 mapping checks completed
Simulation complete via $finish
```

**Result:** All five mapping checks passed, and the scan completed in 65,024 cycles.

*Note: The results above are reproduced from the supplied simulation log; the simulation was not rerun while preparing this repository.*

<img width="940" height="459" alt="image" src="https://github.com/user-attachments/assets/71d6c1a3-dd94-48ff-88d3-3b1ee7c81a56" />

## Tools

- SystemVerilog
- Cadence Xcelium
- SimVision (optional, for waveform inspection)
