
export WORKDIR=$ROOTDIR
export QUARTUS_HOME=$QUARTUS_ROOTDIR
export QUARTUS_INSTALL_DIR=$QUARTUS_ROOTDIR
export QUARTUS_ROOTDIR_OVERRIDE=$QUARTUS_ROOTDIR
export IMPORT_IP_ROOTDIR=$QUARTUS_ROOTDIR/../ip
export DESIGNWARE_HOME=/p/psg/EIP/synopsys/vip_common/vip_W-2025.03C
export VERDIR=$WORKDIR/verification
export DESIGN=src
export DESIGN_DIR=$ROOTDIR/$DESIGN/
export UVM_HOME=$VCS_HOME/etc/uvm-1.2


echo "VCS                 " $VCS_HOME
echo "QUARTUS_HOME        " $QUARTUS_HOME
echo "IMPORT_IP_ROOTDIR   " $IMPORT_IP_ROOTDIR
echo "ROOTDIR             " $ROOTDIR
echo "DESIGNWARE_HOME     " $DESIGNWARE_HOME
echo "VERDIR              " $VERDIR
echo "DESIGN              " $DESIGN
echo "DESIGN_DIR          " $DESIGN_DIR
echo "UVM_HOME            " $UVM_HOME
