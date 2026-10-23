SHELL := /bin/bash

.PHONY: sim synth clean

sim:
	bash scripts/run_iverilog.sh

synth:
	bash scripts/run_yosys_synth.sh

clean:
	rm -rf build reports/generated
