# Read all 4 analog input channels and display on screen in a loop
import time
from OmegaExpansion import AdcExp


# Create an ADC Expansion instance
#   and specify the address indicated by the address switch
adc = AdcExp.AdcExp(address=0x48)

print('Reading ADC Expansion voltages, press Ctrl-C to quit...')
# Print nice channel column headers.
print('| {0:>6} | {1:>6} | {2:>6} | {3:>6} |'.format(*range(4)))
print('-' * 37)
# Main loop.
while True:
    # Read all the ADC channel values in a list.
    values = [0]*4
    for i in range(4):
        # Read the specified ADC channel (using the default gain value)
        values[i] = adc.read_voltage(i)

    # Print the ADC values.
    print('| {0:>6} | {1:>6} | {2:>6} | {3:>6} |'.format(*values))
    # Pause for half a second.
    time.sleep(0.5)
