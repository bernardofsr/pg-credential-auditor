# PostgreSQL Default Credential Audit Script

Simple bash script to scan a network for exposed PostgreSQL services and test a small set of default credentials.

---

## Overview

- Asks for a network range (CIDR)
- Scans for PostgreSQL on port 5432
- Tests a small, controlled list of default credentials
- Shows output **only when valid credentials are found**
- Automatically lists databases on successful login
- Writes a full log of all activity to disk
- Non-destructive and read-only

---

## Requirements

You need:

- nmap
- postgresql-client

--- 

Install on Debian/Ubuntu/Kali:

```bash
sudo apt install nmap postgresql-client -y
