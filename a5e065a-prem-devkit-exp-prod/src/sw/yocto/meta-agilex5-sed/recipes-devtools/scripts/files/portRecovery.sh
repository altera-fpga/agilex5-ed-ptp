#!/bin/sh

# Usage: portRecovery.sh <eth1|eth2> [--tx] [--rx] [--global]
# Example: portRecovery.sh eth2 --tx --rx
# If no option is given, defaults to --global

BASE_ADDR=0x40200000

if [ $# -lt 1 ]; then
    echo "Usage: $0 <eth1|eth2> [--tx] [--rx] [--global]"
    exit 1
fi

PORT_STR=$1
shift

if [[ "$PORT_STR" == "eth1" ]]; then
    PORT=0
elif [[ "$PORT_STR" == "eth2" ]]; then
    PORT=1
else
    echo "Port must be 'eth1' or 'eth2'"
    exit 1
fi

# Bit positions for eth1/eth2
TX_BITS=(2 3)
RX_BITS=(4 5)
GLOBAL_BITS=(0 1)

reset_val=0x3F

# Function to clear bit at position $1, but never bits 6 or 7
clear_bit() {
    local val=$1
    local bit=$2
    if [[ $bit -ge 6 ]]; then
        echo $val
    else
        echo $((val & ~(1 << bit)))
    fi
}

# If no option is given, default to --global
if [ $# -eq 0 ]; then
    reset_val=$(clear_bit $reset_val ${GLOBAL_BITS[$PORT]})
else
	while [[ $# -gt 0 ]]; do
	    key="$1"
	    case $key in
		--tx)
		    reset_val=$(clear_bit $reset_val ${TX_BITS[$PORT]})
		    ;;
		--rx)
		    reset_val=$(clear_bit $reset_val ${RX_BITS[$PORT]})
		    ;;
		--global)
		    reset_val=$(clear_bit $reset_val ${GLOBAL_BITS[$PORT]})
		    ;;
		*)
		    echo "Unknown option $1"
		    exit 1
		    ;;
	    esac
	    shift
	done
fi

# Ensure bits 6 and 7 are set
reset_val=$(( (reset_val & 0x3F) | 0xC0 ))

reset_val_hex=$(printf "0x%02X" $reset_val)

echo "Writing $reset_val_hex to $BASE_ADDR using devmem2:"
devmem2 $BASE_ADDR w $reset_val_hex
