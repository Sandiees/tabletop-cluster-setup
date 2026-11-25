
import subprocess
import re
import os
import tempfile


# ============================================================
# RAM ELECTRICAL MONITORING — RASPBERRY PI 5
# ============================================================

OUTPUT = "/var/lib/prometheus/node-exporter/ram_electrical.prom"


def main():
    voltage, current = RAM_Electrical_Measurements()
    power = RAM_Power(voltage, current)
    send_to_prometheus(voltage, current, power)


def RAM_Electrical_Measurements():
    # Read PMIC measurements from the Raspberry Pi 5
    result = subprocess.check_output(
        ["vcgencmd", "pmic_read_adc"],
        text=True
    )

    # Extract DDR_VDD2 voltage in volts
    voltage_match = re.search(
        r"^\s*DDR_VDD2_V\s+volt\(\d+\)\s*=\s*([\d.]+)V",
        result,
        re.MULTILINE
    )

    # Extract DDR_VDD2 current in amperes
    current_match = re.search(
        r"^\s*DDR_VDD2_A\s+current\(\d+\)\s*=\s*([\d.]+)A",
        result,
        re.MULTILINE
    )

    if not voltage_match or not current_match:
        raise RuntimeError("DDR_VDD2 measurements not found")

    voltage = float(voltage_match.group(1))
    current = float(current_match.group(1))

    if voltage <= 0 or current < 0:
        raise ValueError("Invalid DDR supply measurements")

    print(f"DDR_VDD2 voltage: {voltage:.6f} V")
    print(f"DDR_VDD2 current: {current:.6f} A")

    return voltage, current


def RAM_Power(voltage, current):
    # Calculate estimated power of the DDR_VDD2 rail
    power = voltage * current

    print(f"DDR_VDD2 power: {power * 1000:.3f} mW")

    return power


def send_to_prometheus(voltage, current, power):
    # Export metrics in Prometheus textfile format
    metrics = f"""# HELP rpi_ddr_vdd2_voltage_volts Measured DDR VDD2 rail voltage
# TYPE rpi_ddr_vdd2_voltage_volts gauge
rpi_ddr_vdd2_voltage_volts {voltage:.6f}
# HELP rpi_ddr_vdd2_current_amperes Measured DDR VDD2 rail current
# TYPE rpi_ddr_vdd2_current_amperes gauge
rpi_ddr_vdd2_current_amperes {current:.8f}
# HELP rpi_ddr_vdd2_power_watts Estimated DDR VDD2 rail power
# TYPE rpi_ddr_vdd2_power_watts gauge
rpi_ddr_vdd2_power_watts {power:.8f}
"""

    # Write safely using a temporary file
    directory = os.path.dirname(OUTPUT)
    fd, temporary = tempfile.mkstemp(dir=directory)

    try:
        with os.fdopen(fd, "w") as file:
            file.write(metrics)

        # Allow Node Exporter to read the file
        os.chmod(temporary, 0o644)

        # Atomically replace the previous metrics file
        os.replace(temporary, OUTPUT)

    except Exception:
        if os.path.exists(temporary):
            os.remove(temporary)
        raise


if __name__ == "__main__":
    main()
