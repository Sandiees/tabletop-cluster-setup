import subprocess
import os
import tempfile

"""The idea with this code is to check the throttling status of the 
    Raspberry Pi using the vcgencmd command.
    The get_throttling_status function runs the command, retrieves the output, and parses 
    it to determine which throttling flags are set.
    It then prints out the status of each flag, 
    indicating whether it is active (1) or inactive (0).
"""

def main():
    throttling_status = get_throttling_status()
    send_to_prometheus(throttling_status)


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

    # Decode each status bit
    measurements = {}

    for name, bit in flags.items():
        value = int(bool(status & (1 << bit)))
        measurements[name] = value
        print(f"{name}: {value}")

    return measurements


def send_to_prometheus(measurements):
    OUTPUT = "/var/lib/prometheus/node-exporter/throttling.prom"

    metrics = ""

    for name, value in measurements.items():
        metric_name = f"rpi_{name}"

        metrics += (
            f"# TYPE {metric_name} gauge\n"
            f"{metric_name} {value}\n"
        )

    # Write safely using a temporary file
    directory = os.path.dirname(OUTPUT)
    fd, temporary = tempfile.mkstemp(dir=directory)

    try:
        with os.fdopen(fd, "w") as file:
            file.write(metrics)

        # Allow Node Exporter to read the file
        os.chmod(temporary, 0o644)

        # Atomically replace the old metrics file
        os.replace(temporary, OUTPUT)

    except Exception:
        if os.path.exists(temporary):
            os.remove(temporary)
        raise


if __name__ == "__main__":
    main()

