#!/usr/bin/env python3

import csv
import os
import re
import stat
import subprocess
import sys
from pathlib import Path

CSV_FILE = Path(
    sys.argv[1] if len(sys.argv) > 1
    else "/root/cluster-admin/user-management/students.csv"
)

USERNAME_PATTERN = re.compile(r"^[a-z_][a-z0-9_-]*[$]?$")
GROUP_PATTERN = re.compile(r"^[a-z_][a-z0-9_-]*$")


def run(command, **kwargs):
    subprocess.run(command, check=True, **kwargs)


def get_entry(database, name):
    result = subprocess.run(
        ["getent", database, name],
        text=True,
        capture_output=True
    )
    return result.stdout.strip() if result.returncode == 0 else None


def ensure_group(group_name, gid):
    existing = get_entry("group", group_name)

    if existing:
        fields = existing.split(":")
        if int(fields[2]) != gid:
            raise RuntimeError(
                f"Group {group_name} exists with GID {fields[2]}, "
                f"but the CSV specifies {gid}."
            )
        return

    gid_owner = get_entry("group", str(gid))
    if gid_owner:
        raise RuntimeError(
            f"GID {gid} is already used by {gid_owner.split(':')[0]}."
        )

    print(f"Creating group {group_name} (GID {gid})")
    run(["groupadd", "--gid", str(gid), group_name])


def create_user(row):
    username = row["username"]
    fullname = row["fullname"]
    uid = int(row["uid"])
    group_name = row["group"]
    gid = int(row["gid"])
    password = row["password"]

    if not USERNAME_PATTERN.fullmatch(username):
        raise ValueError(f"Invalid username: {username}")

    if not GROUP_PATTERN.fullmatch(group_name):
        raise ValueError(f"Invalid group name: {group_name}")

    if uid < 1000 or gid < 1000:
        raise ValueError(f"UID and GID must be at least 1000: {username}")

    if not fullname or not password:
        raise ValueError(f"Missing fullname or password for {username}")

    if any(char in password for char in ("\n", "\r", ":")):
        raise ValueError(f"Password for {username} contains an unsupported character.")

    ensure_group(group_name, gid)

    existing = get_entry("passwd", username)

    if existing:
        fields = existing.split(":")
        existing_uid = int(fields[2])
        existing_gid = int(fields[3])

        if existing_uid != uid or existing_gid != gid:
            raise RuntimeError(f"Existing account {username} has UID/GID {existing_uid}/{existing_gid}, expected {uid}/{gid}.")

        print(f"User {username} already exists; skipping.")
        return

    uid_owner = get_entry("passwd", str(uid))
    if uid_owner:
        raise RuntimeError(f"UID {uid} is already used by {uid_owner.split(':')[0]}.")

    print(f"Creating user {username} (UID {uid})")

    run([
        "useradd",
        "--create-home",
        "--uid", str(uid),
        "--gid", group_name,
        "--shell", "/bin/bash",
        "--comment", fullname,
        username
    ])

    home = Path("/home") / username
    os.chmod(home, 0o700)

    # Supply the password through stdin, not as a command-line argument.
    run(["chpasswd"], input=f"{username}:{password}\n", text=True)

    # Require the user to choose a new password at first login.
    run(["chage", "--lastday", "0", username])

    print(f"Created {username}")


def main():
    if os.geteuid() != 0:
        sys.exit("Run this script as root.")

    if not CSV_FILE.is_file():
        sys.exit(f"CSV file not found: {CSV_FILE}")

    file_stat = CSV_FILE.stat()

    if stat.S_IMODE(file_stat.st_mode) & 0o077:
        sys.exit(f"Unsafe permissions on {CSV_FILE}. Set them to 600 with chmod 600.")

    if file_stat.st_uid != 0:
        sys.exit(f"{CSV_FILE} must be owned by root.")

    required_columns = {"username", "fullname", "uid", "group", "gid", "password"}

    with CSV_FILE.open(newline="", encoding="utf-8") as csv_file:
        reader = csv.DictReader(csv_file)

        if not required_columns.issubset(reader.fieldnames or []):
            sys.exit("CSV must contain these columns: " + ", ".join(sorted(required_columns)))

        rows = list(reader)

    if not rows:
        sys.exit("The CSV contains no users.")

    usernames = [row["username"] for row in rows]
    if len(usernames) != len(set(usernames)):
        sys.exit("The CSV contains duplicate usernames.")

    print(f"Preparing to create {len(rows)} account(s).")

    for row in rows:
        if None in row or any(value is None for value in row.values()):
            raise ValueError("The CSV contains a row with missing fields.")

        create_user({
            key: value.strip() if key != "password" else value
            for key, value in row.items()
        })

    print("User account setup complete.")


if __name__ == "__main__":
    main()
