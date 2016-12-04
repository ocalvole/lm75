#!/bin/bash

# HIGH     LOWBYTE
#FEDCBA98 76543210
#--------·--------
#00000000 01111111 >> Temperature value
#00000000 10000000 >> Temperature value sign 0=+ 1=-
#10000000 00000000 >> Temperatire value half degree to add 0=no 1=+0.5
#----------------------
#11111111 00010101

#Mask definition values according to upper diagram
MASK_VALU=$((2#0000000001111111))
MASK_SIGN=$((2#0000000010000000))
MASK_HALF=$((2#1000000000000000))

#Get the 0x00 register from the lm75
TERMO_RAW=$( sudo i2cget -y 1 0x48 0x00 w )

#Get the temperature value
TERMO_VALU=$(( $TERMO_RAW & $MASK_VALU ))

#check temperature sign, bit 7
TERMO_SIGN=1
if [ $(( $TERMO_RAW & $MASK_SIGN )) -gt 0 ]; then
        TERMO_SIGN=-1
fi

#Check bit 15 to see if theres half a degree
TERMO_HALFDEGREE=0
if [ $(( $TERMO_RAW & $MASK_HALF )) -gt 0 ]; then
        TERMO_HALFDEGREE=0.5
fi

#Add halfdegree to raw low byte where the base temp is all x10 to bypass floating point bashing
TF=$( echo "scale=1; (${TERMO_SIGN}*${TERMO_VALU}+${TERMO_HALFDEGREE})/1 " | bc )

#if no parameters, just print temperature and goodbye
if [ "$1" == "" ]; then
        echo $TF
        exit 0
fi

#In other case, value amortiguation enabled
#memorize
MEMFILE=/tmp/termomem.txt
SIZE=10
echo $TF >> $MEMFILE
tail -$SIZE $MEMFILE > $MEMFILE.temp
rm -f $MEMFILE
mv $MEMFILE.temp $MEMFILE

#mode calculation is very simple using sort and uniq
MODE=$( cat $MEMFILE | sort | uniq  -c | sort -gr | head -1 | tr -s ' ' ';' | cut -f 3 -d';')

#average is a bit longer
TOTAL=0
while read LINE
do
        #remove floating point
        #then we must divide by 10 since all values
        #are from 22.5 to 225 or 25.0 to 250
        VALUE=$( echo $LINE | tr -d '.' )
        TOTAL=$(( $TOTAL + $VALUE ))
done < $MEMFILE

#then just divide by 10 and number of lines (SIZE)
AVERAGE=$(echo "scale=3; $TOTAL / ($SIZE * 10)" | bc)

echo $TF $MODE $AVERAGE

exit 0