#!/usr/bin/env bash
# rog-tune: manual backup of my research to hp-server (rsync over SSH). Runs only when I ask; never deletes anything there.
#   what to copy: the folders I ticked (Settings -> Backup, or Spotlight -> "Back up"); stored one per line in ~/.config/spotlight/sync.list
#   where to:     hp-server:Media/rog-backup/  = the external drive on hp-server (override with ROG_SYNC_DEST)
#   sync-server.sh [-n]    -n shows what would be copied and changes nothing
DRY=; [[ ${1:-} == -n ]] && DRY=-n
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
# only new/changed files are sent (size + mtime); with "Mirror deletions" on, files I removed here are removed from the backup too
DEL=; [[ ${BACKUP_MIRROR:-0} == 1 ]] && DEL="--delete-after --max-delete=500"
DEST=${ROG_SYNC_DEST:-hp-server:Media/rog-backup}   # Media is the external drive on hp-server, NOT its SSD
LIST=$HOME/.config/spotlight/sync.list
if [[ -r $LIST ]]; then mapfile -t SRC < <(grep -v '^[[:space:]]*#' "$LIST" | sed '/^[[:space:]]*$/d; s|^~|'"$HOME"'|'); else SRC=("$HOME/notes" "$HOME/Documents"); fi
echo "Backing up to $DEST ${DRY:+(dry run) }- only new and changed files are sent${DEL:+; deleted files are removed from the backup too (Mirror deletions is on)}"
ssh -o BatchMode=yes -o ConnectTimeout=8 "${DEST%%:*}" true || { echo "cannot reach ${DEST%%:*}"; read -rp "Press Enter to close "; exit 1; }
# refuse to write unless the external drive is really mounted (otherwise the copy would silently fill the server's SSD)
if [[ $DEST == hp-server:Media/* ]] && ! ssh -o BatchMode=yes "${DEST%%:*}" 'mountpoint -q "$HOME/Media"'; then
	echo "The external drive (~/Media on hp-server) is not mounted. Nothing was copied."; read -rp "Press Enter to close "; exit 1
fi
[[ -n $DRY ]] || ssh "${DEST%%:*}" "mkdir -p '${DEST#*:}'"
rc=0
for s in "${SRC[@]}"; do
	[[ -e $s ]] || { echo "skip (missing): $s"; continue; }
	echo; echo "== $s"
	rsync -ah $DRY $DEL --partial --info=progress2,stats1 \
		--exclude=node_modules --exclude=__pycache__ --exclude='*.pyc' --exclude=.venv --exclude=venv --exclude=site-packages --exclude=.cache \
		"${s%/}" "$DEST/" || rc=$?
done
echo; if [[ $rc == 0 ]]; then echo "Done."; [[ -n $DRY ]] || { mkdir -p "$HOME/.local/state/spotlight"; date +%s >"$HOME/.local/state/spotlight/last-backup"; }; else echo "Finished with errors (rsync exit $rc)."; fi
read -rp "Press Enter to close "
