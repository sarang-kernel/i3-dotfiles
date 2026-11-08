#!/usr/bin/env bash
# rog-tune: update the system the careful way: show the Arch news since your last update first, then (if you agree) run pacman -Syu.
#   Arch occasionally needs a manual step before an update (a changed package, a config to edit); that is announced in the news.
red=$'\e[1;31m'; yel=$'\e[1;33m'; dim=$'\e[2m'; off=$'\e[0m'

D=${ROG_RESTORE_DIR:-/var/backups/rog-restore}
if [[ ${1:-} == --rollback ]]; then
	# Put the packages back to what they were at a restore point (taken automatically before every pacman transaction).
	echo "${yel}Roll back packages to a restore point${off}"
	pts=$(sudo ls -1d "$D"/*/ 2>/dev/null | sed 's:/$::' | tac)
	[[ -n $pts ]] || { echo "  no restore points yet (one is saved before your next pacman update)."; read -rp "Press Enter to close "; exit 0; }
	i=0; for p in $pts; do i=$((i+1)); n=$(sudo awk 'END{print NR}' "$p/versions.txt"); echo "  $i) $(basename "$p" | sed -E 's/^(....)(..)(..)-(..)(..).*/\1-\2-\3 \4:\5/')   kernel $(sudo cat "$p/kernel.txt" 2>/dev/null)   $n packages"; done
	read -rp "Which one? [1 = newest, Enter cancels] " n; [[ -n $n ]] || exit 0
	p=$(echo "$pts" | sed -n "${n}p"); [[ -n $p ]] || { echo "no such point"; read -rp "Press Enter "; exit 1; }
	files=(); missing=()
	while read -r name ver; do
		cur=$(pacman -Q "$name" 2>/dev/null | cut -d' ' -f2); [[ $cur == "$ver" ]] && continue
		if [[ -z $cur ]]; then continue; fi
		f=$(ls /var/cache/pacman/pkg/"$name"-"$ver"-*.pkg.tar.* 2>/dev/null | grep -v '\.sig$' | grep -E "/$name-$ver-[^-]+\.pkg" | head -1)
		[[ -n $f ]] && files+=("$f") || missing+=("$name $ver")
	done < <(sudo cat "$p/versions.txt")
	echo; echo "  ${#files[@]} package(s) can go back, ${#missing[@]} are no longer in the cache."
	for f in "${files[@]}"; do echo "    $(basename "$f")"; done | head -40
	((${#missing[@]})) && { echo "  ${dim}not in cache:${off} ${missing[*]:0:12}"; }
	((${#files[@]})) || { read -rp "Nothing to do. Press Enter to close "; exit 0; }
	echo "  ${dim}Your /etc files are NOT touched; they are saved in $p/etc.tar.gz if you ever need them.${off}"
	read -rp "${yel}Reinstall these older versions? [y/N] ${off}" a
	[[ $a == y || $a == Y ]] && sudo pacman -U "${files[@]}"
	read -rp "Done. Press Enter to close "; exit 0
fi
echo "${yel}Arch Linux news since your last update${off}"
python3 - <<'PY'
import re, subprocess, time, urllib.request, xml.etree.ElementTree as ET
from email.utils import parsedate_to_datetime
last = 0
try:
    for line in reversed(open("/var/log/pacman.log").read().splitlines()):
        if "starting full system upgrade" in line:
            ts = line[1:25] if line.startswith("[") else ""
            m = re.match(r"\[(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})", line)
            if m: last = time.mktime(time.strptime(m.group(1) + " " + m.group(2), "%Y-%m-%d %H:%M:%S"))
            break
except Exception: pass
try:
    xml = urllib.request.urlopen(urllib.request.Request("https://archlinux.org/feeds/news/", headers={"User-Agent": "rog-update"}), timeout=15).read()
except Exception as e:
    print("  could not fetch the news (%s). Check https://archlinux.org/news/ yourself before updating." % e); raise SystemExit
new = 0
for it in ET.fromstring(xml).iter("item"):
    when = parsedate_to_datetime(it.findtext("pubDate")).timestamp()
    if when <= last: continue
    new += 1; title = it.findtext("title"); link = it.findtext("link")
    flag = "  \033[1;31m<-- manual intervention\033[0m" if re.search(r"manual|intervention|requires|breaking|before upgrading", (title + (it.findtext("description") or "")), re.I) else ""
    print("  %s  %s%s\n     \033[2m%s\033[0m" % (time.strftime("%Y-%m-%d", time.localtime(when)), title, flag, link))
if not new: print("  (nothing new since your last update)")
PY
echo
read -rp "${yel}Continue with the update? [y/N] ${off}" a
[[ $a == y || $a == Y ]] || { echo "Cancelled."; read -rp "Press Enter to close "; exit 0; }
sudo pacman -Syu
echo
last=$(sudo ls -1d "$D"/*/ 2>/dev/null | tail -n1)
[[ -n $last ]] && echo "${dim}Restore point saved before this update: $(basename "${last%/}"). If something broke: rog-update.sh --rollback (or Spotlight: \"roll back update\").${off}"
left=$(find /etc -name '*.pacnew' 2>/dev/null | wc -l)
((left)) && echo "${yel}$left .pacnew file(s) in /etc: compare them with 'pacdiff' (or by hand) when you have a moment.${off}"
read -rp "Done. Press Enter to close "
