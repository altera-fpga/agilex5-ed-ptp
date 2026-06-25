# ########################################################################
# Copyright (C) 2025 Altera Corporation.
# SPDX-License-Identifier: MIT
# ########################################################################

#######################################
###  Environment setup for SM7PLUS PTP 
#######################################
#check for $ROOTDIR and set to cloned repo toplevel path
echo "Setting ROOTDIR"

if test -n "$BASH" ; then SCRIPT_NAME=$BASH_SOURCE
elif test -n "$TMOUT"; then SCRIPT_NAME=${.sh.file}
elif test -n "$ZSH_NAME" ; then SCRIPT_NAME=${(%):-%x}
elif test ${0##*/} = dash; then x=$(lsof -p $$ -Fn0 | tail -1); SCRIPT_NAME=${x#n}
else SCRIPT_NAME=$0
fi

SCRIPT_DIR="$(cd "$(dirname -- "$SCRIPT_NAME")" 2>/dev/null && pwd -P)"

export ROOTDIR=$(readlink -f ${SCRIPT_DIR}/../../)
unset SCRIPT_DIR

echo "ROOTDIR         " $ROOTDIR

source ${ROOTDIR}/verification/env/arc_resource_list.sh

ARC_RESOURCE="${PYTHON} ${GCC} ${CMAKE} ${VCS} ${QUARTUS_VER} ${VERDI}"

echo "arc shell ${ARC_RESOURCE}"
arc shell ${ARC_RESOURCE}

