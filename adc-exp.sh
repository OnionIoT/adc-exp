#! /bin/sh

## script to interact with the ADC Expansion

# global variables
bUsage=1
bJson=0
bInit=0

switchVal=0
inputChannel=0
deviceAddr=0
deviceChannel=0

deviceAddrSwitch0=0x4a
deviceAddrSwitch1=0x48

# usage
Usage () {
        echo ""
        echo "Usage: adc-exp [options] <channel>"
        echo ""
        echo "FUNCTIONALITY:"
        echo "Onion ADC Expansion: Read voltage value of an analog input channel"
        echo "valid channel: 0-7"
        echo ""
        echo "OPTIONS:"
        echo " -s <0|1>			specify address switch value"
        echo " -j               json output"
        echo " -h               help: show this prompt"
        echo ""
}

# initialize the expansion
initializeExp () {
	i2cset -y 0 $deviceAddr 0x01 0x8300 w
}

# set the device address and channel based on input 
#	argument1 - address switch value
#	argument2 - AINx channel
decodeChannel () {
	# adjust the (base) device address based on the switch value
	if [ $1 == 0 ]; then
		deviceAddr=$deviceAddrSwitch0
	else
		deviceAddr=$deviceAddrSwitch1
	fi
	
	# normalize the input channel to 0-3
	if [ $2 -gt 3 ]; then
		deviceChannel=$(($inputChannel - 4))
		# requires using the other ADS chip
		deviceAddr=$(printf "0x%02x\n" $(($deviceAddr + 1)) )
	else
		deviceChannel=$inputChannel
	fi
}

# read the adc value
#	argument1 - AINx channel
readAdcValue () {
	# TODO: change input channel reading based on inputChannel
	
	
	# read adc 16 bit value
	adcVal=$(($(i2cget -y 0 $deviceAddr 0x00 w | sed -e 's/0x\(..\)\(..\)/0x\2\1/')/1))
	
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
        -s|--s|switch|-switch|--switch)
            shift
            switchVal=$1
            shift
        ;;
        #*)
        #    echo "ERROR: Invalid Argument: $1"
        #	echo ""
        #	bUsage=1		
        #    shift
        #;;
    esac
    
    if [ "$1" != "" ]; then
    	inputChannel="$1"
    	bUsage=0
    	shift
    else
    	echo "ERROR: Expecting channel input"
    fi
    	
done

# initialize the expansion
if [ $bUsage == 1 ]; then
	Usage
	exit
fi

# TODO: add checking for valid switch and channel inputs


# decode the device and channel 
decodeChannel $switchVal $inputChannel
echo "decodeChannel done: deviceAddr = $deviceAddr, deviceChannel = $deviceChannel"
exit

# initialize the expansion
if [ $bInit == 1 ]; then
	initializeExp
fi

val=$(readAdcValue)
echo $val


