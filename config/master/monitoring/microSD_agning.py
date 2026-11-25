
from pathlib import Path
import time
import os
import tempfile


DEVICE = "mmcblk0"

SAMPLE_INTERVAL = 10  # Seconds


REFERENCE_WRITE_RATE = 16159.81

OUTPUT = "/var/lib/prometheus/node-exporter/microsd_aging.prom"


def main():
    write_rate = microSD_Write_Rate()
    aging_factor = Aging_Acceleration_factor(write_rate)
    send_to_prometheus(aging_factor, write_rate)


def microSD_Written_Bytes():
    # Read cumulative disk statistics from Linux
    stat_path = Path(f"/sys/block/{DEVICE}/stat")

    with open(stat_path, "r") as file:
        values = file.read().split()

    # Field 7 contains sectors written (zero-based index 6)
    sectors_written = int(values[6])

    # Linux block statistics use 512-byte sectors
    return sectors_written * 512


def microSD_Write_Rate():
    # First measurement
    bytes_before = microSD_Written_Bytes()
    time_before = time.monotonic()

    time.sleep(SAMPLE_INTERVAL)

    # Second measurement
    bytes_after = microSD_Written_Bytes()
    time_after = time.monotonic()

    elapsed = time_after - time_before
    bytes_written = bytes_after - bytes_before

    if elapsed <= 0 or bytes_written < 0:
        raise RuntimeError("Invalid microSD write-rate measurement")

    write_rate = bytes_written / elapsed

    print(f"microSD write rate: {write_rate:.2f} bytes/s")

    return write_rate


def Aging_Acceleration_factor(write_rate):
    # Relative host-write acceleration
    if REFERENCE_WRITE_RATE <= 0:
        raise ValueError("Reference write rate must be positive")

    aging_factor = write_rate / REFERENCE_WRITE_RATE

    print(f"microSD write-wear acceleration: {aging_factor:.3f}x")

    return aging_factor


def send_to_prometheus(aging_factor, write_rate):
    metrics = f"""# HELP rpi_microsd_aging_factor Relative microSD host-write rate compared with reference
# TYPE rpi_microsd_aging_factor gauge
rpi_microsd_aging_factor {aging_factor:.6f}
# HELP rpi_microsd_write_rate_bytes_per_second Measured microSD host-write throughput
# TYPE rpi_microsd_write_rate_bytes_per_second gauge
rpi_microsd_write_rate_bytes_per_second {write_rate:.6f}
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
