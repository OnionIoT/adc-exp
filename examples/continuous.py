# enable continuous conversion mode and read channel 0 on the ADC Expansion
import time
from OmegaExpansion import AdcExp

# Create an ADC Expansion instance
#   and specify the address indicated by the address switch
adc = AdcExp.AdcExp(address=0x48)

# set the gain to be 2/3 to read voltages from -6.144 to +6.144V
GAIN = 2/3

# Start continuous ADC conversions on channel 0 using the previously set gain
adc.start_adc(0, gain=GAIN)
# Once continuous ADC conversions are started you can call get_last_result() to
# retrieve the latest result, or stop_adc() to stop conversions.

# Note you can also call start_adc_difference() to take continuous differential
# readings.  See the read_adc_difference() function in differential.py for more
# information and parameter description.

# Read channel 0 for 5 seconds and print out its values.
print('Reading ADC Expansion channel 0 for 5 seconds...')
start = time.time()
while (time.time() - start) <= 5.0:
    # Read the last ADC conversion value and print it out.
    value = adc.get_last_voltage()
    # WARNING! If you try to read any other ADC channel during this continuous
    # conversion (like by calling read_adc again) it will disable the
    # continuous conversion!
    print('Channel 0: %.02f V'%(value))
    # Sleep for half a second.
    time.sleep(0.5)

# Stop continuous conversion.  After this point you can't get data from get_last_result!
adc.stop_adc()
