#!/usr/bin/env bash
# rog-snappy: make the CPU react faster (run with sudo). asusd sets the "Balanced" profile to the energy preference balance_power, which
# keeps the cores at 1.1-2.4 GHz until load has built up for a while: fine for battery, laggy for a desktop on the charger.
# This moves Balanced to balance_performance (still efficient, much quicker to ramp). Quiet keeps its power-saving preference.
# Undo: cp /etc/asusd/asusd.ron.bak-snappy /etc/asusd/asusd.ron && systemctl restart asusd
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
f=/etc/asusd/asusd.ron
grep -q "profile_balanced_epp: BalancePower," "$f" || { echo "nothing to change in $f"; exit 0; }
cp -n "$f" "$f.bak-snappy"
sed -i "s/profile_balanced_epp: BalancePower,/profile_balanced_epp: BalancePerformance,/" "$f"
systemctl restart asusd
sleep 2
for p in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do echo balance_performance > "$p" 2>/dev/null || true; done
echo "profile: $(cat /sys/firmware/acpi/platform_profile)   epp now: $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)"
