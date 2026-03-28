alias nvc='nvc --std=2008 --work=work_nvc'
nvc -a *.vhd
nvc -e multiplier_tb
nvc -r multiplier_tb --stop-time=3sec --format=fst --dump-arrays --wave=waveforms.fst