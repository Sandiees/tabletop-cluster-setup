# Student user management

This directory contains the tools for creating student accounts on the
Raspberry Pi cluster.

## 1. Prepare the private account directory

On each Pi, run:

```bash
sudo mkdir -p /root/cluster-admin/user-management
sudo chown root:root /root/cluster-admin
sudo chmod 700 /root/cluster-admin

sudo chown root:root /root/cluster-admin/user-management
sudo chmod 700 /root/cluster-admin/user-management
```

## 2. Copy the account files

From the repository root, run:

```bash
sudo install -o root -g root -m 700 \
    user-management/create_users.py \
    /root/cluster-admin/user-management/create_users.py

sudo install -o root -g root -m 600 \
    user-management/students.example.csv \
    /root/cluster-admin/user-management/students.csv
```

The second command creates a private copy of the example CSV.

## 3. Edit the student information

Edit the private CSV:

```bash
sudo nano /root/cluster-admin/user-management/students.csv
```

The CSV must have this format:

```csv
username,fullname,uid,group,gid,password
student-1,Student One,2001,course,2000,TEMPORARY-PASSWORD
student-2,Student Two,2002,course,2000,TEMPORARY-PASSWORD
```

Replace the example information with the actual student information.

Important:

- Every username must be unique.
- Every user must have a unique UID.
- Use the same UID for a particular student on every Pi.
- Use the same GID for a particular group on every Pi.
- Use unique temporary passwords.
- Do not put real student information or passwords in GitHub.

Save the file and check its permissions:

```bash
sudo chown root:root /root/cluster-admin/user-management/students.csv
sudo chmod 600 /root/cluster-admin/user-management/students.csv
```

## 4. Create the accounts

Run:

```bash
sudo python3 /root/cluster-admin/user-management/create_users.py
```

The script creates the specified group if necessary, creates the accounts
and home directories, assigns the requested numeric IDs, and requires
students to change their temporary passwords at first login.

The script can safely be run again. Existing accounts with matching IDs
are skipped; accounts with conflicting IDs cause an error.

## 5. Repeat on the other Pis

Run the same procedure on the master and every compute node.

Use exactly the same CSV on every node so that usernames, UIDs and GIDs
remain consistent throughout the cluster.

The private CSV should be transferred to the other Pis securely, for
example using SCP over SSH. Remove the transferred CSV after account
creation if it is no longer needed.

## 6. Verify the accounts

Check an individual account:

```bash
id student-1
getent passwd student-1
```

Check the home directory:

```bash
ls -ld /home/student-1
```

The home directory should be accessible only to its owner.
