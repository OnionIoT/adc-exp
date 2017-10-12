#! /bin/sh

## script to interact with the ADC Expansion

# global variables
bUsage=0
bJson=0
bInit=0

# initialize the expansion
initializeExp () {
	i2cset -y 0 0x4a 0x01 0x8300 w
}

# read the adc value
readAdcValue () {
	# TODO: change address based on channel (0-3 vs 4-7) and switch value
	# read adc 16 bit value
	adcVal=$(($(i2cget -y 0 0x4a 0x00 w | sed -e 's/0x\(..\)\(..\)/0x\2\1/')/1))
	
	# check if negative
	signChangeVal=$((0x8000/1))
	if [ $adcVal -gt $signChangeVal ]; then
		maxVal=$((0xffff/1))
		adcVal=$(echo "(-1)*($maxVal-$adcVal)" | bc -l)
	fi
	
	# perform conversion to Volts based on FSR
	conversionVal="0.0001875"
	Vadc=$(echo "($adcVal)*($conversionVal)" | bc -l)
	# round to 2 decimals
	Vadc=$(echo "scale=2; $Vadc / 1" | bc -l)
	
	# prettify negative numbers that are -1 < x < 1
	Vadc=$(echo "$Vadc" | sed -e 's/^-\./-0./' -e 's/^\./0./')
	echo $Vadc
}



### MAIN PROGRAM ###
# parse arguments
while [ "$1" != "" ]
do
    case "$1" in
        -h|--h|help|-help|--help)
            bUsage=1
            shift
        ;;
        -j|--j|json|-json|--json)
            bJson=1
            shift
        ;;
        -i|--i|init|-init|--init)
            bInit=1
            shift
        ;;
        *)
            echo "ERROR: Invalid Argument: $1"
            shift
            exit
        ;;
    esac
done


# initialize the expansion
if [ "$bInit" == 1 ]; then
	initializeExp
fi

val=$(readAdcValue)
echo $val