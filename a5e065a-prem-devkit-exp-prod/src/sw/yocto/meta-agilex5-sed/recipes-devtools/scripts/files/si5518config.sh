#!/bin/sh

if [ -z $1 ]; then
     echo -e "Usage:"
	 echo -e "./si5518config.sh <master/slave>"
     exit
fi

if [ $1 == "master" ]; then
      echo "Set master"
      echo "0x2 0x0" > /sys/bus/i2c/devices/0-0059/holdover
      echo "0x2 0x5" > /sys/bus/i2c/devices/0-0059/input_sel
      echo "0x5" > /sys/bus/i2c/devices/0-0059/input_status
      TenMHz_status=$?
      echo "0x6" > /sys/bus/i2c/devices/0-0059/input_status
      Onepps_status=$?

      if [ $TenMHz_status == 1 ]; then
         echo "10MHz input is invalid"
         echo "0x2 0x0" > /sys/bus/i2c/devices/0-0059/pll_wait
         holdover_status=$?
         if [ $holdover_status == 1 ]; then
             echo "10MHz is not connected and DSPLLA is not holdover... MASTER set FAILED!!"
		 else
			 echo "10MHz is not connected and DSPLLA in holdover... Master set successful!!"
         fi
      fi

      if [ $TenMHz_status == 0 ]; then
         echo "10MHz input valid"
         echo "0x2 0x1" > /sys/bus/i2c/devices/0-0059/pll_wait
         lock_status=$?
         if [ $lock_status == 1]; then
             echo "10MHz is connected and DSPLLA is not locked... MASTER set FAILED!!"
		 else
			 echo "10MHz is connected and DSPLLA is locked... Master set successful!!"
         fi
      fi

elif [ $1 == "slave" ]; then
      echo "0x2 0x0" > /sys/bus/i2c/devices/0-0059/holdover
      echo "0x2 0x0" > /sys/bus/i2c/devices/0-0059/input_sel
      echo "0x0" > /sys/bus/i2c/devices/0-0059/input_status

      if [ $? == 1 ]; then
         echo "CDR clock input is invalid. Check LINK status"
         echo "0x2 0x0" > /sys/bus/i2c/devices/0-0059/pll_wait
         holdover_status=$?
         if [ $holdover_status == 1 ]; then
			echo "DSPLLA is not holdover without CDR valid... CHECK THE CLOCK INPUT!!"
		 else
			echo "CDR clock not available and PLL is in holdover... Slave set successful!!"
         fi
      fi

      if [ $? == 0 ]; then
         echo "CDR clock input is valid"
         echo "0x2 0x1" > /sys/bus/i2c/devices/0-0059/pll_wait
         lock_status=$?
	 count=5;
	 while [ $lock_status == 1 ]; do
		count=$((count-1))
		if [ $count -eq 0 ]; then
			break
		fi
		sleep 1
		echo "0x2 0x1" > /sys/bus/i2c/devices/0-0059/pll_wait
		lock_status=$?
	done

	if [ $count -eq 0 ]; then
             echo "DSPLLA is not locked to CDR... SLAVE set FAILED!!"
	else
	     echo "Input set to CDR and PLL is locked... Slave set successful!!"
	fi
    fi
else
      echo -e "Invalid"
fi
