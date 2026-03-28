alias nvc='nvc --std=2008 --work=work_nvc'
nvc -a *.vhd
nvc -e adder_tb
nvc -r adder_tb --stop-time=3sec --format=fst --dump-arrays --wave=waveforms_adder.fst