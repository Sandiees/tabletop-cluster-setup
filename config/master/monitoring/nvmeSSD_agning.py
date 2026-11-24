
from pathlib import Path
import time
import os
import tempfile


# ============================================================
# MODEL PARAMETERS — MUST BE CALIBRATED
# ============================================================

DEVICE = "nvme0n1"

SAMPLE_INTERVAL = 10  # Seconds

# TODO: Replace with measured NVMe reference write rate.
# 1 MB/s is only a provisional example, not a measured baseline.
REFERENCE_WRITE_RATE = 1_000_000  # Bytes/second

OUTPUT = "/var/lib/prometheus/node-exporter/nvme_aging.prom"


def main():
    write_rate = SSD_Write_Rate()
    aging_factor = Aging_Acceleration_factor(write_rate)
    send_to_prometheus(aging_factor, write_rate)


def SSD_Written_Bytes():
    # Read cumulative disk statistics from Linux
    stat_path = Path(f"/sys/block/{DEVICE}/stat")

    with open(stat_path, "r") as file:
        values = file.read().split()

    # Field 7 contains sectors written (zero-based index 6)
    sectors_written = int(values[6])

    # Linux block statistics use 512-byte sectors
    return sectors_written * 512


def SSD_Write_Rate():
    # First measurement
    bytes_before = SSD_Written_Bytes()
    time_before = time.monotonic()

    time.sleep(SAMPLE_INTERVAL)

    # Second measurement
    bytes_after = SSD_Written_Bytes()
    time_after = time.monotonic()

    elapsed = time_after - time_before
    bytes_written = bytes_after - bytes_before

    if elapsed <= 0 or bytes_written < 0:
        raise RuntimeError("Invalid SSD write-rate measurement")

    write_rate = bytes_written / elapsed

    print(f"NVMe write rate: {write_rate:.2f} bytes/s")

    return write_rate


def Aging_Acceleration_factor(write_rate):
    # Relative host-write acceleration
    if REFERENCE_WRITE_RATE <= 0:
        raise ValueError("Reference write rate must be positive")

    aging_factor = write_rate / REFERENCE_WRITE_RATE

    print(f"NVMe write-wear acceleration: {aging_factor:.3f}x")

    return aging_factor


def send_to_prometheus(aging_factor, write_rate):
    metrics = f"""# HELP rpi_nvme_write_aging_factor Relative NVMe host-write rate compared with reference
# TYPE rpi_nvme_write_aging_factor gauge
rpi_nvme_write_aging_factor {aging_factor:.6f}
# HELP rpi_nvme_write_rate_bytes_per_second Measured NVMe host-write throughput
# TYPE rpi_nvme_write_rate_bytes_per_second gauge
rpi_nvme_write_rate_bytes_per_second {write_rate:.6f}
"""

    # Write safely using a temporary file
    directory = os.path.dirname(OUTPUT)
    fd, temporary = tempfile.mkstemp(dir=directory)

    try:
        with os.fdopen(fd, "w") as file:
            file.write(metrics)

        # Allow Node Exporter to read the file
        os.chmod(temporary, 0o644)

        # Atomically replace the previous metrics
        os.replace(temporary, OUTPUT)

    except Exception:
        if os.path.exists(temporary):
            os.remove(temporary)
        raise


if __name__ == "__main__":
    main()
