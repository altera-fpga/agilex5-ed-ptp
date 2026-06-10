***************************************************
Please make sure to source the below resources and 
set all the environment variables from setup.sh as below
in the given order
1. set resources
  a. VCS version vcs/U-2023.03-SP2-1 vcs-vcsmx-lic
  b. QUARTUS VERSION 25.3
  c. Synopsys_verdi version synopsys_verdi/U-2023.03-SP2-1
  d. ROOTDIR - <user path>/<repo name>/src/hw
2. The below env variables will be set by 
   source <user path>/<repo name>/src/hw/verification/setup.sh
  . WORKDIR=$ROOTDIR
  . QUARTUS_HOME=$QUARTUS_ROOTDIR
  . QUARTUS_INSTALL_DIR=$QUARTUS_ROOTDIR
  . DESIGNWARE_HOME=<synopsys vip location>
  . VERDIR=$WORKDIR/verification
  . DESIGN=src
  . DESIGN_DIR=$ROOTDIR/$DESIGN/
  . UVM_HOME=$VCS_HOME/etc/uvm-1.2
***************************************************

to run single UVM test:

1. cd $ROOTDIR/verification/scripts

2. Below is a one time run that needs to be given when compiling
   the DUT for the first time or if there is any change in the IP

   make -f Makefile.mk cmplib

3. Run below make command to compile and elaborate the DUT and TESTBENCH
   
   make -f Makefile.mk build

4. Run below command to run a sequence

  make -f Makefile.mk run SEQNAME=<sequence name>
  Eg:
  make -f Makefile.mk run SEQNAME=sm_ptp_h2d0_90B_seq

5. Steps 3 and 4 can be combined and run in a single step

  make -f Makefile.mk build run SEQNAME=sm_ptp_h2d0_90B_seq

6. Dumping a waveform
  Please add option DUMP=1 to steps 3 and 4 or step 5 to enable waveform dumping

  Eg 1:
  make -f Makefile.mk build DUMP=1
  make -f Makefile.mk run SEQNAME=sm_ptp_h2d0_90B_seq DUMP=1
  
  Eg 2:
  make -f Makefile.mk build run SEQNAME=sm_ptp_h2d0_90B_seq DUMP=1

7. Results directory
  . The test results are stored at $ROOTDIR/verification/sim
  . Everytime step 2 is re-run, the previous sim directory gets renamed to sim.# and a new sim directory gets created
  . The logs and waveform are dumped in $ROOTDIR/verification/sim/<sequence name> directory
  . If same sequence is re-run, the previous result dir for that sequence gets renamed to $ROOTDIR/verification/sim/<sequence name>.#
    and a new $ROOTDIR/verification/sim/<sequence name> directory gets created

***************************************************
List of tests that  can be run standalone:

// Showcases the scenario where traffic is generated from all the channels of
// dma port port 0.
// For each channel, the payload length for each eth packet is 90B.
sm_ptp_h2d0_90B_seq

// This sequence enables prefetcher for all channels of both ports 1 and 2
// of DMA. For each channel, fixed number of descriptors are configured with
// 64B payload length for each.
sm_ptp_all_dma_ports_64B_traffic_seq

// This sequence showcases transactions from user client 0 and 1
// Both user clients are configured to generate random number of ethernet packets.
sm_ptp_user1_user0_seq

// Showcases the scenario where traffic is generated from all the dma ports
// and user client  ports simultaneously
sm_ptp_all_ports_traffic_seq

// This sequence exercises few CSR addresses to showcase reads to register
// space of hssi block
sm_ptp_hssi_csr_seq

sm_ptp_qsfp0_poll_enable_seq
