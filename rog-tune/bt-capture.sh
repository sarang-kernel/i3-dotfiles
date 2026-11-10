#!/bin/bash
# Records only Bluetooth connection events (connect, disconnect + reason, link timing, scanning). A whitelist keeps every data line out, so typed keys never reach the file.
# Run: sudo systemd-run --unit=bt-capture --property=RuntimeMaxSec=4h /home/sarang/rog-tune/bt-capture.sh    (stops by itself after 4 h or at reboot)
out=${1:-/var/tmp/bt-events.log}
: >"$out"; chmod 644 "$out"
stdbuf -oL btmon -T 2>&1 | grep --line-buffered -E 'Disconnect Complete|Reason:|LE .*Connection Complete|Connection Update|Connection interval:|Connection latency:|(Peripheral|Slave) latency:|Supervis[a-z]+ timeout:|Hardware Error|Accept List|Scan Enable|Create Connection|Peer address:' >>"$out"
