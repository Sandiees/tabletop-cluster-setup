import subprocess

"""The idea with this code is to check the throttling status of the 
    Raspberry Pi using the vcgencmd command.
    The get_throttling_status function runs the command, retrieves the output, and parses 
    it to determine which throttling flags are set.
    It then prints out the status of each flag, 
    indicating whether it is active (1) or inactive (0).
"""

def get_throttling_status():
    # executing a Raspberry Pi vcgencmd command to get 
    # the throttling status of the device
    result = subprocess.check_output(
        ["vcgencmd", "get_throttled"],
        text=True
    ).strip()

    #converting the hexadecimal value to an integer 
    status = int(result.split("=")[1], 16)

    # the different flags that can be set in the throttling status
    flags = {
        "undervoltage": 0,
        "frequency_capped": 1,
        "throttled": 2,
        "soft_temp_limit": 3,
        "undervoltage_occurred": 16,
        "frequency_capped_occurred": 17,
        "throttled_occurred": 18,
        "soft_temp_limit_occurred": 19,
    }

    # goes through each flag and checkes if the status flag i active, 
    # prints whether a flad is active (1) or inactive (0)
    for name, bit in flags.items():
        value = int(bool(status & (1 << bit)))
        print(f"{name}: {value}")


get_throttling_status()