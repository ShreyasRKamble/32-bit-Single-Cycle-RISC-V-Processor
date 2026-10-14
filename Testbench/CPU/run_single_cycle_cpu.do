# Run from the repository root in the ModelSim/Questa transcript:
#   do Testbench/CPU/run_single_cycle_cpu.do
# +acc keeps internal datapath signals visible for waveform/debug inspection.
do Testbench/CPU/load_single_cycle_cpu.do
onfinish stop
run -all
