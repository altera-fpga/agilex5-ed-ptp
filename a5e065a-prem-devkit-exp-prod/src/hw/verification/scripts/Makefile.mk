#-----------------------------------------------------------------------------
# Copyright 2024 Intel Corporation.
#
# THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
# COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Description
#-----------------------------------------------------------------------------

SCRIPTS_DIR = $(WORKDIR)/verification/scripts
VCDFILE = $(WORKDIR)/scripts/vpd_dump.key
SIMDIR = $(VERDIR)/sim
VIPDIR = $(SIMDIR)/vip/axi_vip
TESTNAME = sm_ptp_base_test

IP_LIST = $(VERDIR)/tb/ip_list.f
RTL_LIST = $(VERDIR)/tb/rtl_list.f

ifdef CFG_RAND
  CFG_SW = +CONFIG_RAND=1
endif

VLOG_OPT_TB = -kdb -ntb_opts uvm-1.2 -lca -sverilog -full64 +vcs+lic+wait -l ./../sim/vlog.log -Mdir=./../sim/output/csrc +warn=noBCNACMBP -CFLAGS +error+1000 -debug_acc -timescale=1ns/1fs +libext+.v+.sv -debug_acc -notice -work work

# Defines list
ifdef HSSI_25G
VLOG_OPT_TB += +define+__ALTERA_STD__METASTABLE_SIM +define+UVM_DISABLE_AUTO_ITEM_RECORDING +define+UVM_NO_DEPRECATED +define+UVM_PACKER_MAX_BYTES=1500000 +define+UVM_VERDI_NO_COMPWAVE +define+SVT_UVM_TECHNOLOGY +define+SYNOPSYS_SV +define+SVT_FSDB_ENABLE +define+NUM_QSFP_2 +define+P7521SERDES_UX_SIMSPEED +define+MAC_SRD_CFG_25G +SET_25G
VLOG_OPT_TB += +define+SVT_AXI_MAX_NUM_MASTERS_1 +define+SVT_AXI_MAX_NUM_SLAVES_1 +define+SVT_AXI_MAX_ADDR_WIDTH=64 +define+SVT_AXI_MAX_DATA_WIDTH=256 +define+SM_PTP_MAX_PORTS=2 +define+SIM_MODE +define+SM_PTP_CFG_25G 
else ifdef HSSI_10G
VLOG_OPT_TB += +define+__ALTERA_STD__METASTABLE_SIM +define+UVM_DISABLE_AUTO_ITEM_RECORDING +define+UVM_NO_DEPRECATED +define+UVM_PACKER_MAX_BYTES=1500000 +define+UVM_VERDI_NO_COMPWAVE +define+SVT_UVM_TECHNOLOGY +define+SYNOPSYS_SV +define+SVT_FSDB_ENABLE +define+NUM_QSFP_2 +define+P7521SERDES_UX_SIMSPEED +define+MAC_SRD_CFG_25G +SET_10G
VLOG_OPT_TB += +define+SVT_AXI_MAX_NUM_MASTERS_1 +define+SVT_AXI_MAX_NUM_SLAVES_1 +define+SVT_AXI_MAX_ADDR_WIDTH=64 +define+SVT_AXI_MAX_DATA_WIDTH=256 +define+SM_PTP_MAX_PORTS=2 +define+SIM_MODE 
endif

ifndef NUM_CHANN
  VLOG_OPT_TB += +define+NUM_CHANNELS_2 +define+SM_PTP_NUM_PORTS=2
else
  VLOG_OPT_TB += +define+SM_PTP_NUM_PORTS=$(NUM_CHANN)
  ifeq ($(NUM_CHANN),2)
    VLOG_OPT_TB += +define+NUM_CHANNELS_2
  endif
endif

ifdef PORT_LB
	VLOG_OPT_TB += +define+SM_PTP_PORT_LEVEL_LOOPBACK
endif

# Include list
VLOG_OPT_TB += +incdir+./
VLOG_OPT_TB += +incdir+$(VERDIR)/sim/vip/axi_vip/src/sverilog/vcs
VLOG_OPT_TB += +incdir+$(VERDIR)/sim/vip/axi_vip/include/sverilog
VLOG_OPT_TB += +incdir+$(VERDIR)/sim/vip/axi_vip/src/verilog/vcs
VLOG_OPT_TB += +incdir+$(VERDIR)/sim/vip/axi_vip/include/verilog
VLOG_OPT_TB += -y $(VERDIR)/sim/vip/axi_vip/src/sverilog/vcs
VLOG_OPT_TB += -y $(VERDIR)/sim/vip/axi_vip/src/verilog/vcs
VLOG_OPT_TB += +incdir+$(VERDIR)/tb
VLOG_OPT_TB += +incdir+$(VERDIR)/tb/tests
VLOG_OPT_TB += +incdir+$(VERDIR)/tb/tests/sequences
VLOG_OPT_TB += +incdir+$(VERDIR)/tb/env
VLOG_OPT_TB += +incdir+$(VERDIR)/tb/env/cfg
VLOG_OPT_TB += +incdir+$(UVM_HOME)
VLOG_OPT_TB += +incdir+$(UVM_HOME)/vcs 
VLOG_OPT_TB += +incdir+$(DESIGNWARE_HOME)/vip/svt/amba_svt/latest/sverilog/src/vcs/
VLOG_OPT_TB += +incdir+$(VERDIR)/qsfp_controller/i2c_bfm/altera_i2cslave_to_avlmm_bridge_1910/sim
VLOG_OPT_TB += +incdir+$(VERDIR)/qsfp_controller/tests/sequences
VLOG_OPT_TB += +incdir+$(VERDIR)/qsfp_controller/tests
VLOG_OPT_TB += +incdir+$(VERDIR)/qsfp_controller/testbench
VLOG_OPT_TB += +incdir+$(VERDIR)/qsfp_controller/qsfp_slave_uvc

# File lists
VLOG_OPT_TB += -f $(RTL_LIST) -f $(VERDIR)/tb/tb_list.f
# DPI specific includes
VLOG_OPT_TB += $(QUARTUS_INSTALL_DIR)/eda/sim_lib/quartus_dpi.c +define+QUARTUS_ENABLE_DPI_FORCE $(QUARTUS_INSTALL_DIR)/eda/sim_lib/simsf_dpi.cpp

ifdef SIMPROFILE
VLOG_OPT_TB += -simprofile time
endif

VCS_ELAB_OPT  = -ntb_opts uvm-1.2 $(QUARTUS_INSTALL_DIR)/eda/sim_lib/quartus_dpi.c $(QUARTUS_INSTALL_DIR)/eda/sim_lib/simsf_dpi.cpp
VCS_ELAB_OPT +=  +vcs+lic+wait +plusarg_save +vcs+lic+wait -full64 +vcs+nostdout -lca -assert enable_diag -assert svaext -o simv +lint=TFIPC-L +lint=PCWM +warn=noSVA-LDRF -j4 +warn=noLCA_FEATURES_ENABLED +warn=noDFLT_OPT +warn=noSVA-TIDE +warn=noOSVF-NPVIUFPI +warn=noUFTMD +error+1000 -debug_access+all+classdbg+f -debug_region=lib+cell +ntb_solver_debug=serial+extract +ntb_solver_debug_filter=12 -CFLAGS -DVCS -l vcs.log -sverilog -debug_access+
ifdef SIMPROFILE
VCS_ELAB_OPT += -simprofile time
endif

SIMV_OPT = +UVM_TESTNAME=$(TESTNAME) -l ./simulate_$(SEQNAME).log run +seqname=$(SEQNAME)
SIMV_OPT += $(QUARTUS_INSTALL_DIR)/eda/sim_lib/quartus_dpi.c

ifndef VERBOSITY
SIMV_OPT += +UVM_VERBOSITY=UVM_LOW
else
SIMV_OPT += +UVM_VERBOSITY=$(VERBOSITY)
endif

ifdef DUMP
    VLOG_OPT_TB += +define+VCS_DUMP
    #VCS_OPT += -debug_access+all
    #SIMV_OPT += -ucli -i $(VCDFILE)
endif

ifdef COV
    #VLOG_OPT += +define+COV -cm line+cond+fsm+tgl+branch -cm_name $(WORKDIR)/sim/ -cm_dir simv.vdb
    #VCS_OPT  += -cm line+cond+fsm+tgl+branch -cm_name $(WORKDIR)/sim/ -cm_dir simv.vdb
    #SIMV_OPT += -cm line+cond+fsm+tgl+branch -cm_name $(TESTNAME) -cm_dir regression.vdb
    VLOG_OPT_TB += -cm line+cond+fsm+tgl+branch -cm_name $(SIMDIR) -cm_dir simv.vdb
    VCS_ELAB_OPT  += -cm line+cond+fsm+tgl+branch -cm_name $(SIMDIR) -cm_dir simv.vdb
    SIMV_OPT += -cm line+cond+fsm+tgl+branch -cm_name $(TESTNAME) -cm_dir $(TESTNAME).vdb
endif

ifndef SEED
    SIMV_OPT += +ntb_random_seed_automatic
else
    SIMV_OPT += +ntb_random_seed=$(SEED)
endif

ifdef SIMPROFILE
SIMV_OPT += -simprofile time
endif

#setup: create_sim_dir
setup: update_files create_sim_dir

update_files:
ifdef HSSI_25G
	sed -i '/dependant/d' ../../synth/top.qsf
	sed -i '/MAC_SRD_CFG_25G/a\set_global_assignment -name VERILOG_MACRO SM_PTP_CFG_25G' ../../synth/top.qsf
	sed -i '/SOURCE_FILE/a\set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/ethernet_hip_25G.ip' ../../synth/top.qsf
	sed -i '/ethernet_hip/a\set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/gts_systempll_25G.ip' ../../synth/top.qsf
	cp $(SYNTH_DIR)/ip_list.tcl $(SCRIPTS_DIR)/ip_list.tcl
	perl ip_script.pl HSSI_25G=1
else ifdef HSSI_10G
	sed -i '/dependant/d' ../../synth/top.qsf
	sed -i '/SOURCE_FILE/a\set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/ethernet_hip.ip' ../../synth/top.qsf
	sed -i '/ethernet_hip/a\set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/gts_systempll.ip' ../../synth/top.qsf
	cp $(SYNTH_DIR)/ip_list.tcl $(SCRIPTS_DIR)/ip_list.tcl
	perl ip_script.pl HSSI_10G=1
endif

create_sim_dir:
	sh rename_prev_sim.sh
	mkdir $(VERDIR)/sim

cmplib:	setup gen_qip parse_dut_files gen_ip_lib gen_vip

build: compile_tb elab

gen_qip:
	cd $(SIMDIR) && sh $(SCRIPTS_DIR)/generate_ip.sh $(IP_LIST)
	cd $(SIMDIR) && sh $(SCRIPTS_DIR)/gen_ip_sim_setup.sh $(IP_LIST)

parse_dut_files:
	perl parser_for_ghrd_top.pl $(DESIGN_DIR)
	perl parser_for_qsys_top.pl $(DESIGN_DIR)

gen_ip_lib:
	cd $(VERDIR)/sim && mkdir ip_libraries
	cp -f $(SIMDIR)/synopsys/vcsmx/synopsys_sim.setup $(SIMDIR)/ip_libraries/
	cd $(SIMDIR)/ip_libraries && sh $(SIMDIR)/synopsys/vcsmx/vcsmx_setup.sh SKIP_SIM=1 SKIP_ELAB=1 QSYS_SIMDIR=$(SIMDIR) QUARTUS_INSTALL_DIR=$(QUARTUS_HOME) USER_DEFINED_COMPILE_OPTIONS="+define+__ALTERA_STD__METASTABLE_SIM"

gen_vip:
	mkdir -p $(SIMDIR)/vip/axi_vip/
	@$(DESIGNWARE_HOME)/bin/dw_vip_setup -path $(SIMDIR)/vip/axi_vip/ -e amba_svt/tb_axi_svt_uvm_basic_sys -svtb

compile_rtl:
	cd $(SIMDIR) && vlogan $(VLOG_OPT_RTL)

compile_tb:
	rsync -avz --checksum --ignore-times $(SIMDIR)/ip_libraries/* $(SIMDIR)/
	cd $(SIMDIR) && vlogan -ntb_opts uvm-1.2 -sverilog
	cd $(SIMDIR) && vlogan $(VLOG_OPT_TB)

elab:
	cd $(SIMDIR) && vcs $(VCS_ELAB_OPT) tb_top 

run:
	sh rename_prev_seqdir.sh $(SEQNAME)
	cd $(VERDIR)/sim/ && mkdir -p $(SEQNAME) && cd $(SEQNAME) && cp -f ../*.hex . && cp -f ../*.mif . && ../simv $(CFG_SW) $(SIMV_OPT)

run_dve:
	dve -vpd $(SIMDIR)/$(SEQNAME)/dump.vpd -session $(SCRIPTS_DIR)/session.dump.vpd.tcl &
