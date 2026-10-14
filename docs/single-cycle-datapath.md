# Single-cycle RISC-V datapath

`CPU/Datapath/single_cycle_cpu.v` connects the existing RV32I building blocks
into a working single-cycle core. One rising edge advances the PC and commits
any register-file or data-memory write.

```text
 PC ──► Instruction memory ──► Control + immediate generator
 ▲                                 │
 │                           Register file ──► ALU ──► Data memory
 │                                 ▲             │           │
 └──── branch / jump target ◄──────┘             └─ writeback┘
```

Supported instruction groups are integer register and immediate operations,
`LW`/`SW`, conditional branches, `JAL`/`JALR`, `LUI`, and `AUIPC`. The current
memory interface intentionally supports aligned word loads and stores only.

## Hookup

Compile the modules in the repository's existing directories, including
`Memory/Data_Memory/data_memory.v` and `CPU/Datapath/single_cycle_cpu.v`.
Instantiate `single_cycle_cpu` with a clock, synchronous reset, and enable.
Instruction memory starts filled with NOPs; load a small program through
`imem_load_we`, `imem_load_address` (byte address), and
`imem_load_instruction`. Tie `imem_load_we` low during normal execution.

Optional `IMEM_INIT_FILE` and `DMEM_INIT_FILE` parameters load hexadecimal
word images with `$readmemh`. `pc`, `instruction`, and `illegal_instruction`
are provided as useful bring-up signals.

## ModelSim / Questa debug run

From the repository root, enter this in the ModelSim transcript:

```tcl
do Testbench/CPU/run_single_cycle_cpu.do
```

The testbench prints one row per executed instruction with PC, instruction,
register indexes and operands, immediate, ALU result, control enables, and
selected next PC. A second line shows ALU flags, memory activity, writeback,
and illegal-instruction status. It finishes with x0-x7, data-memory words 0-3,
and a clear `RESULT: PASS` or `RESULT: FAIL` summary. `+acc` is enabled in the
run script so internal datapath signals remain available to the Wave window.

To run the component checks and both CPU integration tests in one session,
use:

```tcl
do Testbench/CPU/run_all_tests.do
```

This runs the ALU, decoder, control-to-ALU, immediate generator, register
file, instruction memory, PC, data memory, CPU smoke test, and directed full
CPU regression. Each testbench prints its own summary to the Transcript.
The script sets ModelSim's `onfinish stop` behavior so `$finish` ends each
test cleanly without prompting to close the simulator.
