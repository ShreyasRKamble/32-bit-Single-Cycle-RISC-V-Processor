# Run from the repository root in ModelSim/Questa:
#   do Testbench/CPU/run_all_tests.do
# Each testbench prints its own PASS/FAIL summary to the Transcript.
if {![file exists work/_info]} {
    vlib work
}

vlog -work work \
    ALU/alu_top_tb.v \
    ALU/alu_top.v \
    ALU/Arithmetic/arithmetic_unit.v \
    ALU/Arithmetic/cla_32bit.v \
    ALU/Arithmetic/cla_8bit.v \
    ALU/Logic/logic_unit.v \
    ALU/Shift_Rotate/shift_unit.v \
    ALU/Compare/compare_unit.v \
    Control/control_unit.v \
    Control/control_unit_tb.v \
    Control/control_alu_integration_tb.v \
    Immediate_Generator/imm_gen.v \
    Immediate_Generator/imm_gen_tb.v \
    Register_File/register_file.v \
    Register_File/register_file_tb.v \
    Memory/Instruction_Memory/instruction_memory.v \
    Memory/Data_Memory/data_memory.v \
    CPU/Datapath/program_counter.v \
    Testbench/CPU/instruction_memory_tb.v \
    Testbench/CPU/program_counter_tb.v \
    Testbench/CPU/data_memory_tb.v \
    CPU/Datapath/single_cycle_cpu.v \
    Testbench/CPU/single_cycle_cpu_tb.v \
    Testbench/CPU/single_cycle_cpu_full_tb.v

proc run_test {top_name} {
    puts "\n\n============================================================"
    puts " RUNNING $top_name"
    puts "============================================================"
    vsim -voptargs=+acc work.$top_name
    # Keep $finish from prompting to close the ModelSim GUI.
    onfinish stop
    run -all
}

run_test alu_top_tb
run_test control_unit_tb
run_test control_alu_integration_tb
run_test imm_gen_tb
run_test register_file_tb
run_test instruction_memory_tb
run_test program_counter_tb
run_test data_memory_tb
run_test single_cycle_cpu_tb
run_test single_cycle_cpu_full_tb

puts "\n============================================================"
puts " ALL PROJECT TESTBENCHES COMPLETED"
puts " Inspect each RESULT/STATUS line above for failures."
puts "============================================================"
