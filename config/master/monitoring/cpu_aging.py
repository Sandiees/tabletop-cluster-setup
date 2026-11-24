from pathlib import Path
import math
import os
import tempfile


def main():
    temperature = CPU_Temperature()
    aging_factor = Aging_Acceleration_factor(temperature)
    send_to_prometheus(aging_factor)


def CPU_Temperature():
    # Path to the CPU temperature sensor on the Raspberry Pi 5
    temp_path = Path("/sys/class/thermal/thermal_zone0/temp")

    # Read the temperature from the Linux thermal subsystem
    with open(temp_path, "r") as file:
        temperature_raw = int(file.read().strip())

    # Convert millidegrees Celsius to degrees Celsius
    temperature_c = temperature_raw / 1000

    print(f"CPU temperature: {temperature_c:.2f} C")

    return temperature_c


def Aging_Acceleration_factor(temperature_c):
    # Constants for the Arrhenius aging model
    K_B = 8.617333262145e-5  # Boltzmann constant (eV/K)
    E_A = 0.5                 # Assumed activation energy (eV)
    T_REF_C = 40.0            # Reference temperature (Celsius)

    # Convert temperatures from Celsius to Kelvin
    T_cpu = temperature_c + 273.15
    T_ref = T_REF_C + 273.15

    # Calculate thermal aging acceleration relative to the reference
    aging_factor = math.exp(
        (E_A / K_B) * ((1 / T_ref) - (1 / T_cpu)))

    print(f"CPU Aging Acceleration Factor: {aging_factor:.3f}x")

    return aging_factor


def send_to_prometheus(aging_factor):
    OUTPUT = "/var/lib/prometheus/node-exporter/cpu_aging.prom"

    # Create Prometheus-compatible metric
    metrics = f"""# HELP rpi_cpu_aging_factor Estimated CPU thermal aging acceleration relative to 40 Celsius
# TYPE rpi_cpu_aging_factor gauge
rpi_cpu_aging_factor {aging_factor:.6f}
"""

    # Write safely using a temporary file
    directory = os.path.dirname(OUTPUT)
    fd, temporary = tempfile.mkstemp(dir=directory)

    try:
        with os.fdopen(fd, "w") as file:
            file.write(metrics)

        # Allow Node Exporter to read the metrics file
        os.chmod(temporary, 0o644)

        # Atomically replace the previous metrics file
        os.replace(temporary, OUTPUT)

        print(f"rpi_cpu_aging_factor {aging_factor:.6f}")

    except Exception:
        if os.path.exists(temporary):
            os.remove(temporary)
        raise


if __name__ == "__main__":
    main()