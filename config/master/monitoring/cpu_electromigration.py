
import math
import os
import re
import subprocess
import tempfile
from pathlib import Path


K_B = 8.617333262145e-5  # Boltzmann constant (eV/K)

E_A = 0.5                 # Assumption from Black's electromigration equation
                          # Activation energy describing how sensitive electromigration is to temperature
N = 2.0                   # Assumption from Black's electromigration equation
                          # Current-stress exponent describing how strongly electromigration responds to increased
T_REF_C = 47           
I_REF_A = 0.662308       

OUTPUT = "/var/lib/prometheus/node-exporter/cpu_electromigration.prom"


def main():
    temperature = CPU_Temperature()
    current = CPU_Current()

    aging_factor = Aging_Acceleration_factor(
        temperature, current
    )

    send_to_prometheus(aging_factor)


def CPU_Temperature():
    # Read SoC temperature from Linux thermal subsystem
    temp_path = Path("/sys/class/thermal/thermal_zone0/temp")

    with open(temp_path, "r") as file:
        temperature_raw = int(file.read().strip())

    temperature_c = temperature_raw / 1000

    print(f"CPU temperature: {temperature_c:.2f} C")

    return temperature_c


def CPU_Current():
    # Read PMIC ADC measurements from Raspberry Pi firmware
    result = subprocess.check_output(
        ["vcgencmd", "pmic_read_adc"],
        text=True
    )

    # Extract VDD_CORE_A (amperes)
    match = re.search(
        r"^\s*VDD_CORE_A\s+current\(\d+\)\s*=\s*([\d.]+)A",
        result,
        re.MULTILINE
    )

    if not match:
        raise RuntimeError("VDD_CORE_A measurement not found")

    current_a = float(match.group(1))

    print(f"CPU core supply current: {current_a:.6f} A")

    return current_a


def Aging_Acceleration_factor(temperature_c, current_a):
    # Convert Celsius to Kelvin
    T_cpu = temperature_c + 273.15
    T_ref = T_REF_C + 273.15

    # Approximate electromigration acceleration
    current_factor = (current_a / I_REF_A) ** N

    thermal_factor = math.exp(
        (E_A / K_B) * ((1 / T_ref) - (1 / T_cpu))
    )

    aging_factor = current_factor * thermal_factor

    print(f"Current stress factor: {current_factor:.3f}x")
    print(f"Thermal factor: {thermal_factor:.3f}x")
    print(f"EM proxy acceleration factor: {aging_factor:.3f}x")

    return aging_factor


def send_to_prometheus(aging_factor):
    metrics = f"""# HELP rpi_cpu_em_proxy_factor Experimental current-and-temperature stress acceleration proxy
# TYPE rpi_cpu_em_proxy_factor gauge
rpi_cpu_em_proxy_factor {aging_factor:.6f}
"""

    directory = os.path.dirname(OUTPUT)
    os.makedirs(directory, exist_ok=True)

    fd, temporary = tempfile.mkstemp(dir=directory)

    try:
        with os.fdopen(fd, "w") as file:
            file.write(metrics)

        os.chmod(temporary, 0o644)
        os.replace(temporary, OUTPUT)

        print(f"rpi_cpu_em_proxy_factor {aging_factor:.6f}")

    except Exception:
        if os.path.exists(temporary):
            os.remove(temporary)
        raise


if __name__ == "__main__":
    main()
