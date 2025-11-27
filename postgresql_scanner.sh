#!/bin/bash

echo "=============================================="
echo " PostgreSQL Default Credential Audit Tool"
echo "=============================================="
echo

read -p "Enter network range to scan (example: 192.168.1.0/24): " REDE
echo

OUTDIR="pg_results"
LOGFILE="$OUTDIR/full_audit.log"
SUCCESSFILE="$OUTDIR/success.txt"
FAILFILE="$OUTDIR/fail.txt"

mkdir -p "$OUTDIR"
> "$LOGFILE"
> "$SUCCESSFILE"
> "$FAILFILE"

echo "[*] Audit started at: $(date)" | tee -a "$LOGFILE"
echo "[*] Target network: $REDE" | tee -a "$LOGFILE"
echo "[*] Results directory: $OUTDIR" | tee -a "$LOGFILE"
echo >> "$LOGFILE"

# Controlled default credentials list (audit-safe)
CREDS=(
  "postgres:postgres"
  "postgres:admin"
  "admin:admin"
  "root:root"
  "postgres:"
)

echo "[*] Scanning network for PostgreSQL (5432)..."
echo "[*] Running Nmap discovery..." | tee -a "$LOGFILE"

# Discover PostgreSQL hosts
nmap -p5432 -Pn --open "$REDE" -n -oG - | grep "/open/" | while read -r line; do

    IP=$(echo "$line" | awk '{print $2}')
    echo "[*] PostgreSQL detected on $IP" >> "$LOGFILE"

    for cred in "${CREDS[@]}"; do
        USER="${cred%%:*}"
        PASS="${cred#*:}"

        echo "    [+] Trying $USER / $PASS" >> "$LOGFILE"

        RESULT=$(PGPASSWORD="$PASS" timeout 5 psql \
          -h "$IP" \
          -U "$USER" \
          -d postgres \
          -p 5432 \
          --pset footer=off \
          --pset format=aligned \
          -c "\l" 2>> "$LOGFILE")

        if [ $? -eq 0 ]; then
            echo
            echo "[+ VALID CREDENTIALS FOUND]"
            echo "Host      : $IP"
            echo "Username  : $USER"
            echo "Password  : $PASS"
            echo
            echo "[+] Databases on $IP:"
            echo "$RESULT"
            echo "----------------------------------------"

            echo "$IP $USER $PASS" >> "$SUCCESSFILE"
            echo "[SUCCESS] $IP $USER $PASS" >> "$LOGFILE"
            echo "$RESULT" >> "$LOGFILE"
            echo >> "$LOGFILE"
            break
        else
            echo "[FAIL] $IP $USER $PASS" >> "$FAILFILE"
        fi

        sleep 0.4
    done
done

echo
echo "[*] Audit completed at: $(date)"
echo "[*] Valid credentials: $SUCCESSFILE"
echo "[*] Failed attempts:   $FAILFILE"
echo "[*] Full forensic log: $LOGFILE"

