# read a single analog input channel and display on screen
import time
from OmegaExpansion import AdcExp


# Create an ADC Expansion instance
#   using the default I2C device address (0x48)
adc = AdcExp.AdcExp()

# set the gain to be 2/3 to read voltages from -6.144 to +6.144V
GAIN = 2/3

print('Reading ADC Expansion value:')

value = adc.read_adc(0, gain=GAIN)
print('ADC Value = %f'%value)

value = adc.read_voltage(0, gain=GAIN)
print('Voltage = %.02f V'%value)
