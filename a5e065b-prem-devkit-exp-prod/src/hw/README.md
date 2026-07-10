# Agilex™ 5 10GbE Ethernet System Example Design Build Scripts


# Dependency

- Altera&reg; Quartus&reg; Prime Pro software suite (See [Release Notes](../../#Project-Details) for the supported version)


# Build Steps

 1. Compile design and generate configuration (sof) file:
    
    The synth folder contains a Makefile and the Quartus Project.The Makefile support various compile options such as 
    - make compile - runs the compile stage of Quartus
    - make synth   - runs synthesis stage of Quartus
    - make all     - runs a full Quartus compile including the Assembler
    Running <make> will print out all the options supported
    
    Alternatively, if using the GUI is preferred, the qpf file can be opened in Quartus and compile options selected there.
    ```
    cd synth/
	  make all
    ```

# Programming Files Generation Steps <UPDATE BELOW>

 1. File link of [`u-boot-spl-dtb.hex`](../sw/artifacts/u-boot-spl-dtb.hex) 

 2. Generate `top.{core,hps}.rbf` including U-Boot SPL:

    ```
    cd synth/
    quartus_pfg -c -o hps=on -o hps_path=../../sw/artifacts/u-boot-spl-dtb.hex output_files/top.sof output_files/top.rbf
    ```
3. Generate QSPI Flash Image file
   The QSPI image will contain the FPGA configuration data and the HPS FSBL and it can be built using the following command.
	``` bash
	cd $TOP_FOLDER 
	quartus_pfg -c src/hw/synth/output_files/top.sof \
	bin/top.jic \
	-o hps_path=src/sw/artifacts/u-boot-spl-dtb.hex \
	-o device=MT25QU128 \
	-o flash_loader=A5ED065BB32AE4S \
	-o mode=ASX4 \
	-o hps=1
		```

