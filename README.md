# lm75
Bash script to easily get temperature readings from LM75 and LM75A temperature sensor (Raspberry PI)

I helped myself a bunch of those small temperature sensors with the idea to turn my Raspi into a thermosensor. The first lesson is to buy also some wires: if you plug directly the sensor to the Raspi's GPIO will work pretty fine, but the board heat will warm the sensor by direct contact. With the help of five simple wires you can place the sensor away from the Raspi's board.

I was using a script found on the net to manage the lm75a and it was more or less fine, but throw some strange temperature values: 21.345, 20.843, ... I was a bit annoyed for such a thing. Obviously a 0.75$ sensor won't have a 1/1000 degree accuracy. So I dig a bit into the code and found some magical maths:
        adj_neg=0
        adj_tmp=$(($(($tmp_raw >> 8)) | $(($tmp_raw << 8))))
        adj_tmp=$(($adj_tmp & 0xffff))

        # Check if the MSB (of the word) is set to indicate a negitive value
        if [[ $(($adj_tmp & 0x8000)) -eq 0x8000 ]]
        then
           adj_neg=256
        fi

        adj_tmp=$(($adj_tmp >> 5))

        if [ "$fahrenheit" = true ]
        then
           TEMP=`echo "scale=3; (($adj_tmp * 0.125) - $adj_neg) * (9 / 5) + 32" | bc`
        else
           TEMP=`echo "scale=3; ($adj_tmp * 0.125) - $adj_neg" | bc`
        fi
I searched for other scripts but all looks more or less similar. I was really impressed with the "x0.125" stuff and that "$tmp_raw >> 8 | $tmp_raw << 8" got me hipnotized. I really love the magical and arcane code. After recovering from the shock and once found the technical docs for the sensor I built my own script in bash.

Not magic-code, just very simple and easy to understand, sorry for the boring time.

Finally I noticed the sensor (which by the way has only half degree of definition) jumps a bit up and down, so I also implemented a simple "cushion" functionality so the script returns the temperature measured directly from the sensor, the mode of the last 10 readings and the average of the same 10 readings.

To use it you just need to install i2ctools (not so complicated, just google "i2ctools install raspberry") and use the script.

There are just two ways to run it:
* The simple way:
    pi@erebor ~/termometro $ ./lm75.sh
    21.5
* The full way:
    pi@erebor ~/termometro $ ./lm75.sh full
    21.5 21.0 21.150

It just don't matter if you use "full" as first parameter or "flowerpower".

Please note it just uses the "last 10 times" that means there should be a crontab entry to run this script every minute or so in order to have a sense. If you run this script only when you want to know the temperature, the "full" feature is useless and pointless, just go without parms.
