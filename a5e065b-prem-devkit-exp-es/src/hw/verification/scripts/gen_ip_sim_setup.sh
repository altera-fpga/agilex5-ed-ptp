#!/bin/bash
# Copyright 2020 Intel Corporation.
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

SCRIPTNAME="$(basename -- "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"
ROOTDIR="$ROOTDIR"
IP_FLIST=$1

if [ -z $IP_FLIST ]; then
   echo "Usage: sh gen_ip_sim_setup.sh <ip file list>"
   exit -1
fi

set -xe

echo "markdtet gen_ip_sim_setup.sh Started!"

# Get IP .spd file list
ip_spd=""
spd_lst=""
first=1

for ip in `grep -vE '^(\s*$|#)' $IP_FLIST`
do
   echo "markdtet gen_ip_sim_setup.sh in LOOP!"
   ip_dir=$(dirname -- $ip)
   ip_file=$(basename -- $ip)
   ip_name=$(echo $ip_file | sed -e "s/\..*$//g")

   spd="${ip_dir}/${ip_name}/${ip_name}.spd"
   spd_tmp="${ip_dir}/${ip_name}/${ip_name}_tmp.spd"
   cp $ROOTDIR/$spd $ROOTDIR/$spd_tmp
   sed '/\<device name=/d' -i $ROOTDIR/$spd_tmp

   if [ $first == 1 ]; then
      spd_lst="$ROOTDIR/$spd_tmp"
   else
      spd_lst="${spd_lst}, $ROOTDIR/$spd_tmp"
   fi
   first=0;
done

echo $spd_lst > spd.lst
#ip-make-simscript --spd="${spd_lst}" --use-relative-paths --output-directory=./qip_sim_script --device-family=agilex5
ip-make-simscript --spd="${spd_lst}" --use-relative-paths --device-family=agilex5
#ip-setup-simulation --quartus-project=../../src/sm_soc_devkit_ghrd/ghrd_a5ed065bb32ae6sr0.qpf --revision=$REV --output-directory=./qip_sim_script --use-relative-paths 

rm -rf spd.lst

set +x
for ip in `grep -vE '^(\s*$|#)' $IP_FLIST`
do
   ip_dir=$(dirname -- $ip)
   ip_file=$(basename -- $ip) 
   ip_name=$(echo $ip_file | sed -e "s/\..*$//g") 
   rm -rf $ROOTDIR/${ip_dir}/${ip_name}/${ip_name}_tmp.spd
done

echo "markdtet gen_ip_sim_setup.sh DONE!"
