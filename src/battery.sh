#!/bin/bash
# CACHEFILE is the place where the script keeps old readings. It is used as a logfile, too.
# you can move CACHEFILE to /tmp if you don't want to keep a log of your battery
CACHEFILE=~/battery.log
# CACHEAGE is the maximum age a battery reading can have, before it is updated.
CACHEAGE=60
# RAWMAX the maximum expected value for the raw battery value, this will be considered 100%
RAWMAX=2450
# RAWMIN the minimum expected value for the raw battery value, this will be considered 0%
RAWMIN=1930

#  
RAWSPAN=$((RAWMAX-RAWMIN))

# if the age of the cache + the allowed age is still greater than now, the cache is still valid
# (fails if file does not exists so it's created.)
if [ $(( $( stat --format=%Y $CACHEFILE ) + $CACHEAGE )) -gt $( date +%s ) ] ;
then
#    tail -1 $CACHEFILE | awk '$1'
    OUT=($(tail -1 $CACHEFILE))
    echo ${OUT[2]}
    exit 0
fi
# If the script is still running, the cache must have been invalid
# so append a new line with current data to the cache
(
        TIME=$(date +'%H:%M %d.%m')
        # Get values from system 
	PERCENT=$(sudo cat /sys/firmware/beepy/battery_percent )
	VOLTAGE=$(sudo cat /sys/firmware/beepy/battery_volts )
        RAWARRAY=()
        # Read multiple values from raw so we can discard the first and average the rest 
        # Iterate over the array and calc the average in RAW
        RAWFIRST=$(sudo cat /sys/firmware/beepy/battery_raw )
        for i in {1..5}; 
        do 
          RAW=$(sudo cat /sys/firmware/beepy/battery_raw ) 
          RAWARRAY+=($RAW)
        done
        for RAW in ${RAWARRAY[@]}; do
          RAWSUM=$((RAWSUM+RAW))
        done
        RAWLEN=${#RAWARRAY[@]}
        RAW=$((RAWSUM/RAWLEN))

        # Calculate our own percentage
        RAWCALC=$((RAW-RAWMIN))
        PERCENTCALC=$((RAWCALC*100/RAWSPAN))
        # correct for 0 <= PERCENTCALC <=100
        if (( PERCENTCALC > 100 )); then
          PERCENTCALC=100
        fi
        if (( PERCENTCALC < 0 )); then
          PERCENTCALC=0
        fi
        
	echo $TIME' '$PERCENTCALC'% '$PERCENT'% '$VOLTAGE'v '$RAWCALC' '$RAW' '$RAWFIRST' '${RAWARRAY[*]}
) >> $CACHEFILE

# tail -1 $CACHEFILE | awk '$1'

OUT=($(tail -1 $CACHEFILE))
echo ${OUT[2]}
