Altera Agilex™ 5 (SM7+ PDK) Precision Time Protocol System Example Design - Hardware
Dependency
Altera Quartus Prime (See Release Notes for the supported version)
Build Steps
Compile design and generate configuration (sof) file:

The synth folder contains a Makefile and the Quartus Project.The Makefile support various compile options such as:

make compile - runs the compile stage of Quartus
make synth - runs synthesis stage of Quartus
make all - runs a full Quartus compile including the Assembler Running make will print out all the options supported
The Design can be compiled to specificate datarate with or w/o ANLT option using two methods as explaied below.

Config File Method:

The project Makefile reads src/hw/synth/config.txt to determine the Ethernet data rate for the Ethernet Subsystem IPs. Open config.txt and set the configuration to the desired Ethernet data rate support as shown in the snippet below.

The config text file will have below config for 25GbE;

Configuration=25G_NON_ANLT

Command Method:

cd synth/

make all CONFIG=25G_NON_ANLT     - Runs a full Quartus compile including the Assembler for 25G_NON_ANLT

Programming Files Generation Steps
Download u-boot-spl-dtb.hex from sw/artifacts/u-boot-spl-dtb.hex.

Generate top{core,hps}.rbf including U-Boot SPL:

cd synth/
quartus_pfg -c -o hps=on -o hps_path=../../sw/artifacts/u-boot-spl-dtb.hex output_files/top.sof output_files/top.rbf
