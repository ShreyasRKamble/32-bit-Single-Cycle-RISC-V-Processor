# Compile and load the integration test into ModelSim/Questa without running it.
# Run from the repository root with:
#   do Testbench/CPU/load_single_cycle_cpu.do
if {![file exists work/_info]} {
    vlib work
}

vlog -work work \
    Testbench/CPU/single_cycle_cpu_tb.v \
    Testbench/CPU/single_cycle_cpu_full_tb.v \
    Testbench/CPU/data_memory_tb.v \
    CPU/Datapath/single_cycle_cpu.v \
    CPU/Datapath/program_counter.v \
    Memory/Instruction_Memory/instruction_memory.v \
    Memory/Data_Memory/data_memory.v \
    Control/control_unit.v \
    Immediate_Generator/imm_gen.v \
    Register_File/register_file.v \
    ALU/alu_top.v \
    ALU/Arithmetic/arithmetic_unit.v \
    ALU/Arithmetic/cla_32bit.v \
    ALU/Arithmetic/cla_8bit.v \
    ALU/Logic/logic_unit.v \
    ALU/Shift_Rotate/shift_unit.v \
    ALU/Compare/compare_unit.v

vsim -voptargs=+acc work.single_cycle_cpu_tb
