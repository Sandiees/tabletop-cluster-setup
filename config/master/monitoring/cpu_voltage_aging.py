
from pathlib import Path
import subprocess
import math
import os
import re
import tempfile


K_B = 8.617333262145e-5  # Boltzmann constant (eV/K)
E_A = 0.5                
M = 2.0               
T_REF_C = 47            
V_REF_V = 0.778470      

OUTPUT = "/var/lib/prometheus/node-exporter/cpu_voltage_aging.prom"


def main():
    temperature = CPU_Temperature()
    voltage = CPU_Voltage()

    aging_factor = Aging_Acceleration_factor(
        temperature, voltage
    )

    send_to_prometheus(aging_factor)


def CPU_Temperature():
    # Read the CPU temperature from the Linux thermal sensor
    temp_path = Path("/sys/class/thermal/thermal_zone0/temp")

    with open(temp_path, "r") as file:
        temperature_raw = int(file.read().strip())

    # Convert millidegrees Celsius to Celsius
    temperature_c = temperature_raw / 1000

    print(f"CPU temperature: {temperature_c:.2f} C")

    return temperature_c


def CPU_Voltage():
    # Read voltage measurements from the Raspberry Pi 5 PMIC
    result = subprocess.check_output(
        ["vcgencmd", "pmic_read_adc"],
        text=True
    )

    # Extract the CPU core supply voltage
    match = re.search(
        r"^\s*VDD_CORE_V\s+volt\(\d+\)\s*=\s*([\d.]+)V",
        result,
        re.MULTILINE
    )

    if not match:
        raise RuntimeError("VDD_CORE_V measurement not found")

    voltage_v = float(match.group(1))

    if voltage_v <= 0:
        raise ValueError("CPU core voltage must be positive")

    print(f"CPU core supply voltage: {voltage_v:.6f} V")

    return voltage_v


def Aging_Acceleration_factor(temperature_c, voltage_v):
    # Convert Celsius to Kelvin
    T_cpu = temperature_c + 273.15
    T_ref = T_REF_C + 273.15

    # Calculate relative voltage stress
    voltage_factor = (voltage_v / V_REF_V) ** M

    # Calculate temperature-dependent acceleration
    thermal_factor = math.exp(
        (E_A / K_B) * ((1 / T_ref) - (1 / T_cpu))
    )

    # Experimental BTI acceleration proxy
    aging_factor = voltage_factor * thermal_factor

    print(f"Voltage stress factor: {voltage_factor:.3f}x")
    print(f"Thermal factor: {thermal_factor:.3f}x")
    print(f"BTI proxy acceleration factor: {aging_factor:.3f}x")

    return aging_factor


def send_to_prometheus(aging_factor):
    # Path monitored by Node Exporter
    metrics = f"""# HELP rpi_cpu_bti_proxy_factor Experimental voltage-and-temperature stress acceleration proxy
# TYPE rpi_cpu_bti_proxy_factor gauge
rpi_cpu_bti_proxy_factor {aging_factor:.6f}
"""

    directory = os.path.dirname(OUTPUT)

    # Write safely using a temporary file
    fd, temporary = tempfile.mkstemp(dir=directory)

    try:
        with os.fdopen(fd, "w") as file:
            file.write(metrics)

        # Allow Node Exporter to read the measurements
        os.chmod(temporary, 0o644)

        # Atomically replace the previous metrics file
        os.replace(temporary, OUTPUT)

        print(f"rpi_cpu_bti_proxy_factor {aging_factor:.6f}")

    except Exception:
        if os.path.exists(temporary):
            os.remove(temporary)
        raise


if __name__ == "__main__":
    main()
