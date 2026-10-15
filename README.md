# RV32I Single-Cycle Processor

A modular Verilog implementation of a 32-bit RISC-V integer datapath, from individual building blocks through a single-cycle CPU. The repository includes component testbenches and a directed full-CPU regression so the design can be explored and checked at multiple levels.

## At a glance

- **HDL:** Verilog
- **Architecture:** RV32I integer subset, single-cycle datapath
- **Simulation:** ModelSim / Questa (`.do` scripts included)
- **Verification:** ALU, control, immediate, register-file, memory, PC, and CPU testbenches

## Architecture

```text
                         ┌──────────────────────┐
                         │   Control + Imm Gen  │
                         └──────────┬───────────┘
                                    │
┌─────┐  ┌──────────────┐  ┌────────▼───────┐  ┌─────┐  ┌────────────┐
│ PC  ├─►│ Instruction  ├─►│ Register File  ├─►│ ALU ├─►│ Data Memory│
└──▲──┘  │   Memory     │  └───────▲────────┘  └──┬──┘  └─────┬──────┘
   │     └──────────────┘          │              └──────┬─────┘      │
   └──────── branch/jump ──────────┴─────────────────────┴─ writeback ┘
```

Each instruction completes in one enabled rising-edge cycle. The CPU exposes instruction-memory loading ports for small programs, along with `pc`, `instruction`, and `illegal_instruction` signals for bring-up and debugging.

## Instruction coverage

The control and datapath implement RV32I integer register and immediate operations, `LUI`, `AUIPC`, conditional branches, `JAL`/`JALR`, and byte/halfword/word loads and stores. Supported memory instructions are `LB`, `LH`, `LW`, `LBU`, `LHU`, `SB`, `SH`, and `SW`.

Byte accesses support all byte offsets. Halfword and word accesses require natural alignment; misaligned accesses are ignored because the core does not implement traps. This is an educational RTL implementation, not a complete privileged or production RISC-V system.

## Repository map

| Path | Purpose |
| --- | --- |
| `CPU/Datapath/` | Program counter and integrated single-cycle CPU |
| `ALU/` | Arithmetic, logic, comparison, and shift units |
| `Control/` | Instruction decode and ALU control |
| `Immediate_Generator/` | I/S/B/U/J immediate extraction and sign extension |
| `Register_File/` | 32-register integer register file |
| `Memory/Instruction_Memory/` | Instruction storage and program loading interface |
| `Memory/Data_Memory/` | Byte-addressed data memory access |
| `Testbench/CPU/` | CPU, PC, and memory tests plus regression scripts |
| `docs/` | Datapath notes and additional design documentation |
| `sim/modelsim/` | ModelSim project files for component simulations |

## Run the full regression

1. Install ModelSim or Questa and open its Transcript in the repository root.
2. Run:

   ```tcl
   do Testbench/CPU/run_all_tests.do
   ```

The script compiles the RTL and testbenches, then runs the ALU, control, immediate-generator, register-file, instruction-memory, PC, data-memory, CPU smoke, and directed CPU regression tests. Check each test's `RESULT`/`STATUS` output for failures; the script's final line reports that all testbenches completed, not an aggregate pass calculation.

To run only the full CPU debug trace:

```tcl
do Testbench/CPU/run_single_cycle_cpu.do
```

That test prints instruction-level datapath signals and a final pass/fail summary. See [`docs/single-cycle-datapath.md`](docs/single-cycle-datapath.md) for instantiation, memory initialization, and debug details.

## Design notes

- `single_cycle_cpu` takes a synchronous reset and an execution enable. The register file's reset behavior is asynchronous.
- Instruction memory defaults to NOP-filled storage. Load instructions using `imem_load_we`, a byte-addressed `imem_load_address`, and `imem_load_instruction`.
- `IMEM_INIT_FILE` and `DMEM_INIT_FILE` parameters optionally load hexadecimal word images with `$readmemh`.
- Illegal instructions are reported through `illegal_instruction`; there is no exception/trap mechanism.

## Working with the RTL

The modules are organized by function so individual units can be inspected and simulated independently. Start with `CPU/Datapath/single_cycle_cpu.v` for the integration and `Control/control_unit.v` for the supported instruction decode. Testbenches are useful executable examples of instruction encoding and expected behavior.
