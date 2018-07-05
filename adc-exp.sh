#! /bin/sh

## script to interact with the ADC Expansion

# global variables
bUsage=0
bJson=0
bInit=0

switchVal=0
inputChannel=0
deviceAddr=0
deviceChannel=0

deviceAddrSwitch0=0x48
deviceAddrSwitch1=0x49

deviceConfigReg="0x01"
deviceConversionReg="0x00"

deviceSetMaxFsrMask=0xf1ff
deviceEnableContConvMask=0xfeff
deviceInputMuxMask=0x8fff
deviceInputMuxChannel0=0x4000
deviceInputMuxChannel1=0x5000
deviceInputMuxChannel2=0x6000
deviceInputMuxChannel3=0x7000

deviceConversionDelay="0.008"

# usage
Usage () {
				echo ""
				echo "Usage: adc-exp [options] <channel>"
				echo ""
				echo "FUNCTIONALITY:"
				echo "Onion ADC Expansion: Read voltage value of an analog input channel"
				echo "valid channel: 0-3, or 'all'"
				echo ""
				echo "OPTIONS:"
				echo " -s <0|1>			specify address switch value"
				echo " -j               json output"
				echo " -h               help: show this prompt"
				echo ""
}

# program ADS chip to read a specific channel
# will also FSR to max & enable continuous conversion mode
#	argument1 - ADS channel (0-3)
setChannel () {
	# read current configuration register value
	config=$(i2cget -y 0 $deviceAddr $deviceConfigReg w | sed -e 's/0x\(..\)\(..\)/0x\2\1/')

	# set the FSR to max
	config=$(printf "0x%04x\n" $(($config & $deviceSetMaxFsrMask)))
	# enable continuous conversion mode
	config=$(printf "0x%04x\n" $(($config & $deviceEnableContConvMask)))

	# set the input value
	# 	first, mask out the input multiplexor config
	config=$(printf "0x%04x\n" $(($config & $deviceInputMuxMask)))
	case "$1" in
		0)
			muxMask=deviceInputMuxChannel0
		;;
		1)
			muxMask=deviceInputMuxChannel1
		;;
		2)
			muxMask=deviceInputMuxChannel2
		;;
		3)
			muxMask=deviceInputMuxChannel3
		;;
	esac
	# apply the input value to the register value
	config=$(printf "0x%04x\n" $(($config | $muxMask)))

	# flip the bytes and write to the config register
	config=$(echo "$config" | sed -e 's/0x\(..\)\(..\)/0x\2\1/' )
	i2cset -y 0 $deviceAddr $deviceConfigReg $config w
	#echo "wrote: i2cset -y 0 $deviceAddr $deviceConfigReg $config w"

	# wait for the conversion delay before reading the conversion register
	/usr/bin/sleep $deviceConversionDelay
}

# read the adc value
#	argument1 - ADS device channel (0-3)
readAdcValue () {
	# set the input channel mux
	setChannel $1

	# read adc 16 bit value
	adcVal=$(($(i2cget -y 0 $deviceAddr $deviceConversionReg w | sed -e 's/0x\(..\)\(..\)/0x\2\1/')/1))

	# check if negative
	signChangeVal=$((0x8000/1))
	if [ $adcVal -gt $signChangeVal ]; then
		maxVal=$((0xffff/1))
		adcVal=$(echo "(-1)*($maxVal-$adcVal)" | bc -l)
	fi

	# perform conversion to Volts based on FSR
	conversionVal="0.0001875"
	local Vadc=$(echo "($adcVal)*($conversionVal)" | bc -l)
	# round to 2 decimals
	Vadc=$(echo "scale=2; $Vadc / 1" | bc -l)

	# prettify negative numbers that are -1 < x < 1
	Vadc=$(echo "$Vadc" | sed -e 's/^-\./-0./' -e 's/^\./0./')
	echo $Vadc
}



### MAIN PROGRAM ###
# parse options
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
				-s|--s|switch|-switch|--switch)
						shift
						switchVal=$1
						shift
				;;
				*)
					# this last argument should be the input channel, AINx
					break
				;;
		esac
done

# parse input channel
if [ "$1" != "" ]; then
	inputChannel="$1"
	shift
else
	echo "ERROR: Expecting channel input"
	bUsage=1
fi

# check for valid switch input
case "$switchVal" in
	0|0x48|48|0X48)
		deviceAddr=$deviceAddrSwitch0
	;;
	1|0x49|49|0X49)
		deviceAddr=$deviceAddrSwitch1
	;;
	default)
		echo "ERROR: Invalid switch value"
		bUsage=1
	;;
esac

# check for valid channel
case "$inputChannel" in
	0|1|2|3|all)
		# do nothing all good
	;;
	default)
		echo "ERROR: Invalid input channel value"
		bUsage=1
	;;
esac

# print usage if required
if [ $bUsage == 1 ]; then
	Usage
	exit
fi


# read all channels
if [ "$inputChannel" == "all" ]; then
	# read all 4 channels
	A0=$(readAdcValue 0)
	A1=$(readAdcValue 1)
	A2=$(readAdcValue 2)
	A3=$(readAdcValue 3)

	if [ $bJson == 1 ]; then
		echo "{\"A0\":$A0,\"A1\":$A1,\"A2\":$A2,\"A3\":$A3,\"switch\":$switchVal}"
	else
		echo "A0 Voltage: $A0 V"
		echo "A1 Voltage: $A1 V"
		echo "A2 Voltage: $A2 V"
		echo "A3 Voltage: $A3 V"
	fi
else
	# configure the adc, then read the input value
	val=$(readAdcValue $inputChannel)

	if [ $bJson == 1 ]; then
		echo "{\"channel\":$inputChannel,\"voltage\":$val, \"switch\":$switchVal}"
	else
		echo "A$inputChannel Voltage: $val V"
	fi
fi
