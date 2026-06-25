////////////////////////////////////////////////////////////////////////////////////////////////
IMP NOTE TO RUN TESTS in SMPLUS PTP DESIGN UVM TB.
-------------------------------------------------------
There are 2 variants in SMPLUS PTP DESIGN. i.e 10G,25G
Below steps needs to be done for each variant in a separate xterm.
Two variants cannot be run in a single xterm. This needs to be taken care primarily.
////////////////////////////////////////////////////////////////////////////////////////////////
Please execute the below steps before executing UVM TB:
. source <user path>/<repo_name>/src/hw/verification/env/env.sh
. source <user path>/<repo_name>/src/hw/verification/env/setup.sh


to run single UVM test:

1. cd $ROOTDIR/verification/scripts

2. Below is a one time run that needs to be given when compiling
   the DUT for the first time or if there is any change in the IP
  
   10G SMPLUS PTP DESIGN
   make -f Makefile.mk cmplib HSSI_10G=1
   25G SMPLUS PTP DESIGN
   make -f Makefile.mk cmplib HSSI_25G=1

3. Run below make command to compile and elaborate the DUT and TESTBENCH
   
   10G SMPLUS PTP DESIGN
   make -f Makefile.mk build HSSI_10G=1
   25G SMPLUS PTP DESIGN
   make -f Makefile.mk build HSSI_25G=1

4. Run below command to run a sequence

  make -f Makefile.mk run SEQNAME=<sequence name>
  Eg:
  make -f Makefile.mk run SEQNAME=sm_ptp_h2d0_path_seq


5. Dumping a waveform
  Please add option DUMP=1 to steps 3 and 4 or step 5 to enable waveform dumping

  Eg 1:
  make -f Makefile.mk build DUMP=1
  make -f Makefile.mk run SEQNAME=sm_ptp_h2d0_path_seq DUMP=1
  
  Eg 2:
  make -f Makefile.mk build run SEQNAME=sm_ptp_h2d0_path_seq DUMP=1

6. Enabled DV for 1 port / 2port Design
   . All the tests run 2 port design by default.
   . To run 1 port design, please add NUM_CHANN=1 during 'build' step
     in step 3 and step 5
     Eg:
        make -f Makefile.mk build NUM_CHANN=1
        make -f Makefile.mk build run SEQNAME=sm_ptp_h2d0_path_seq NUM_CHANN=1

7. Results directory
  . The test results are stored at $ROOTDIR/verification/sim
  . Everytime step 2 is re-run, the previous sim directory gets renamed to sim.# and a new sim directory gets created
  . The logs and waveform are dumped in $ROOTDIR/verification/sim/<sequence name> directory
  . If same sequence is re-run, the previous result dir for that sequence gets renamed to $ROOTDIR/verification/sim/<sequence name>.#
    and a new $ROOTDIR/verification/sim/<sequence name> directory gets created

***************************************************
List of tests that  can be run standalone:

// DMA only port 0 -> 1 sequences
// In 1 channel DUT, port 0 -> 0 loopback is tested
sm_ptp_h2d0_90B_seq
sm_ptp_h2d0_path_seq
sm_ptp_h2d0_fifo_depth_cover_seq
sm_ptp_h2d0_path_poll_en_seq
sm_ptp_h2d0_pkt_err_seq

// Below sequences are only applicable for 2 port design

// DMA only port 1 -> 0 sequences
sm_ptp_h2d1_90B_seq
sm_ptp_h2d1_path_seq
sm_ptp_h2d1_fifo_depth_cover_seq
sm_ptp_h2d1_path_poll_en_seq

// Both DMA ports enabled sequences
// Only applicable for 2 port design
sm_ptp_all_dma_ports_traffic_seq
sm_ptp_all_dma_ports_64B_traffic_seq.sv"

How to Run UVM Regressions?:
*****************************
1) cd $PTP_ROOTDIR/scripts
#Note: Sequence list for regression run is taken from the regress script itself
2)  Need to pass the arguments as per the variant
#  10G SMPLUS PTP Design
   "perl regress_run.pl nocov 10G"
#  25G SMPLUS PTP Design
   "perl regress_run.pl nocov 25G"
3) Command to run regression with coverage
#  10G SMPLUS PTP Design
   "perl regress_run.pl cov 10G"
#  25G SMPLUS PTP Design
   "perl regress_run.pl cov 25G"
4) Results are created in a sim directory ($ROOTDIR/sim/<sequence name>).Check stimulate_$seqname.log for Simulation result
5) To generate coverage report for a regression, execute:
   #“urg -dir <$VERDIR/sim/simv.vdb> <$VERDIR/sim/regression.vdb> -format both -dbname final.vdb”
yy   #Note: The default report directory is “urgReport” and coverage database (regression.vdb) will be present in the same directory
6)To open DVE of a single regression or testcase, execute:  ”dve -full64 -cov -covdir simv.vdb regression.vdb &”
7)To open DVE of a merged regression, execute: ”dve -full64 -cov -covdir <dirname.vdb> &
8)To load the coverage report, execute: “firefox urgReport/dashboard.html”

