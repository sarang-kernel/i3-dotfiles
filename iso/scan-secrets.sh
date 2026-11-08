#!/usr/bin/env bash
# scan-secrets.sh DIR: refuse to publish if DIR looks like it holds keys, passwords or tokens. Exit 1 on any hit.
d=${1:?dir}; bad=0
hit() { printf 'SECRET? %s\n' "$*"; bad=1; }
grep -rIlE --exclude=scan-secrets.sh -- '-----BEGIN [A-Z ]*PRIVATE KEY|PRIVATE KEY-----|oauth_token|ghp_[A-Za-z0-9]{20,}|github_pat_|AKIA[0-9A-Z]{16}|xox[baprs]-[0-9A-Za-z-]{10,}|Passphrase=|PreSharedKey|wpa_passphrase|^[[:space:]]*psk[[:space:]]*=|[Pp]assword[[:space:]]*=[[:space:]]*[^[:space:]]|\$(y|6|5|2[aby])\$[./A-Za-z0-9]{8,}' "$d" 2>/dev/null | while read -r f; do hit "content: $f"; done | tee /tmp/.scan.$$ >/dev/null
find "$d" \( -name 'id_*' -o -name '*.pem' -o -name '*.psk' -o -name '*.p12' -o -name 'known_hosts*' -o -name 'authorized_keys' -o -name 'ssh_host_*' -o -name 'secrets*' -o -name 'shadow*' -o -name 'hosts.yml' -o -name '*.kdbx' -o -path '*/.gnupg/*' -o -path '*/.ssh/*' -o -path '*/lib/iwd/*' -o -path '*/lib/bluetooth/*' -o -path '*/system-connections/*' -o -name '.bash_history' \) -print 2>/dev/null | sed 's/^/SECRET? name: /' >>/tmp/.scan.$$
[[ -s /tmp/.scan.$$ ]] && { cat /tmp/.scan.$$; rm -f /tmp/.scan.$$; echo "scan: FAILED" >&2; exit 1; }
rm -f /tmp/.scan.$$; echo "scan: clean ($(find "$d" -type f | wc -l) files)"
