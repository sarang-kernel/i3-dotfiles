#!/usr/bin/env bash
# Session-side trimming + quality of life for rog (no sudo). Dry run by default; --undo restores everything it touched.
#   ~/rog-tune/rog-lean-session.sh [parts…]          show what would change
#   ~/rog-tune/rog-lean-session.sh --apply [parts…]  do it
#   ~/rog-tune/rog-lean-session.sh --undo            restore i3 config, polybar, kitty, .bashrc, autostart files
# parts (default: all except vaapi)
#   automount  disable the broken user unit home-sarang-mnt-server.automount (fails at every login)
#   picom      stop starting picom (i3 line AND /etc/xdg/autostart/picom.desktop, which dex would start anyway). My picom.conf
#              draws nothing (no shadows/fades/transparency) yet costs ~4 % of a core at 165 Hz. Cost: possible tearing
#   compositor lean picom (explicit config: no shadows/fades/blur, damage tracking, unredirects fullscreen) so terminals, polybar and
#              notifications can be translucent. Replaces the old 'picom' (= turn the compositor off) part
#   hz60       60 Hz at every login (the panel only offers 165 and 60)
#   autostart  stop launching nm-applet (NetworkManager is disabled; iwd does Wi-Fi), the GNOME disk-notify daemon and the
#              AT-SPI accessibility bus at login (apps start AT-SPI themselves when needed)
#   bash       lazy-load nvm in .bashrc: a new shell takes ~0.42 s today, ~0.1 s after (node 24 stays on PATH)
#   kitty      snappier terminal: repaint_delay 6, input_delay 1, no bell
#   xset       faster key repeat (250 ms delay, 50/s) and no X bell. Needs xorg-xset (it was not installed, so this did nothing until now)
#   polybar    stop polling: the mic indicator follows pulse events instead of spawning 2 processes every second;
#              brightness 1→3 s, clock 1→5 s, cpu/memory 2→3 s
#   shot       screenshots go to the CLIPBOARD (paste straight into chat/docs) and to ~/Pictures, with a notification:
#                Print / Insert        whole screen       Shift+Print / Shift+Insert / Shift+Delete   select an area
#                Ctrl+Print            area, clipboard only (no file)         Alt+Print   focused window
#   osd        volume / mic / brightness keys show an on-screen bar (dunst); volume steps 5 % instead of 10 %
#   ui         a consistent Catppuccin look at zero runtime cost (no compositor needed): i3 gaps, 2 px borders instead of title
#              bars, coloured focus; polybar icons instead of "VOL/BAT/CPU" text, wider spacing, no "|" separators; kitty's
#              theme (kitty.conf includes a theme.conf that is entirely commented out, hence the plain black terminals);
#              a dunst config (none exists, so notifications use dunst's defaults); dark GTK apps with Papirus-Dark icons
#   quiet      no on-screen bars, no notifications (the notification daemon is parked), silent screenshots; brightness shown in the bar
#   keys       Super+F1 (or Super+/) opens a searchable menu of every i3 keybind
#   focus      macOS-style centred clock, focus FOLLOWS the mouse (kept), vim-style resize, Super+Ctrl+H/L between workspaces
#   power      on AC: blur + 90 Hz. On battery: no blur, 60 Hz. Switches by itself when I plug/unplug (event driven, no polling)
#   loginbg    keeps the login screen's wallpaper in step with the desktop wallpaper
#   lock       the lock screen shows my current wallpaper, blurred and darkened (the old script passed a JPEG to i3lock, which only
#              reads PNG, and read ~/.fehbg, which my wallpaper script never updates)
#   idle       lock + screen off by power source (AC: 10 / 15 min, battery: 2 / 3 min) and lock before suspend (xss-lock)
#   ocr        Super+Print: select an area, its text lands on the clipboard (tesseract)
#   night      Super+Shift+N toggles a warm night tint (~4000 K, display gamma, no daemon); Super+Alt+N returns to the schedule
#              (on 19:00-07:00, like my wallpapers). Survives mode switches
#   sysmon     clicking CPU or RAM in the bar, or Super+Shift+Esc, opens a proper GUI task monitor (Mission Center; falls back to
#              Resources, GNOME System Monitor, then btop)
#   psd        browser profiles (Chrome, Firefox) live in RAM and sync back to disk: much snappier browsers. Costs ~2 GB of RAM
#   rotate     the session's auto-rotate: panel, touchscreen and pen follow the accelerometer from the moment I log in (my script only
#              reacted to later changes, skipped the pen and started a new copy at every i3 restart). Super+Shift+O freezes it
#   spotlight  Super+D: a real Spotlight. Searches AS YOU TYPE: apps (most-used first), open windows, files (plocate), maths and unit
#              conversion (qalc), clipboard history (c ...), commands (> ...), system actions (lock, sleep, night tint ...). Vim keys
#   settings   Super+comma (or Spotlight: "settings"): one window for everything I can toggle or fiddle with (night tint, lock timers,
#              battery profile, blur, focus-follows-mouse, rotation, tablet mode, Spotlight, backup). Applies immediately
#   caffeine   Super+Shift+I keeps the screen on and unlocked; (nothing is shown in the bar). It also switches on BY ITSELF
#              while a window is fullscreen or an app uses the microphone (video, calls); music does not count
#   tablet     Super+Shift+T toggles tablet mode (OFF by default): an on-screen keyboard that pops up when I touch a text field. Needs onboard
#   pin        Super+Shift+P: float the window, keep it above everything and on every workspace (press again to tile it back)
#   input      touchpad (tap, natural scrolling, palm rejection), pointer speed, key repeat and starting with the mic muted, all from Settings
#   barfont    workspace numbers in a lighter font, and a compact box around the active workspace; weight, size and box/line are in Settings
#   mode       (part of power) Super+Alt+M cycles Quiet / Balanced / Performance; default Balanced on AC, Quiet on battery
#   display    adaptive refresh (after a while without input the panel drops to the idle rate, any key or touch brings the full rate back, no
#              polling) and cinema mode (a fullscreen video player gets a rate that divides the film's frame rate, 71.928 Hz for 23.976 fps)
#   vaapi      (opt-in) GPU video decoding in Chrome/Firefox/Zen, so video stops burning CPU. Unverified on this machine
set -euo pipefail
H=$HOME
BK=${ROG_BK:-$H/.local/share/rog-tune}; mkdir -p "$BK"
I3=$H/.config/i3/config PB=$H/.config/polybar/config.ini KC=$H/.config/kitty/kitty.conf BRC=$H/.bashrc
SD=$H/.config/scripts AS=$H/.config/autostart
ALL=(automount compositor power loginbg autostart bash kitty xset polybar shot osd ui quiet keys focus lock idle ocr night sysmon psd rotate spotlight caffeine tablet pin input barfont display)
APPLY=0 UNDO=0 PARTS=()
for a in "$@"; do case $a in
	--apply) APPLY=1 ;; --undo) UNDO=1 ;;
	automount | picom | compositor | hz60 | autostart | bash | kitty | shot | osd | ui | quiet | keys | focus | power | loginbg | lock | idle | ocr | night | sysmon | psd | rotate | spotlight | caffeine | tablet | pin | input | barfont | display | vaapi) PARTS+=("$a") ;;
	polybar | xset) PARTS+=("$a") ;;
	*) sed -n '2,70p' "$0"; exit 1 ;; esac; done
((${#PARTS[@]})) || PARTS=("${ALL[@]}")
has() { [[ " ${PARTS[*]} " == *" $1 "* ]]; }
live() { [[ -n ${ROG_BK:-} ]] && { echo "  (test) $*"; return 0; }; "$@"; }
MARK='rog-tune'

if ((UNDO)); then
	for f in i3config:"$I3" polybar.ini:"$PB" kitty.conf:"$KC" bashrc:"$BRC" picom.conf:"$H/.config/picom/picom.conf" rofi-main:"$H/.config/rofi/catppuccin-mocha.rasi" rofi-power:"$H/.config/rofi/powermenu.rasi" wallcycle:"$H/.config/wallpaper-config/wallpaper-cycle.sh" wallcycle-rev:"$H/.config/wallpaper-config/wallpaper-cycle-reverse.sh" lock:"$H/.config/i3lock/lock.sh"; do
		[[ -e $BK/${f%%:*}.before ]] && cp -a --remove-destination "$BK/${f%%:*}.before" "${f#*:}" && echo "restored ${f#*:}"
	done
	{ grep -l "^# $MARK" "$AS"/*.desktop 2>/dev/null || true; } | xargs -r rm -v
	if [[ -e $BK/created.list ]]; then while IFS= read -r f; do rm -fv "$f"; done <"$BK/created.list"; rm -f "$BK/created.list"; fi
	for u in "$H"/.config/mozilla/firefox/*/user.js "$H"/.zen/*/user.js; do [[ -e $u ]] && grep -q "$MARK" "$u" && sed -i "/$MARK/,/\/$MARK/d" "$u" && echo "cleaned $u"; done
	[[ -e $BK/psd.enabled ]] && { live systemctl --user disable --now psd.service; rm -f "$BK/psd.enabled"; echo "psd disabled"; }
	[[ -e $BK/dunst.masked ]] && { live systemctl --user unmask dunst.service; rm -f "$BK/dunst.masked"; echo "notifications back on"; }
	[[ -e $BK/automount.was-enabled ]] && live systemctl --user enable home-sarang-mnt-server.automount && echo "automount re-enabled"
	echo "done (log out and in, or i3-msg restart)"; exit 0
fi

g() { python3 -c "print(chr(0x$1), end='')"; }
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
cp "$I3" "$W/i3"; cp "$PB" "$W/pb"; cp "$KC" "$W/kc"; cp "$BRC" "$W/brc"
ADD=() # extra files to write: dest|content-file

# set KEY=VAL inside [SECTION] of an ini ($1 file $2 section $3 key $4 val); replaces the line, or appends to the section
ini_set() { awk -v sec="[$2]" -v key="$3" -v val="$4" '
	/^\[/ { if (insec && !done) { print key " = " val; done=1 } insec = ($0 == sec) }
	insec && $0 ~ "^"key"[ \t]*=" { print key " = " val; done=1; next }
	{ print }
	END { if (insec && !done) print key " = " val }' "$1" >"$1.n" && mv "$1.n" "$1"; }
ini_get() { awk -v sec="[$2]" -v key="$3" '/^\[/{insec=($0==sec)} insec && $0 ~ "^"key"[ \t]*=" {sub(/^[^=]*=[ \t]*/,""); print; exit}' "$1"; }
ini_del() { awk -v sec="[$2]" -v key="$3" '/^\[/{insec=($0==sec)} !(insec && $0 ~ "^"key"[ \t]*=")' "$1" >"$1.n" && mv "$1.n" "$1"; }
append_once() { grep -q "$MARK: $3" "$1" || printf '%s\n' "$2" >>"$1"; } # file, text, tag

hide_autostart=()
if has picom; then
	sed -i -E 's|^(exec --no-startup-id picom\s*)$|# rog-tune: \1|' "$W/i3"
	hide_autostart+=(picom)
fi
if has compositor; then
	sed -i -E -e 's|^(# rog-tune: )?exec --no-startup-id picom\s*$|exec --no-startup-id picom --config ~/.config/picom/picom.conf|' "$W/i3"
	hide_autostart+=(picom)   # i3 starts it; dex must not start a second one
	cat >"$W/picom-ac.conf" <<'E'
# rog-tune: picom for Hyprland-style translucency: windows with alpha (kitty, rofi, polybar) show the blurred wallpaper behind them.
# Opaque windows are never blurred; everything else costly is off.
backend = "glx";
vsync = true;
use-damage = true;                 # redraw only what changed
unredir-if-possible = true;        # fullscreen apps/video bypass the compositor entirely
shadow = false;
fading = false;
corner-radius = 0;
corner-radius-rules = [ "26:class_g = 'Spotlight'" ];   # only the Spotlight box has rounded corners
blur-method = "dual_kawase";
blur-strength = 6;
blur-background = true;
blur-background-exclude = [ "window_type = 'desktop'" ];
inactive-dim = 0.10;               # the unfocused window recedes a little (focus cue)
inactive-dim-fixed = true;
focus-exclude = [ "class_g = 'Rofi'", "class_g = 'Polybar'" ];
detect-client-opacity = true;
mark-wmwin-focused = true;
mark-ovredir-focused = true;
E
	cat >"$W/picom-bat.conf" <<'E'
# rog-tune: picom on battery / in Quiet mode: translucent but no blur and no dimming, so the GPU stays near idle.
# The one exception is the Spotlight box, which is blurred (only while it is open) so its text stays readable.
backend = "glx";
vsync = true;
use-damage = true;
unredir-if-possible = true;
shadow = false;
fading = false;
corner-radius = 0;
corner-radius-rules = [ "26:class_g = 'Spotlight'" ];   # only the Spotlight box has rounded corners
detect-client-opacity = true;
mark-wmwin-focused = true;
mark-ovredir-focused = true;
blur-method = "dual_kawase";
blur-strength = 6;
blur-background = true;
blur-background-exclude = [ "!class_g = 'Spotlight'" ];   # blur nothing except Spotlight
E
	ADD+=("$H/.config/picom/picom-ac.conf|$W/picom-ac.conf" "$H/.config/picom/picom-bat.conf|$W/picom-bat.conf")
fi
if has autostart; then
	sed -i -E 's|^(exec --no-startup-id nm-applet\s*)$|# rog-tune: \1|' "$W/i3"
	hide_autostart+=(nm-applet org.gnome.SettingsDaemon.DiskUtilityNotify at-spi-dbus-bus)
fi
has hz60 && append_once "$W/i3" "exec_always --no-startup-id xrandr --output eDP-1 --rate 60  # rog-tune: hz60" hz60
if has xset; then
	sed -i -E "/# rog-tune: xset\$/d" "$W/i3"
	append_once "$W/i3" "exec_always --no-startup-id sh -c 'command -v xset >/dev/null && { xset r rate 250 50; xset b off; }'  # rog-tune: xset" xset
fi

if has shot; then
	sed -i -E '/^bindsym (Print|Insert|Shift\+Print|Shift\+Insert|Shift\+Delete) exec scrot/d' "$W/i3"
	if ! grep -q "$MARK: shot" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: shot — screenshots land on the clipboard (and in ~/Pictures unless noted)
bindsym Print exec --no-startup-id ~/.config/scripts/shot.sh full
bindsym Insert exec --no-startup-id ~/.config/scripts/shot.sh full
bindsym Shift+Print exec --no-startup-id ~/.config/scripts/shot.sh area
bindsym Shift+Insert exec --no-startup-id ~/.config/scripts/shot.sh area
bindsym Shift+Delete exec --no-startup-id ~/.config/scripts/shot.sh area
bindsym Ctrl+Print exec --no-startup-id ~/.config/scripts/shot.sh area-clip
bindsym Mod1+Print exec --no-startup-id ~/.config/scripts/shot.sh window
E
	fi
	cat >"$W/shot.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: screenshot → clipboard (PNG, pastes into browsers/chat/editors) + ~/Pictures. Silent.
# usage: shot.sh full|area|window|area-clip      (area-clip: clipboard only, no file)
set -u
mode=${1:-full}
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"   # Settings: SHOT_SAVE=0 means clipboard only
dir=${XDG_PICTURES_DIR:-$HOME/Pictures}; mkdir -p "$dir"
name=screenshot_$(date +%Y-%m-%d_%H-%M-%S).png
case $mode in
area-clip) f=$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/shot.XXXXXX.png"); keep=0 ;;
*) if [[ ${SHOT_SAVE:-1} == 0 ]]; then f=$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/shot.XXXXXX.png"); keep=0; else f=$dir/$name; keep=1; fi ;;
esac
case $mode in
full) scrot -o "$f" ;;
window) scrot -o -u "$f" ;;
area | area-clip) scrot -o -s "$f" ;;
*) echo "usage: $0 full|area|window|area-clip" >&2; exit 2 ;;
esac || { rm -f "$f"; exit 0; }            # Esc during selection: quietly do nothing
[[ -s $f ]] || { rm -f "$f"; exit 0; }
xclip -selection clipboard -t image/png -i "$f"
((keep)) || rm -f "$f"
E
	ADD+=("$SD/shot.sh|$W/shot.sh")
fi

if has osd; then
	sed -i -E \
	 -e 's|^(bindsym XF86AudioRaiseVolume).*|\1 exec --no-startup-id ~/.config/scripts/osd.sh vol up|' \
	 -e 's|^(bindsym XF86AudioLowerVolume).*|\1 exec --no-startup-id ~/.config/scripts/osd.sh vol down|' \
	 -e 's|^(bindsym XF86AudioMute).*|\1 exec --no-startup-id ~/.config/scripts/osd.sh vol mute|' \
	 -e 's|^(bindsym XF86AudioMicMute).*|\1 exec --no-startup-id ~/.config/scripts/osd.sh mic|' \
	 -e 's|^(bindsym XF86MonBrightnessUp).*|\1 exec --no-startup-id ~/.config/scripts/osd.sh bri up|' \
	 -e 's|^(bindsym XF86MonBrightnessDown).*|\1 exec --no-startup-id ~/.config/scripts/osd.sh bri down|' "$W/i3"
	cat >"$W/osd.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: volume / mic / brightness actions. Silent: no bars, no popups (the bar shows the state).
set -u
case $1 in
vol)
	case $2 in
	up) pactl set-sink-mute @DEFAULT_SINK@ 0; pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
	down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
	mute) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
	esac ;;
mic) pactl set-source-mute @DEFAULT_SOURCE@ toggle ;;
bri)
	BL=(); [[ -d /sys/class/backlight/nvidia_wmi_ec_backlight ]] && BL=(-d nvidia_wmi_ec_backlight)
	case $2 in
	up) brightnessctl -q "${BL[@]}" set +5% ;;
	down) brightnessctl -q -n1 "${BL[@]}" set 5%- ;;
	up1) brightnessctl -q "${BL[@]}" set +1% ;;
	down1) brightnessctl -q -n1 "${BL[@]}" set 1%- ;;
	esac
	# remember it: the next login restores it (the login screen may have been raised to stay readable)
	mkdir -p "$HOME/.local/state/rog"; brightnessctl "${BL[@]}" -m | cut -d, -f4 | tr -d '%' >"$HOME/.local/state/rog/brightness" ;;
esac
E
	ADD+=("$SD/osd.sh|$W/osd.sh")
fi

if has polybar; then
	ini_set "$W/pb" module/mic exec "~/.config/polybar/scripts/mic-follow.sh"
	ini_set "$W/pb" module/mic tail true
	ini_set "$W/pb" module/brightness scroll-up "~/.config/scripts/osd.sh bri up1"
	ini_set "$W/pb" module/brightness scroll-down "~/.config/scripts/osd.sh bri down1"
	ini_del "$W/pb" module/mic interval
	ini_set "$W/pb" module/brightness exec "~/.config/polybar/scripts/bri-follow.sh"
	ini_set "$W/pb" module/brightness tail true
	ini_del "$W/pb" module/brightness interval
	ini_set "$W/pb" module/date interval 5
	ini_set "$W/pb" module/memory interval 3
	ini_set "$W/pb" module/cpu interval 3
	cat >"$W/mic-follow.sh" <<'E'
#!/bin/sh
# rog-tune: polybar mic indicator, event driven (no polling). Always visible: quiet grey = live, red = muted. Click toggles.
show() { if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q yes; then echo "%{F#e06c5a}@OFF@  muted%{F-}"; else echo "%{F#9b9084}@ON@  live%{F-}"; fi; }
show
f=$(mktemp -u "${XDG_RUNTIME_DIR:-/tmp}/micfollow.XXXXXX"); mkfifo "$f"
pactl subscribe >"$f" 2>/dev/null & P=$!
trap 'kill "$P" 2>/dev/null; rm -f "$f"; exit 0' INT TERM HUP    # polybar restarts must not leave a pactl behind
trap 'kill "$P" 2>/dev/null; rm -f "$f"' EXIT
while read -r l; do case $l in *source*|*server*) show ;; esac; done <"$f"
E
	sed -i "s/@OFF@/$(g f131)/; s/@ON@/$(g f130)/" "$W/mic-follow.sh"
	ADD+=("$H/.config/polybar/scripts/mic-follow.sh|$W/mic-follow.sh")
	cat >"$W/bri-follow.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: polybar brightness indicator. No polling processes: reads sysfs with shell builtins and waits on a private fifo.
d=/sys/class/backlight/nvidia_wmi_ec_backlight; [[ -d $d ]] || d=$(ls -d /sys/class/backlight/* | head -n1)
read -r max <"$d/max_brightness"
f=$(mktemp -u); mkfifo "$f"; exec 3<>"$f"; rm -f "$f"
last=
while :; do
	read -r v <"$d/brightness"
	[[ $v != "$last" ]] && { echo "@ICON@  $((v * 100 / max))%"; last=$v; }
	read -r -t 0.4 -u 3 _ || true
done
E
	sed -i "s/@ICON@/$(g f185)/" "$W/bri-follow.sh"
	ADD+=("$H/.config/polybar/scripts/bri-follow.sh|$W/bri-follow.sh")
fi

if has kitty && ! grep -q "$MARK: kitty" "$W/kc"; then cat >>"$W/kc" <<'E'

# rog-tune: kitty — lower input latency
repaint_delay 6
input_delay 1
enable_audio_bell no
E
fi

if has bash && ! grep -q "$MARK: history" "$W/brc"; then
	cat >>"$W/brc" <<'E'

# rog-tune: history — every command is written to ~/.bash_history at once, so Spotlight's "h ..." search finds it from any terminal
shopt -s histappend
HISTSIZE=50000; HISTFILESIZE=100000
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
E
fi
if has bash && grep -q '^\[ -s "\$NVM_DIR/nvm.sh" \]' "$W/brc"; then
	ver=$(cat "$H/.nvm/alias/default" 2>/dev/null || echo)
	python3 - "$W/brc" "$ver" <<'E'
import sys,re
p,ver=sys.argv[1],sys.argv[2]
s=open(p).read()
s=re.sub(r'\[ -s "\$NVM_DIR/nvm.sh" \] && .*\n\[ -s "\$NVM_DIR/bash_completion" \] && .*\n',
'''# rog-tune: lazy nvm — node %s is on PATH immediately, nvm itself loads the first time you call it
_nvm_bin=$(ls -d "$NVM_DIR"/versions/node/v%s*/bin 2>/dev/null | tail -n1)
[ -n "$_nvm_bin" ] && PATH="$_nvm_bin:$PATH"
unset _nvm_bin
nvm() { unset -f nvm; . "$NVM_DIR/nvm.sh"; . "$NVM_DIR/bash_completion"; nvm "$@"; }
''' % (ver or "default", ver or ""), s)
open(p,'w').write(s)
E
fi

if has vaapi; then
	ADD+=("$H/.config/chrome-flags.conf|$W/chrome-flags.conf")
	printf '%s\n' '--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiIgnoreDriverChecks' >"$W/chrome-flags.conf"
fi

if has ui; then
	if ! grep -q "$MARK: ui" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: ui — Catppuccin Mocha, pixel borders (no title bars), windows tile edge to edge
default_border pixel 2
default_floating_border pixel 2
hide_edge_borders smart
client.focused          #e0a458 #1c1917 #e7dfd3 #e0a458 #e0a458
client.focused_inactive #3a342e #1c1917 #b5aa9a #3a342e #3a342e
client.unfocused        #2b2622 #14110f #6e655a #2b2622 #2b2622
client.urgent           #e06c5a #e06c5a #0f0d0c #e06c5a #e06c5a
client.placeholder      #14110f #14110f #e7dfd3 #14110f #14110f
client.background       #1c1917
exec_always --no-startup-id xsetroot -cursor_name left_ptr
E
	fi
	sed -i -E '/^gaps (inner|outer) [0-9]+$/d; /^smart_gaps on$/d' "$W/i3"
	if grep -q "^# rog-tune: kittycolors" "$W/kc"; then awk '/^# rog-tune: kittycolors/{exit} {print}' "$W/kc" >"$W/kc.n" && mv "$W/kc.n" "$W/kc"; fi
	if ! grep -q "$MARK: binds" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: binds — notifications, bar toggle, small conveniences
bindsym $mod+n exec --no-startup-id dunstctl history-pop
bindsym $mod+Shift+n exec --no-startup-id dunstctl set-paused toggle
bindsym $mod+Ctrl+n exec --no-startup-id dunstctl close-all
bindsym $mod+b exec --no-startup-id polybar-msg cmd toggle
workspace_auto_back_and_forth yes
for_window [class="Pavucontrol"] floating enable
for_window [class="Blueberry.py"] floating enable
for_window [class="Nm-connection-editor"] floating enable
for_window [class="Lxappearance"] floating enable
for_window [window_role="pop-up"] floating enable
for_window [window_type="dialog"] floating enable
E
	fi
	# warm palette over the existing colour names, so every module follows
	declare -A WARM=([base]=#1c1917 [mantle]=#14110f [crust]=#0f0d0c [text]=#e7dfd3 [subtext0]=#b5aa9a [subtext1]=#cfc5b5 [surface0]=#2b2622 [surface1]=#3a342e [surface2]=#4a4239 [overlay0]=#6e655a [overlay1]=#857b6e [overlay2]=#9b9084 [blue]=#d4a373 [lavender]=#e0b88a [sapphire]=#c99a6b [sky]=#d9b48f [teal]=#b8a58a [green]=#a3a27a [yellow]=#e5c07b [peach]=#e39a5f [maroon]=#c8786a [red]=#e06c5a [mauve]=#e0a458 [pink]=#d98c7a [flamingo]=#e6b3a1 [rosewater]=#f0d9c8)
	for k in "${!WARM[@]}"; do ini_set "$W/pb" colors "$k" "${WARM[$k]}"; done
	declare -A CL=([focused]="#e0a458 #1c1917 #e7dfd3 #e0a458 #e0a458" [focused_inactive]="#3a342e #1c1917 #b5aa9a #3a342e #3a342e" [unfocused]="#2b2622 #14110f #6e655a #2b2622 #2b2622" [urgent]="#e06c5a #e06c5a #0f0d0c #e06c5a #e06c5a" [placeholder]="#14110f #14110f #e7dfd3 #14110f #14110f")
	for k in "${!CL[@]}"; do sed -i -E "s|^client\.$k +.*|client.$k  ${CL[$k]}|" "$W/i3"; done
	sed -i -E 's|^client\.background +.*|client.background       #1c1917|; s|^# rog-tune: ui — .*|# rog-tune: ui — warm palette, pixel borders (no title bars), windows tile edge to edge|' "$W/i3"
	ini_set "$W/pb" bar/toph separator '""'
	ini_set "$W/pb" bar/toph module-margin 2
	ini_set "$W/pb" bar/toph padding-left 1
	ini_set "$W/pb" bar/toph padding-right 2
	ini_set "$W/pb" bar/toph background '#d9000000'
	ini_set "$W/pb" module/pulseaudio format-volume-prefix "\"$(g f028)  \""
	ini_set "$W/pb" module/pulseaudio label-muted "$(g f026)  muted"
	ini_set "$W/pb" module/memory format-prefix "\"$(g f2db)  \""
	ini_set "$W/pb" module/cpu format-prefix "\"$(g f085)  \""
	ini_set "$W/pb" module/battery format-prefix "\"\""
	ini_set "$W/pb" module/date label "$(g f017)  %date%"
	ini_set "$W/pb" module/xworkspaces label-active-padding 2
	ini_set "$W/pb" module/xworkspaces label-occupied-padding 2
	ini_set "$W/pb" module/xworkspaces label-urgent-padding 2
	ini_set "$W/pb" module/xworkspaces label-empty-padding 2
	cat >>"$W/kc" <<'E'
E
	if ! grep -q "$MARK: kittycolors" "$W/kc"; then cat >>"$W/kc" <<'E'

# rog-tune: kittycolors — black, translucent (blurred wallpaper behind, via picom); warm palette.
# ctrl+shift+a then m / l = more / less opaque, a then 1 = fully opaque, a then d = back to default
background_opacity 0.78
dynamic_background_opacity yes
foreground #E7DFD3
background #000000
selection_foreground #000000
selection_background #E0A458
cursor #E0A458
cursor_text_color #000000
url_color #E5C07B
color0 #3A342E
color8 #6E655A
color1 #EA6962
color9 #EA6962
color2 #A9B665
color10 #A9B665
color3 #D8A657
color11 #D8A657
color4 #7DAEA3
color12 #7DAEA3
color5 #D3869B
color13 #D3869B
color6 #89B482
color14 #89B482
color7 #CFC5B5
color15 #E7DFD3
E
	fi
	# rofi: same warm palette, translucent window (picom blurs it)
	cp "$H/.config/rofi/catppuccin-mocha.rasi" "$W/rofi-main" 2>/dev/null && cp "$H/.config/rofi/powermenu.rasi" "$W/rofi-power" 2>/dev/null && python3 - "$W/rofi-main" "$W/rofi-power" <<'E'
import re,sys
M={'#1e1e2e':'#1c1917','#181825':'#14110f','#313244':'#2b2622','#89b4fa':'#e0a458','#cdd6f4':'#e7dfd3','#a6adc8':'#b5aa9a','#f38ba8':'#e06c5a',
   '#0d0f14':'#0f0d0c','#13161d':'#14110f','#1a1d28':'#1c1917','#2a3050':'#3a342e','#7aa2f7':'#e0a458','#bb9af7':'#e39a5f','#f7768e':'#e06c5a','#c0caf5':'#e7dfd3','#ffffff':'#f5ede0','#3b4261':'#6e655a'}
for f in sys.argv[1:]:
    t=open(f).read()
    for a,b in M.items(): t=re.sub(re.escape(a),b,t,flags=re.I)
    if f.endswith('main'):
        t=re.sub(r'(window \{[^}]*?background-color:\s*)@bg-col;',r'\1#1c1917d9;',t,count=1)
        t=re.sub(r'(mainbox \{[^}]*?background-color:\s*)@bg-col;',r'\1transparent;',t,count=1)
    open(f,'w').write(t)
E
	cat >"$W/dunstrc" <<'E'
# rog-tune: dunst — Catppuccin Mocha, square corners (no compositor here), progress bar for the volume/brightness OSD
[global]
    monitor = 0
    follow = keyboard
    width = (260, 380)
    origin = top-right
    offset = (16, 16)
    notification_limit = 5
    gap_size = 8
    padding = 12
    horizontal_padding = 14
    frame_width = 2
    corner_radius = 0
    progress_bar_height = 10
    progress_bar_frame_width = 0
    indicate_hidden = yes
    separator_height = 0
    font = MesloLGS Nerd Font Mono 11
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    icon_position = left
    max_icon_size = 56
    enable_recursive_icon_lookup = true
    icon_theme = Papirus-Dark
    sticky_history = yes
    history_length = 30
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all
[urgency_low]
    background = "#1e1e2ee6"
    foreground = "#a6adc8"
    frame_color = "#45475a"
    timeout = 4
[urgency_normal]
    background = "#1e1e2ee6"
    foreground = "#cdd6f4"
    frame_color = "#cba6f7"
    highlight = "#cba6f7"
    timeout = 6
[urgency_critical]
    background = "#1e1e2ee6"
    foreground = "#cdd6f4"
    frame_color = "#f38ba8"
    highlight = "#f38ba8"
    timeout = 0
E
	printf '[Settings]\ngtk-application-prefer-dark-theme=1\ngtk-icon-theme-name=Papirus-Dark\ngtk-font-name=Noto Sans 11\ngtk-cursor-theme-name=Adwaita\ngtk-cursor-theme-size=32\n' >"$W/gtk.ini"
	ADD+=("$H/.config/dunst/dunstrc|$W/dunstrc" "$H/.config/gtk-3.0/settings.ini|$W/gtk.ini" "$H/.config/gtk-4.0/settings.ini|$W/gtk.ini")
fi

if has power; then
	sed -i -E '/# rog-tune: hz60$/d' "$W/i3"
	append_once "$W/i3" "exec_always --no-startup-id ~/.config/scripts/power-watch.sh  # rog-tune: power" power
	cat >"$W/power-watch.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: power-aware behaviour, event driven (upower). Re-applied on every plug/unplug.
#   AC:      Balanced mode (blur, 90 Hz), lock after 10 min / screen off after 15
#   battery: Quiet mode (power-saver, 60 Hz, no blur), lock after 2 min / screen off after 3
#   (modes and rates can be changed in Settings; see power-mode.sh)
#   power-watch.sh            run in the background (started by i3)
#   power-watch.sh once ac|bat|auto    apply once and exit (to try it)
#   power-watch.sh timers              re-apply only the lock/blank timers (caffeine uses it)
#   power-watch.sh display             re-apply only the performance mode, refresh rate and CPU profile (Settings and power-mode.sh use it)
#   power-watch.sh autoquiet           re-check the low-battery Quiet override now
#   power-watch.sh refresh             apply only the refresh rate that fits right now (Quiet / cinema / idle / my setting)
#   power-watch.sh rate                print my configured rate for the current power source (60 in Quiet)
PIDF=${XDG_RUNTIME_DIR:-/tmp}/power-watch.pid
PS=${ROG_PS:-/sys/class/power_supply}      # (overridable for tests)
AQ=${XDG_RUNTIME_DIR:-/tmp}/autoquiet.on
ac_online() {
	local f
	for f in "$PS"/*/online; do
		[[ -r $f && $(<"${f%online}type") == Mains ]] && { [[ $(<"$f") == 1 ]] && return 0 || return 1; }
	done
	return 0
}
set_refresh() { # any rate from 60 to 165 Hz: 60 and 165 are the panel's own modes; the rest use the same timings at another pixel clock
	local hz=$1 name clk
	# the panel is eDP-1 or eDP-2 depending on which GPU driver registered first: always look it up
	local panel; panel=$(xrandr --current | awk '/^eDP[^ ]* connected/{print $1; exit}'); panel=${panel:-eDP-1}
	if [[ $hz == 60 || $hz == 165 ]]; then xrandr --output "$panel" --mode 2560x1600 --rate "$hz" 2>/dev/null && return 0; fi
	name=2560x1600_$hz
	if ! xrandr | grep -q "^   $name "; then
		clk=$(awk -v r="$hz" 'BEGIN{printf "%.3f", 2735*1732*r/1e6}')
		xrandr --newmode "$name" "$clk" 2560 2608 2640 2735 1600 1603 1609 1732 -HSync -VSync 2>/dev/null
		xrandr --addmode "$panel" "$name" 2>/dev/null
	fi
	xrandr --output "$panel" --mode "$name" 2>/dev/null || xrandr --output "$panel" --mode 2560x1600 --rate 60
}
timers() { # screen lock / blank timers by power source; caffeine (a state file) switches them off
	command -v xset >/dev/null || return 0
	local want=$1
	[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
	[[ $want == auto ]] && { ac_online && want=ac || want=bat; }
	if [[ -e ${XDG_STATE_HOME:-$HOME/.local/state}/caffeine || -e ${XDG_RUNTIME_DIR:-/tmp}/autocaffeine.on ]]; then xset s off -dpms; return 0; fi
	xset s noblank +dpms
	if [[ $want == ac ]]; then xset s $((${LOCK_AC:-10} * 60)) $((${LOCK_AC:-10} * 60)); xset dpms 0 0 $((${OFF_AC:-15} * 60))
	else xset s $((${LOCK_BAT:-2} * 60)) $((${LOCK_BAT:-2} * 60)); xset dpms 0 0 $((${OFF_BAT:-3} * 60)); fi
}
mode_of() { # ac|bat -> quiet|balanced|performance, from the Settings app (also reads the older profile names)
	local m
	[[ $1 == bat && -e $AQ ]] && { echo quiet; return; }          # low-battery override (see autoquiet_check)
	[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
	if [[ $1 == ac ]]; then
		m=${MODE_AC:-}; [[ -n $m ]] || case ${AC_PROFILE:-balanced} in performance) m=performance ;; *) m=balanced ;; esac
	else
		m=${MODE_BAT:-}; [[ -n $m ]] || case ${BAT_PROFILE:-power-saver} in balanced) m=balanced ;; performance) m=performance ;; *) m=quiet ;; esac
	fi
	echo "$m"
}
style_apply() { # compositor look: blur and dimming only on AC and never in Quiet mode
	local want=$1 pc=$HOME/.config/picom pid
	if [[ $want == ac && $(mode_of ac) != quiet ]]; then ln -sfn picom-ac.conf "$pc/picom.conf"; else ln -sfn picom-bat.conf "$pc/picom.conf"; fi
	pid=$(pgrep -xo -u "$UID" picom) && kill -USR1 "$pid"
}
target_hz() { # ac|bat -> the refresh rate to use right now: cinema = the film rate; Quiet = 60; idle (adaptive) = the idle rate; else my setting
	local want=$1 m hz rt=${XDG_RUNTIME_DIR:-/tmp}
	[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
	[[ -e $rt/cinema.on ]] && { if [[ -s $rt/cinema.hz ]]; then cat "$rt/cinema.hz"; else echo "${CINEMA_HZ:-71.928}"; fi; return; }      # a film in fullscreen beats everything, Quiet included
	m=$(mode_of "$want"); [[ $m == quiet ]] && { echo 60; return; }
	if [[ $want == ac ]]; then hz=${RATE_AC:-90}; else hz=${RATE_BAT:-60}; fi
	if [[ -e $rt/adaptive.low ]] && awk -v a="$hz" -v b="${IDLE_HZ:-60}" 'BEGIN{exit !(a>b)}'; then echo "${IDLE_HZ:-60}"; return; fi
	echo "$hz"
}
refresh_only() { # apply just the refresh rate (the display agent calls this); never while locked or with the screen off (a modeset could wake the panel)
	local want hz
	pgrep -x i3lock >/dev/null && return 0
	xset q 2>/dev/null | grep -q "Monitor is Off" && return 0
	ac_online && want=ac || want=bat
	hz=$(target_hz "$want")
	set_refresh "$hz"
	[[ -x $HOME/.config/scripts/nightlight.sh ]] && "$HOME/.config/scripts/nightlight.sh" reapply
}
display_apply() { # performance mode, refresh rate and CPU profile for ac|bat (defaults: AC balanced + 90 Hz, battery quiet + 60 Hz)
	local want=$1 hz m prof
	[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
	m=$(mode_of "$want")
	hz=$(target_hz "$want")
	case $m in quiet) prof=power-saver ;; performance) prof=performance ;; *) prof=balanced ;; esac
	[[ -n ${ROG_DRY:-} ]] && { echo "display_apply $want mode=$m profile=$prof hz=$hz"; return; }
	set_refresh "$hz"
	command -v powerprofilesctl >/dev/null && powerprofilesctl set "$prof"
	style_apply "$want"
}
autoquiet_check() { # at low battery switch to Quiet until plugged in (or the charge is 5 points above the threshold); event driven
	local cap pct on
	[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
	pct=${AUTOQUIET_PCT:-20}; on=${AUTOQUIET:-1}
	if ac_online || [[ $on != 1 ]]; then [[ -e $AQ ]] && { rm -f "$AQ"; ac_online && display_apply ac || display_apply bat; }; return 0; fi
	cap=$(cat "$PS"/BAT*/capacity 2>/dev/null | head -n1); [[ $cap =~ ^[0-9]+$ ]] || return 0
	if [[ ! -e $AQ ]] && ((cap <= pct)) && [[ $(mode_of bat) != quiet ]]; then : >"$AQ"; display_apply bat
	elif [[ -e $AQ ]] && ((cap > pct + 5)); then rm -f "$AQ"; display_apply bat; fi
}
last=
apply() {
	local want=$1
	[[ $want == auto ]] && { ac_online && want=ac || want=bat; }
	[[ $want == "$last" ]] && return
	last=$want
	display_apply "$want"
	timers "$want"
	[[ -x $HOME/.config/scripts/nightlight.sh ]] && "$HOME/.config/scripts/nightlight.sh" reapply
}
if [[ ${1:-} == once ]]; then apply "${2:-auto}"; exit 0; fi
if [[ ${1:-} == timers ]]; then timers auto; exit 0; fi
if [[ ${1:-} == autoquiet ]]; then autoquiet_check; exit 0; fi
if [[ ${1:-} == refresh ]]; then refresh_only; exit 0; fi
if [[ ${1:-} == rate ]]; then ac_online && w=ac || w=bat; m=$(mode_of "$w"); if [[ $m == quiet ]]; then echo 60; else . "$HOME/.config/rog/settings.env" 2>/dev/null; if [[ $w == ac ]]; then echo "${RATE_AC:-90}"; else echo "${RATE_BAT:-60}"; fi; fi; exit 0; fi
if [[ ${1:-} == display ]]; then ac_online && w=ac || w=bat; display_apply "$w"; [[ -x $HOME/.config/scripts/nightlight.sh ]] && "$HOME/.config/scripts/nightlight.sh" reapply; exit 0; fi
if [[ -r $PIDF ]] && grep -q power-watch "/proc/$(<"$PIDF")/cmdline" 2>/dev/null; then kill "$(<"$PIDF")" 2>/dev/null; fi
echo $$ >"$PIDF"
sleep 1
apply auto; autoquiet_check
coproc UPW { exec upower --monitor 2>/dev/null; }
trap 'kill "$UPW_PID" 2>/dev/null' EXIT; trap 'exit 0' TERM INT
while read -r _ <&"${UPW[0]}"; do apply auto; autoquiet_check; done
E
	cat >"$W/power-mode.sh" <<'RPM'
#!/usr/bin/env bash
# rog-tune: performance mode for the power source I am on right now (saved, so it is also what plug/unplug restores)
#   power-mode.sh quiet | balanced | performance | cycle | status
#   Quiet       least battery: power-saver CPU profile (CPU capped near 4 GHz, quiet fans), 60 Hz, no blur or dimming
#   Balanced    everyday
#   Performance CPU and fans unrestricted (louder, hotter)
#   Defaults: Balanced on AC, Quiet on battery. Spotlight and Settings change the same thing.
ENV=$HOME/.config/rog/settings.env; mkdir -p "${ENV%/*}"; touch "$ENV"
ac_online() { local f; for f in /sys/class/power_supply/*/online; do [[ -r $f && $(<"${f%online}type") == Mains ]] && { [[ $(<"$f") == 1 ]]; return; }; done; return 0; }
if ac_online; then key=MODE_AC def=balanced; else key=MODE_BAT def=quiet; fi
cur=$(grep -m1 "^$key=" "$ENV" | cut -d'"' -f2); cur=${cur:-$def}
case ${1:-status} in
status) echo "$key=$cur"; exit 0 ;;
cycle) case $cur in quiet) new=balanced ;; balanced) new=performance ;; *) new=quiet ;; esac ;;
quiet | balanced | performance) new=$1 ;;
*) sed -n '2,8p' "$0"; exit 1 ;;
esac
rm -f "${XDG_RUNTIME_DIR:-/tmp}/autoquiet.on"      # you chose a mode on purpose: that beats the automatic low-battery Quiet
if grep -q "^$key=" "$ENV"; then sed -i "s|^$key=.*|$key=\"$new\"|" "$ENV"; else printf '%s="%s"\n' "$key" "$new" >>"$ENV"; fi
exec "$HOME/.config/scripts/power-watch.sh" display
RPM
	ADD+=("$SD/power-watch.sh|$W/power-watch.sh" "$SD/power-mode.sh|$W/power-mode.sh")
	if ! grep -q "$MARK: mode" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: mode — Super+Alt+M cycles Quiet / Balanced / Performance for the power source I am on (also in Spotlight and Settings)
bindsym $mod+Mod1+m exec --no-startup-id ~/.config/scripts/power-mode.sh cycle
E
	fi
fi
if has loginbg; then
	cat >"$W/login-bg.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: wallpaper hooks: keeps the login screen's wallpaper equal to the desktop wallpaper (the greeter runs as another user
# and can't read ~) and builds the lock-screen image
dst=/usr/share/backgrounds/rog/current
src=${1:-$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null)}
[[ -n $src && -r $src ]] || exit 0
[[ -x $HOME/.config/scripts/accent.sh ]] && ( "$HOME/.config/scripts/accent.sh" wallpaper >/dev/null 2>&1 & )     # accent colour "from the wallpaper"
# lock screen: i3lock only reads PNG, so make a blurred, darkened one (once per wallpaper)
lock=$HOME/.cache/lock-bg.png; stamp=$HOME/.cache/lock-bg.src
if [[ $(cat "$stamp" 2>/dev/null) != "$src" ]]; then
	nice -n 19 magick "$src" -resize 2560x1600^ -gravity center -extent 2560x1600 -blur 0x14 -fill '#14110f' -colorize 35% "$lock.tmp.png" 2>/dev/null \
		&& mv -f "$lock.tmp.png" "$lock" && echo "$src" >"$stamp"
fi
[[ -w ${dst%/*} ]] || exit 0
cmp -s "$src" "$dst" || cp -f "$src" "$dst"
E
	ADD+=("$SD/login-bg.sh|$W/login-bg.sh")
	for n in wallcycle:wallpaper-cycle.sh wallcycle-rev:wallpaper-cycle-reverse.sh; do
		f=$H/.config/wallpaper-config/${n#*:}
		[[ -e $f ]] || continue
		cp "$f" "$W/${n%%:*}"
		grep -q login-bg.sh "$W/${n%%:*}" || sed -i -E 's|^([[:space:]]*)echo "\$wp" >"\$CURRENT_WP_CACHE"$|&\n\1"$HOME/.config/scripts/login-bg.sh" "$wp" \&|' "$W/${n%%:*}"
		# the day/night hours come from Settings (defaults 7 and 19, as before)
		sed -i -E 's|^DAY_START=7$|DAY_START=${WALL_DAY_START:-7}|; s|^NIGHT_START=19$|NIGHT_START=${WALL_NIGHT_START:-19}|' "$W/${n%%:*}"
		grep -q 'rog/settings.env' "$W/${n%%:*}" || sed -i '/^DAY_START=/i [[ -r "$HOME/.config/rog/settings.env" ]] \&\& . "$HOME/.config/rog/settings.env"' "$W/${n%%:*}"
	done
	cat >"$W/wallpaper-timer.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: (re)create the timer that changes the wallpaper every WALL_EVERY minutes (0 = never; set in Settings -> Wallpaper)
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
systemctl --user stop rog-wallpaper.timer rog-wallpaper.service 2>/dev/null
((${WALL_EVERY:-0} > 0)) || exit 0
env_args=(); for v in DISPLAY XAUTHORITY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS; do [[ -n ${!v:-} ]] && env_args+=(--setenv="$v=${!v}"); done
systemd-run --user --collect --unit=rog-wallpaper --on-active="${WALL_EVERY}m" --on-unit-active="${WALL_EVERY}m" --timer-property=AccuracySec=10s \
	"${env_args[@]}" -- "$HOME/.config/wallpaper-config/wallpaper-cycle.sh" >/dev/null 2>&1
E
	ADD+=("$SD/wallpaper-timer.sh|$W/wallpaper-timer.sh")
	if ! grep -q "$MARK: wallpaper-timer" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: wallpaper-timer — optional automatic wallpaper change (Settings -> Wallpaper)
exec_always --no-startup-id ~/.config/scripts/wallpaper-timer.sh
E
	fi
fi

if has lock; then
	cat >"$W/lock.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: lock with the current wallpaper (blurred and darkened by login-bg.sh; i3lock only reads PNG).
# With i3lock-color installed it looks like the macOS lock screen: date and large thin clock on top, round ring with my name at the bottom;
# with plain i3lock it falls back to the simple lock, and so does it if this i3lock-color build rejects an option.
# the bar must not show over the lock screen: hide it while locked (only if it was visible) and bring it back on any exit
hid=0
if xdotool search --onlyvisible --class polybar >/dev/null 2>&1; then polybar-msg cmd hide >/dev/null 2>&1 && hid=1; fi
trap '((hid)) && polybar-msg cmd show >/dev/null 2>&1' EXIT
img=$HOME/.cache/lock-bg.png
base=(--nofork --ignore-empty-password --show-failed-attempts -c 14110f)
[[ -f $img ]] && base+=(-i "$img")
if i3lock --version 2>&1 | grep -q 'Raymond Li'; then
	acc=$(grep -oP '^ACCENT_HEX="#\K[0-9a-fA-F]{6}' "$HOME/.config/rog/settings.env" 2>/dev/null); acc=${acc:-c47f1c}
	# macOS-style: date and big thin time centred near the top, round "avatar" ring with the name at the bottom centre
	who=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1); who=${who:-$USER}; who=${who^}
	rich=(--clock --force-clock --indicator --radius=54 --ring-width=3
		--time-str="%H:%M" --date-str="%A %-d %B" --time-font="Noto Sans Light" --date-font="Noto Sans Medium"
		--time-size=150 --date-size=34 --time-pos="w/2:h*0.27" --date-pos="w/2:h*0.14"
		--time-color=ffffffee --date-color=ffffffd9 --time-align=0 --date-align=0
		--ind-pos="w/2:h*0.80"
		--greeter-text="$who" --greeter-font="Noto Sans Medium" --greeter-size=22 --greeter-color=ffffffee --greeter-pos="w/2:h*0.80+100" --greeter-align=0
		--inside-color=ffffff26 --ring-color=ffffff40 --line-color=00000000 --separator-color=00000000
		--keyhl-color=ffffffee --bshl-color=ffffff77
		--insidever-color=ffffff40 --ringver-color=ffffffcc
		--insidewrong-color=e8a07a40 --ringwrong-color=e8a07aff
		--verif-text="" --noinput-text="" --lock-text="" --lockfailed-text="" --wrong-text="Incorrect password" --wrong-font="Noto Sans Medium" --wrong-size=20 --wrong-color=ffffffee --wrong-pos="w/2:h*0.80+140"
		--pass-media-keys --pass-volume-keys)
	t0=$(date +%s%N)
	i3lock "${base[@]}" "${rich[@]}"; rc=$?
	((rc == 0 || ($(date +%s%N) - t0) > 2000000000)) && exit "$rc"
fi
i3lock "${base[@]}"
E
fi
if has idle; then
	if [[ -n ${ROG_BK:-} ]] || command -v xss-lock >/dev/null; then
		sed -i -E 's|^(exec --no-startup-id xautolock .*)$|# rog-tune: \1|' "$W/i3"
		append_once "$W/i3" "exec --no-startup-id xss-lock --transfer-sleep-lock -- $H/.config/i3lock/lock.sh  # rog-tune: idle" idle
	else
		echo "!! idle: xss-lock is not installed (sudo pacman -S xss-lock xorg-xset), keeping xautolock for now" >&2
	fi
fi
if has ocr; then
	if ! grep -q "$MARK: ocr" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: ocr — select an area, its text goes to the clipboard
bindsym $mod+Print exec --no-startup-id ~/.config/scripts/ocr.sh
E
	fi
	cat >"$W/ocr.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: select an area on screen, put the text in it on the clipboard (needs tesseract + tesseract-data-eng)
command -v tesseract >/dev/null || exit 1
f=$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/ocr.XXXXXX.png"); trap 'rm -f "$f"' EXIT
scrot -o -s "$f" 2>/dev/null && [[ -s $f ]] || exit 0
tesseract "$f" - -l eng --psm 6 2>/dev/null | sed -e 's/[[:space:]]*$//' | xclip -selection clipboard
E
	ADD+=("$SD/ocr.sh|$W/ocr.sh")
fi
if has night; then
	if ! grep -q "$MARK: night" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: night — warm tint: Super+Shift+N toggles, Super+Alt+N back to the schedule (19:00-07:00)
bindsym $mod+Shift+n exec --no-startup-id ~/.config/scripts/nightlight.sh toggle
bindsym $mod+Mod1+n exec --no-startup-id ~/.config/scripts/nightlight.sh auto
exec_always --no-startup-id ~/.config/scripts/nightlight.sh daemon
E
	fi
	cat >"$W/nightlight.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: night tint through the display's gamma ramp (no extra packages, no popups).
#   nightlight.sh toggle | on | off | auto | status | reapply | daemon
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/nightlight; mkdir -p "$STATE"
MODE=$STATE/mode            # auto | on | off
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"   # Settings app: NIGHT_GAMMA (tint), NIGHT_START/END
TINT=${NIGHTLIGHT_TINT:-${NIGHT_GAMMA:-1.0:0.81:0.65}}    # about 4000 K by default
START=${NIGHT_START:-19} END=${NIGHT_END:-7}              # default: same split as my day/night wallpapers
out=$(xrandr --query | awk '/ connected/{print $1; exit}'); out=${out:-eDP-1}
mode() { cat "$MODE" 2>/dev/null || echo auto; }
want() {
	case $(mode) in on) echo on ;; off) echo off ;;
	*) local h=$((10#$(date +%H))); ((h >= START || h < END)) && echo on || echo off ;; esac
}
apply() { if [[ $(want) == on ]]; then xrandr --output "$out" --gamma "$TINT"; else xrandr --output "$out" --gamma 1:1:1; fi; }
case ${1:-status} in
toggle) if [[ $(want) == on ]]; then echo off >"$MODE"; else echo on >"$MODE"; fi; apply ;;
on | off | auto) echo "$1" >"$MODE"; apply ;;
reapply) apply ;;
status) echo "mode=$(mode) tint=$(want)" ;;
daemon)
	PIDF=${XDG_RUNTIME_DIR:-/tmp}/nightlight.pid
	if [[ -r $PIDF ]] && grep -q nightlight "/proc/$(<"$PIDF")/cmdline" 2>/dev/null; then kill "$(<"$PIDF")" 2>/dev/null; fi
	echo $$ >"$PIDF"
	f=$(mktemp -u); mkfifo "$f"; exec 3<>"$f"; rm -f "$f"
	while :; do apply; read -r -t 300 -u 3 _ || true; done ;;
esac
E
	ADD+=("$SD/nightlight.sh|$W/nightlight.sh")
fi
if has sysmon; then
	ini_set "$W/pb" module/cpu click-left "~/.config/scripts/sysmon.sh"
	ini_set "$W/pb" module/memory click-left "~/.config/scripts/sysmon.sh"
	if ! grep -q "$MARK: sysmon" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: sysmon — GUI task monitor (also: click CPU or RAM in the bar)
bindsym $mod+Shift+Escape exec --no-startup-id ~/.config/scripts/sysmon.sh
E
	fi
	cat >"$W/sysmon.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: open a GUI task monitor: per-process CPU/RAM/disk/GPU, per-app grouping
for c in missioncenter resources gnome-system-monitor; do command -v "$c" >/dev/null && exec "$c"; done
exec kitty --class sysmon -e btop
E
	ADD+=("$SD/sysmon.sh|$W/sysmon.sh")
fi
if has psd; then
	printf '%s\n' '# rog-tune: browser profiles in RAM, synced back to disk' 'BROWSERS="google-chrome firefox"' 'USE_OVERLAYFS="no"' 'BACKUP_LIMIT=2' >"$W/psd.conf"
	ADD+=("$H/.config/psd/psd.conf|$W/psd.conf")
fi

if has quiet; then
	sed -i -E '/dunstctl/d' "$W/i3"                         # notification binds from the earlier round
fi
if has keys; then
	if ! grep -q "$MARK: keys" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: keys — searchable list of every keybind
bindsym $mod+F1 exec --no-startup-id ~/.config/scripts/keys.sh
bindsym $mod+slash exec --no-startup-id ~/.config/scripts/keys.sh
E
	fi
	cat >"$W/keys.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: show every i3 keybind in a searchable rofi list (type to filter, Esc to close)
cfg=${1:-$HOME/.config/i3/config}
list=$(python3 - "$cfg" <<'PY'
import re, sys
raw = open(sys.argv[1]).read().replace("\\\n", " ")
vars_ = dict(re.findall(r'^\s*set\s+(\$\w+)\s+(.+?)\s*$', raw, re.M))
def pretty(k):
    for a, b in (("$mod", "Super"), ("Mod4", "Super"), ("Mod1", "Alt"), ("Control", "Ctrl")):
        k = k.replace(a, b)
    k = re.sub(r'\$\w+', lambda m: vars_.get(m.group(0), m.group(0)).strip('"'), k)
    for a, b in (("semicolon", ";"), ("slash", "/"), ("Return", "Enter"), ("Escape", "Esc"), ("BackSpace", "Backspace"),
                 ("XF86AudioRaiseVolume", "Volume Up"), ("XF86AudioLowerVolume", "Volume Down"), ("XF86AudioMute", "Mute key"),
                 ("XF86AudioMicMute", "Mic-mute key"), ("XF86MonBrightnessUp", "Brightness Up"), ("XF86MonBrightnessDown", "Brightness Down"),
                 ("XF86KbdBrightnessUp", "Kbd-light Up"), ("XF86KbdBrightnessDown", "Kbd-light Down"), ("XF86TouchpadToggle", "Touchpad key")):
        k = k.replace(a, b)
    return k.replace("+", " + ")
def describe(c):
    c = re.sub(r'^exec(_always)?\s+(--no-startup-id\s+)?', '', c)
    c = re.sub(r'^(sh|bash)( -l?c)?\s+', '', c).strip("\"' ")
    c = c.replace("$HOME/", "~/").replace("~/.config/", "").replace("--no-startup-id ", "")
    c = re.sub(r'\$\w+', lambda m: vars_.get(m.group(0), m.group(0)).strip('"'), c)
    return re.sub(r'\s+', ' ', c)[:90]
out, mode = [], ""
for line in raw.splitlines():
    t = line.strip()
    m = re.match(r'mode\s+"([^"]+)"\s*\{', t)
    if m: mode = "[" + m.group(1) + "] "; continue
    if t == "}": mode = ""; continue
    m = re.match(r'bindsym\s+(?:--\S+\s+)*(\S+)\s+(.+)$', t)
    if m and not t.startswith("#"):
        out.append((mode + pretty(m.group(1)), describe(m.group(2))))
w = max(len(k) for k, _ in out) + 2
print("\n".join(f"{k:<{w}}{d}" for k, d in out))
PY
)
printf '%s\n' "$list" | rofi -dmenu -i -no-custom -p "keys" -theme ~/.config/rofi/catppuccin-mocha.rasi \
	-theme-str 'window { width: 1500px; } listview { lines: 13; } * { font: "JetBrainsMono Nerd Font 20"; }'
E
	ADD+=("$SD/keys.sh|$W/keys.sh")
fi
if has focus; then
	sed -i -E 's/^focus_follows_mouse no$/focus_follows_mouse yes/; s/^# rog-tune: focus — .*/# rog-tune: focus — focus follows the mouse; vim-style workspace hops/' "$W/i3"
	ini_set "$W/pb" bar/toph modules-right "pulseaudio brightness battery memory cpu network mic"
	ini_set "$W/pb" bar/toph modules-center "date"
	ini_set "$W/pb" module/date date "%a %d %b  %H:%M"
	ini_set "$W/pb" module/date label "%date%"
	python3 - "$W/i3" <<'E'
import re, sys
p = sys.argv[1]; t = open(p).read()
for old, new in (("bindsym j resize shrink width", "bindsym h resize shrink width"),
                 ("bindsym k resize grow height", "bindsym j resize grow height"),
                 ("bindsym l resize shrink height", "bindsym k resize shrink height"),
                 ("bindsym semicolon resize grow width", "bindsym l resize grow width")):
    t = t.replace(old, new)
open(p, "w").write(t)
E
	if ! grep -q "$MARK: focus" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: focus — focus follows the mouse; vim-style workspace hops
focus_follows_mouse yes
bindsym $mod+Ctrl+h workspace prev
bindsym $mod+Ctrl+l workspace next
bindsym $mod+Ctrl+Shift+h move container to workspace prev; workspace prev
bindsym $mod+Ctrl+Shift+l move container to workspace next; workspace next
E
	fi
fi

if has rotate; then
	if ! grep -q "$MARK: rotate" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: rotate — Super+Shift+O freezes/unfreezes auto-rotation
bindsym $mod+Shift+o exec --no-startup-id ~/.config/scripts/autorotate.sh lock
E
	fi
	cat >"$W/autorotate.sh" <<'RROT'
#!/usr/bin/env bash
# rog-tune: follow the accelerometer. Panel + touchscreen + pen rotate together.
#   autorotate.sh            run (event-driven, one instance)
#   autorotate.sh lock       toggle "stay put" (Super+Shift+O)
LOCK=${XDG_STATE_HOME:-$HOME/.local/state}/autorotate.lock; mkdir -p "${LOCK%/*}"
if [[ ${1:-} == lock ]]; then
	if [[ -e $LOCK ]]; then rm -f "$LOCK"; else : >"$LOCK"; fi
	exit 0
fi
PIDF=${XDG_RUNTIME_DIR:-/tmp}/autorotate.pid
if [[ -r $PIDF ]] && grep -q autorotate "/proc/$(<"$PIDF")/cmdline" 2>/dev/null; then
	pkill -P "$(<"$PIDF")" 2>/dev/null; kill "$(<"$PIDF")" 2>/dev/null
fi
echo $$ >"$PIDF"
SCREEN=$(xrandr --query | awk '/ connected/{print $1; exit}'); SCREEN=${SCREEN:-eDP-1}
CURRENT=
apply() {
	[[ -e $LOCK || $1 == "$CURRENT" ]] && return
	local r m
	case $1 in
	normal) r=normal m="1 0 0 0 1 0 0 0 1" ;;
	left-up) r=left m="0 -1 1 1 0 0 0 0 1" ;;
	right-up) r=right m="0 1 0 -1 0 1 0 0 1" ;;
	bottom-up) r=inverted m="-1 0 1 0 -1 1 0 0 1" ;;
	*) return ;;
	esac
	xrandr --output "$SCREEN" --rotate "$r" || { logger -t autorotate "xrandr refused $r" 2>/dev/null; return; }
	CURRENT=$1
	xinput list --name-only | grep -iE 'touchscreen|stylus|pen|^ELAN' | grep -viE 'touchpad|keyboard|mouse' |
		while read -r d; do xinput set-prop "$d" "Coordinate Transformation Matrix" $m; done
	~/.config/scripts/nightlight.sh reapply 2>/dev/null   # a rotation can reset the tint
}
# the first line is "Has accelerometer (orientation: X ...)", later ones are "orientation changed: X"
# monitor-sensor stays alive and silent when the sensor claim is refused (it only warns on stderr), and a claim made before the session is
# active is refused. So watch for that, and restart it whenever it fails or exits: rotation must not depend on one attempt at login.
pid=
trap 'exit 0' TERM INT
trap '[[ -n $pid ]] && kill "$pid" 2>/dev/null' EXIT
delay=2
while :; do
	exec 3< <(exec monitor-sensor --accel 2>&1)
	pid=$!
	while read -r -u3 line; do
		if [[ $line == *"Failed to claim"* ]]; then
			logger -t autorotate "sensor claim refused, retrying in ${delay}s" 2>/dev/null
			break
		fi
		if [[ $line =~ orientation(\ changed)?:\ ([a-z-]+) ]]; then delay=2; apply "${BASH_REMATCH[2]}"; fi
	done
	exec 3<&-
	kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
	CURRENT=
	sleep "$delay"
	((delay < 30)) && delay=$((delay * 2))
done
RROT
	ADD+=("$SD/autorotate.sh|$W/autorotate.sh")
fi
if has spotlight; then
	# the old rofi-script spotlight owned Super+D; comment out that whole block (i3 would reject a second binding)
	sed -i -E '/^bindsym \$mod\+d exec --no-startup-id rofi \\$/,/^  -theme .*\\$/ { s/\\$//; s/^/# rog-tune: /; }' "$W/i3"
	if ! grep -q "$MARK: spotlight" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: spotlight — Super+D, searches as I type (apps, windows, files, maths, clipboard, actions)
bindsym $mod+d exec --no-startup-id ~/.config/scripts/rog-ui.sh spotlight
for_window [class="^Spotlight$"] floating enable, border none
E
	fi
	if ! grep -q "rog-sync" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: spotlight — the manual backup runs in a floating terminal so I can see its progress
for_window [class="^rog-sync$"] floating enable, resize set 1100 640, move position center
E
	fi
	sed -i -E 's|^for_window \[class="\^RogSettings\$"\].*$|for_window [class="^RogSettings$"] fullscreen enable|' "$W/i3"   # Settings is a full-screen window now
	if ! grep -q "RogAlarm" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: alarm — a Spotlight timer or reminder rings in a centred box that stays until dismissed
for_window [class="^RogAlarm$"] floating enable, border pixel 3, move position center
E
	fi
	if ! grep -q "RogPower" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: power — Super+Escape opens the power menu (lock, log out, sleep, hibernate, restart, shut down)
for_window [class="^RogPower$"] floating enable, border none, move position center
E
	fi
	sed -i -E "s|^bindsym \\\$mod\+Escape exec .*powermenu\.sh.*$|bindsym \\\$mod+Escape exec --no-startup-id python3 ~/.config/scripts/power-menu.py|" "$W/i3"
	if ! grep -q "$MARK: settings" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: settings — Super+comma opens the settings window (also in Spotlight: type "settings")
bindsym $mod+comma exec --no-startup-id ~/.config/scripts/rog-ui.sh settings
for_window [class="^RogSettings$"] fullscreen enable
E
	fi
	cat >"$W/settings.py" <<'RSET'
#!/usr/bin/env python3
# rog-tune: Settings, in the style of GNOME Settings (GTK4 + libadwaita): a category sidebar, grouped rows, changes apply at once.
#   settings.py            the settings window (starts on demand, nothing stays in memory afterwards)
#   settings.py --backup   choose what to back up, then run the backup (also: Spotlight -> "Back up to hp-server…")
import json, math, os, re, shutil, subprocess, sys, tarfile, threading, time
from pathlib import Path
import gi
gi.require_version("Gtk", "4.0"); gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, Gdk, Gio, GLib

HOME = Path.home()
CONF = HOME / ".config/rog"; CONF.mkdir(parents=True, exist_ok=True)
ENV = CONF / "settings.env"
SD = HOME / ".config/scripts"
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state"))
DEFAULTS = {"NIGHT_K": "4000", "NIGHT_START": "19", "NIGHT_END": "7", "LOCK_AC": "10", "OFF_AC": "15", "LOCK_BAT": "2", "OFF_BAT": "3",
            "MODE_AC": "balanced", "MODE_BAT": "quiet", "AUTOCAFFEINE": "1", "SPOT_RECENTS": "1", "SPOT_OPACITY": "62",
            "RATE_AC": "90", "RATE_BAT": "60", "TP_TAP": "1", "TP_NATURAL": "0", "TP_DWT": "1", "PTR_SPEED": "0",
            "KEY_DELAY": "250", "KEY_RATE": "50", "MIC_MUTE_LOGIN": "0", "SHOT_SAVE": "1", "BACKUP_MIRROR": "0", "APPEARANCE": "light", "ACCENT_MODE": "amber", "ACCENT_HEX": "#c47f1c", "WS_ICONS": "0",
            "AUTOQUIET": "1", "AUTOQUIET_PCT": "20", "ALARM_SOUND": "1",
            "ADAPTIVE": "1", "ADAPTIVE_IDLE_S": "60", "IDLE_HZ": "60", "CINEMA": "1", "CINEMA_HZ": "71.928",
            "WALL_DAY_START": "7", "WALL_NIGHT_START": "19", "WALL_EVERY": "0", "FAN_CURVE": "default"}
FILM_RATES = [("71.928", "71.93 Hz (23.976 fps films, exact)"), ("72", "72 Hz (24 fps films)"), ("96", "96 Hz (24 fps, 4 to 1)"), ("120", "120 Hz (24 and 30 fps)"),
              ("75", "75 Hz (25 fps)"), ("100", "100 Hz (25 fps, 4 to 1)")]
# every rate the panel can do: the native 60 and 165 Hz modes, and any rate in between (the panel is variable-refresh 58-165 Hz and
# takes the same timings at any pixel clock, which is how power-watch.sh makes the rest)
RATES = [60, 70, 72, 75, 80, 85, 90, 96, 100, 110, 120, 125, 130, 140, 144, 150, 155, 160, 165]
BAR_MODULES = [("pulseaudio", "Volume"), ("brightness", "Brightness"), ("battery", "Battery"), ("memory", "Memory"),
               ("cpu", "CPU"), ("network", "Wi-Fi"), ("mic", "Microphone"), ("camera", "Camera in use (only shows while a camera is open)")]
CANDIDATES = ["notes", "Documents", "Desktop", "Pictures", "Downloads", "Development", "Music", "Videos", "Zotero", ".ssh", ".config"]

# ---------------------------------------------------------------- state
def load():
    d = dict(DEFAULTS); raw = {}
    try:
        for l in ENV.read_text().splitlines():
            if "=" in l and not l.startswith("#"):
                k, v = l.split("=", 1); raw[k.strip()] = v.strip().strip('"')
    except Exception:
        pass
    d.update({k: v for k, v in raw.items() if k in DEFAULTS or k == "NIGHT_GAMMA"})
    # older versions stored CPU profiles; carry them over once
    if "MODE_AC" not in raw and raw.get("AC_PROFILE") == "performance": d["MODE_AC"] = "performance"
    if "MODE_BAT" not in raw and raw.get("BAT_PROFILE") in ("balanced", "performance"): d["MODE_BAT"] = raw["BAT_PROFILE"]
    if "APPEARANCE" not in raw and raw.get("SETTINGS_DARK") == "1": d["APPEARANCE"] = "dark"
    return d

def gamma_for(k):
    t = k / 100.0
    r = 255 if t <= 66 else max(0, min(255, 329.698727446 * ((t - 60) ** -0.1332047592)))
    g = 99.4708025861 * math.log(t) - 161.1195681661 if t <= 66 else 288.1221695283 * ((t - 60) ** -0.0755148492)
    b = 255 if t >= 66 else (0 if t <= 19 else 138.5177312231 * math.log(t - 10) - 305.0447927307)
    c = lambda x: max(0.0, min(255.0, x)) / 255.0
    return f"{c(r):.2f}:{c(g):.2f}:{c(b):.2f}"

def save(d):
    d["NIGHT_GAMMA"] = gamma_for(int(d["NIGHT_K"]))        # derived, so the shell scripts need no maths
    for k in ("AC_PROFILE", "BAT_PROFILE"): d.pop(k, None)
    ENV.write_text("# written by settings.py; sourced by the scripts in ~/.config/scripts\n" + "".join(f'{k}="{v}"\n' for k, v in sorted(d.items())))

def setv(k, v):
    d = load(); d[k] = str(v); save(d)                       # re-read first: power-mode.sh may have changed the file meanwhile

def run(*cmd):
    try: return subprocess.run(list(cmd), capture_output=True, text=True, timeout=8).stdout.strip()
    except Exception: return ""

def bg(*cmd):
    subprocess.Popen(list(cmd), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL, start_new_session=True)

def read_list(path, default):
    try:
        r = [os.path.expanduser(l.strip()) for l in Path(path).read_text().splitlines() if l.strip() and not l.startswith("#")]
        return r if r else default
    except Exception:
        return default

# ---------------------------------------------------------------- row helpers
def switch_row(title, sub, active, cb):
    r = Adw.SwitchRow(title=title, subtitle=sub or ""); r.set_active(active)
    r.connect("notify::active", lambda w, p: cb(w.get_active())); return r

def combo_row(title, sub, options, current, cb):
    r = Adw.ComboRow(title=title, subtitle=sub or ""); keys = [k for k, _ in options]
    r.set_model(Gtk.StringList.new([l for _, l in options]))
    if current in keys: r.set_selected(keys.index(current))
    r.connect("notify::selected", lambda w, p: cb(keys[w.get_selected()])); return r

def spin_row(title, sub, lo, hi, val, cb, step=1):
    r = Adw.SpinRow.new_with_range(lo, hi, step); r.set_title(title); r.set_subtitle(sub or ""); r.set_value(val)
    r.connect("notify::value", lambda w, p: cb(int(w.get_value()))); return r

def scale_row(title, sub, lo, hi, step, val, fmt, cb):
    r = Adw.ActionRow(title=title, subtitle=sub or "")
    sc = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, lo, hi, step); sc.set_value(val); sc.set_size_request(380, -1)
    sc.set_draw_value(True); sc.set_value_pos(Gtk.PositionType.RIGHT); sc.set_valign(Gtk.Align.CENTER)
    if fmt: sc.set_format_value_func(lambda s, v: fmt(v))
    pending = [0]
    def changed(w):                                           # apply once the slider rests, not on every pixel
        if pending[0]: GLib.source_remove(pending[0])
        pending[0] = GLib.timeout_add(350, lambda: (cb(w.get_value()), pending.__setitem__(0, 0), False)[2])
    sc.connect("value-changed", changed); r.add_suffix(sc); return r

def button_row(title, sub, label, cb, suggested=False):
    r = Adw.ActionRow(title=title, subtitle=sub or ""); b = Gtk.Button(label=label); b.set_valign(Gtk.Align.CENTER)
    if suggested: b.add_css_class("suggested-action")
    b.connect("clicked", lambda _: cb()); r.add_suffix(b); r.set_activatable_widget(b); return r

def group(title, rows, desc=None):
    g = Adw.PreferencesGroup(title=title or "")
    if desc: g.set_description(desc)
    for r in rows: g.add(r)
    return g

# ---------------------------------------------------------------- folder checklist (backup, deep search)
class FolderDialog(Adw.Window):
    def __init__(self, parent, title, selected, buttons, callback):
        super().__init__(title=title, modal=True, default_width=520, default_height=560)
        if parent: self.set_transient_for(parent)
        self.callback = callback; self.rows = {}
        tv = Adw.ToolbarView(); self.set_content(tv)
        hb = Adw.HeaderBar(); hb.set_show_end_title_buttons(False); hb.set_show_start_title_buttons(False); tv.add_top_bar(hb)
        c = Gtk.Button(label="Cancel"); c.connect("clicked", lambda _: self.finish(None)); hb.pack_start(c)
        for key, label, suggested in reversed(buttons):
            b = Gtk.Button(label=label)
            if suggested: b.add_css_class("suggested-action")
            b.connect("clicked", lambda _, k=key: self.finish(k)); hb.pack_end(b)
        page = Adw.PreferencesPage(); tv.set_content(page)
        self.grp = Adw.PreferencesGroup(title="Folders"); page.add(self.grp)
        names = [str(HOME / c) for c in CANDIDATES if os.path.isdir(HOME / c)]
        for p in selected:
            if p not in names: names.append(p)
        for p in names: self.add_folder(p, p in selected)
        addg = Adw.PreferencesGroup(); page.add(addg)
        addg.add(button_row("Add another folder", None, "Choose…", self.pick))
        k = Gtk.EventControllerKey(); k.connect("key-pressed", lambda c_, kv, kc, st: self.finish(None) if kv == Gdk.KEY_Escape else False); self.add_controller(k)

    def add_folder(self, p, on):
        row = Adw.ActionRow(title=p.replace(str(HOME), "~")); chk = Gtk.CheckButton(); chk.set_active(on); chk.set_valign(Gtk.Align.CENTER)
        row.add_prefix(chk); row.set_activatable_widget(chk); self.grp.add(row); self.rows[p] = chk

    def pick(self):
        fd = Gtk.FileDialog(title="Choose a folder"); fd.set_initial_folder(Gio.File.new_for_path(str(HOME)))
        def done(d, res):
            try:
                f = d.select_folder_finish(res)
                if f and f.get_path() not in self.rows: self.add_folder(f.get_path(), True)
            except GLib.Error: pass
        fd.select_folder(self, None, done)

    def finish(self, key):
        chosen = [p for p, c in self.rows.items() if c.get_active()]
        self.close(); self.callback(key, chosen)

def backup_flow(parent, on_done=None):
    lst = HOME / ".config/spotlight/sync.list"
    sel = read_list(lst, [str(HOME / "notes"), str(HOME / "Documents")])
    def cb(key, chosen):
        if key in ("save", "go"):
            lst.parent.mkdir(parents=True, exist_ok=True)
            lst.write_text("# folders copied by sync-server.sh (edit here, or use Settings)\n" + "\n".join(chosen) + "\n")
        if key == "go" and chosen: bg("kitty", "--class", "rog-sync", str(SD / "sync-server.sh"))
        if on_done: on_done()
    FolderDialog(parent, "Back up to hp-server (external drive)", sel, [("save", "Save only", False), ("go", "Back up now", True)], cb).present()

def deep_roots_dialog(parent):
    f = HOME / ".config/spotlight/roots"
    sel = read_list(f, [str(HOME / "notes"), str(HOME / "Documents")])
    def cb(key, chosen):
        if key == "save":
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_text("# folders searched by Spotlight's deep search\n" + "\n".join(chosen) + "\n")
    FolderDialog(parent, "Deep search folders", sel, [("save", "Save", True)], cb).present()

# ---------------------------------------------------------------- the pages
def i3_edit(pat, repl):
    f = HOME / ".config/i3/config"; t = f.read_text(); t2 = re.sub(pat, repl, t, flags=re.M)
    if t2 != t: f.write_text(t2)
    bg("i3-msg", "reload")

def picom_edit(pattern, repl):
    f = HOME / ".config/picom/picom-ac.conf"
    t = f.read_text(); t2 = re.sub(pattern, repl, t, flags=re.M)
    if t2 != t: f.write_text(t2)
    pid = run("pgrep", "-xo", "-u", str(os.getuid()), "picom")
    if pid: os.kill(int(pid), 10)                              # SIGUSR1: reload

def page_display(cfg):
    pc = HOME / ".config/picom/picom-ac.conf"; txt = pc.read_text() if pc.exists() else ""
    try: mode = (STATE / "nightlight/mode").read_text().strip() or "auto"
    except Exception: mode = "auto"
    def night_k(k): setv("NIGHT_K", int(k)); bg(str(SD / "nightlight.sh"), "reapply")
    def night_h(key, v): setv(key, v); bg(str(SD / "nightlight.sh"), "reapply")
    def disp(k, v): setv(k, v); bg(str(SD / "power-watch.sh"), "display")
    hz = [(str(r), f"{r} Hz" + (" (native max)" if r == 165 else " (native)" if r == 60 else "")) for r in RATES]
    return [
        group("Night tint", [
            combo_row("Mode", "Automatic follows the schedule below", [("auto", "Automatic"), ("on", "Always on"), ("off", "Off")],
                      mode if mode in ("auto", "on", "off") else "auto", lambda m: bg(str(SD / "nightlight.sh"), m)),
            scale_row("Warmth", "Lower is warmer", 2700, 6000, 100, int(cfg["NIGHT_K"]), lambda v: f"{int(v)} K", night_k),
            spin_row("Automatic: from (hour)", "24 hour clock; the tint is on from this hour…", 0, 23, int(cfg["NIGHT_START"]), lambda v: night_h("NIGHT_START", v)),
            spin_row("Automatic: until (hour)", "…until this hour.", 0, 23, int(cfg["NIGHT_END"]), lambda v: night_h("NIGHT_END", v))]),
        group("Refresh rate", [
            combo_row("On AC power", None, hz, cfg["RATE_AC"], lambda v: disp("RATE_AC", v)),
            combo_row("On battery", "Applied the moment you unplug", hz, cfg["RATE_BAT"], lambda v: disp("RATE_BAT", v))],
            desc="The panel is variable-refresh (58 to 165 Hz), so any rate from 60 to 165 Hz works. Higher is smoother, lower saves power. Quiet mode always uses 60 Hz, whatever is chosen here."),
        group("Adaptive refresh", [
            switch_row("Lower the rate when idle", "After a while without keys or touch the panel drops to the idle rate; the first key or touch brings your rate back "
                       "(the screen blinks briefly as it switches). Only from 110 Hz up. Not in Quiet mode, while audio plays, or in a call.",
                       cfg["ADAPTIVE"] == "1", lambda on: (setv("ADAPTIVE", "1" if on else "0"), bg(str(SD / "power-watch.sh"), "refresh"))),
            spin_row("Idle after (seconds)", "Longer means fewer blinks while you read; shorter saves more", 15, 600, int(cfg["ADAPTIVE_IDLE_S"]), lambda v: setv("ADAPTIVE_IDLE_S", v), 5),
            combo_row("Idle rate", None, [(str(r), f"{r} Hz") for r in RATES if r <= 100], cfg["IDLE_HZ"], lambda v: setv("IDLE_HZ", v))],
              desc="Measured on this laptop, on battery: 60 Hz and 90 Hz draw the same; 120 Hz draws about 0.4 W more and 165 Hz about 0.5 W more. So this only acts when your rate is 110 Hz or higher. At 90 Hz or below it does nothing and never blinks."),
        group("Cinema mode", [
            switch_row("Match the panel to films", "A fullscreen video player (mpv, VLC, Celluloid and similar; not browsers) switches the panel to the film rate below, "
                       "so frames are shown for an equal time and motion is smooth. It switches back when you leave fullscreen.",
                       cfg["CINEMA"] == "1", lambda on: setv("CINEMA", "1" if on else "0")),
            combo_row("Film rate", "Pick the one that divides your films' frame rate evenly", FILM_RATES, cfg["CINEMA_HZ"], lambda v: setv("CINEMA_HZ", v))],
              desc="Exact matching to each video's own frame rate needs mpv's control socket and is not built yet."),
        group("Effects", [
            switch_row("Blur on AC power", "Frosted glass behind terminals; off on battery and in Quiet mode", "blur-background = true" in txt,
                       lambda on: picom_edit(r"^blur-background = (true|false);", f"blur-background = {'true' if on else 'false'};")),
            switch_row("Dim inactive windows", "The window you are not typing in recedes slightly (AC power only).", re.search(r"^inactive-dim\s*=\s*0\.[1-9]", txt, re.M) is not None,
                       lambda on: picom_edit(r"^inactive-dim = [0-9.]+;", f"inactive-dim = {'0.10' if on else '0.0'};"))])]

def page_power(cfg):
    modes = [("quiet", "Quiet"), ("balanced", "Balanced"), ("performance", "Performance")]
    def disp(k, v): setv(k, v); bg(str(SD / "power-watch.sh"), "display")
    def timers(k, v): setv(k, v); bg(str(SD / "power-watch.sh"), "timers")
    def autocaf(on): setv("AUTOCAFFEINE", "1" if on else "0"); bg(str(SD / "autocaffeine.sh"))
    res = [
        group("Performance mode", [
            combo_row("On AC power", "Used while plugged in", modes, cfg["MODE_AC"], lambda v: disp("MODE_AC", v)),
            combo_row("On battery", "Used whenever you are unplugged", modes, cfg["MODE_BAT"], lambda v: disp("MODE_BAT", v))],
            desc="Quiet: least power and fan noise (CPU capped near 4 GHz, 60 Hz, no blur), the longest battery life. Balanced: everyday. "
                 "Performance: CPU and fans unrestricted, louder and hotter. Super+Alt+M cycles the mode for the power source you are on."),
        group("Low battery", [
            switch_row("Switch to Quiet automatically", "When the battery gets low, until you plug in", cfg["AUTOQUIET"] == "1", lambda on: setv("AUTOQUIET", "1" if on else "0")),
            spin_row("Switch at (percent)", "Quiet mode starts at or below this charge and ends once it is 5 points higher or you plug in", 5, 50, int(cfg["AUTOQUIET_PCT"]),
                     lambda v: (setv("AUTOQUIET_PCT", v), bg(str(SD / "power-watch.sh"), "autoquiet")))],
              desc="Your usual mode on battery stays as chosen above; this only overrides it while the battery is low."),
        group("Keeping the screen on", [
            switch_row("Keep screen awake", "No auto-lock or screen-off until you turn it off (the lid still sleeps)", (STATE / "caffeine").exists(),
                       lambda on: bg(str(SD / "caffeine.sh"), "on" if on else "off")),
            switch_row("Automatic caffeine", "Stay awake while a window is fullscreen or an app uses the microphone", cfg["AUTOCAFFEINE"] == "1", autocaf)]),
        group("Lock and screen off", [
            spin_row("Lock after, on AC (minutes)", "Screen locks after this many idle minutes.", 1, 120, int(cfg["LOCK_AC"]), lambda v: timers("LOCK_AC", v)),
            spin_row("Screen off after, on AC (minutes)", "The display powers off after this many idle minutes.", 1, 120, int(cfg["OFF_AC"]), lambda v: timers("OFF_AC", v)),
            spin_row("Lock after, on battery (minutes)", "Shorter on battery saves power and keeps it safe.", 1, 120, int(cfg["LOCK_BAT"]), lambda v: timers("LOCK_BAT", v)),
            spin_row("Screen off after, on battery (minutes)", None, 1, 120, int(cfg["OFF_BAT"]), lambda v: timers("OFF_BAT", v))])]
    return res + fan_group(cfg)

def page_input(cfg):
    def inp(k, v): setv(k, v); bg(str(SD / "input-apply.sh"))
    return [
        group("Touchpad", [
            switch_row("Tap to click", "Tap the touchpad instead of pressing it.", cfg["TP_TAP"] == "1", lambda on: inp("TP_TAP", "1" if on else "0")),
            switch_row("Natural scrolling", "Content follows your fingers, like a phone.", cfg["TP_NATURAL"] == "1", lambda on: inp("TP_NATURAL", "1" if on else "0")),
            switch_row("Ignore touchpad while typing", "Stops the cursor jumping when your palm brushes the pad.", cfg["TP_DWT"] == "1", lambda on: inp("TP_DWT", "1" if on else "0"))]),
        group("Pointer", [
            scale_row("Pointer speed", "Touchpad and mice. Right is faster. Applies to devices connected right now.", -100, 100, 5, float(cfg["PTR_SPEED"]) * 100, lambda v: f"{int(v)}",
                      lambda v: inp("PTR_SPEED", f"{v / 100:.2f}"))]),
        group("Keyboard", [
            spin_row("Repeat delay (ms)", "How long you hold a key before it starts repeating.", 150, 800, int(cfg["KEY_DELAY"]), lambda v: inp("KEY_DELAY", v), 10),
            spin_row("Repeat rate (per second)", "How fast it repeats once it starts.", 10, 100, int(cfg["KEY_RATE"]), lambda v: inp("KEY_RATE", v), 5)])]

def page_windows(cfg):
    i3 = (HOME / ".config/i3/config").read_text()
    ffm = re.search(r"^focus_follows_mouse\s+(yes|no)", i3, re.M); bw = re.search(r"^default_border pixel (\d+)", i3, re.M)
    kt = (HOME / ".config/kitty/kitty.conf").read_text() if (HOME / ".config/kitty/kitty.conf").exists() else ""
    op = re.search(r"^background_opacity\s+([0-9.]+)", kt, re.M)
    def kitty_opacity(v):
        f = HOME / ".config/kitty/kitty.conf"; t = f.read_text()
        t2 = re.sub(r"^background_opacity\s+[0-9.]+", f"background_opacity {v / 100:.2f}", t, flags=re.M)
        if t2 != t: f.write_text(t2)
        bg("pkill", "-USR1", "-x", "kitty")                    # kitty reloads its config
    lock = STATE / "autorotate.lock"
    return [
        group("Windows", [
            switch_row("Focus follows mouse", "The window under the pointer gets keyboard focus without clicking.", not ffm or ffm.group(1) == "yes",
                       lambda on: i3_edit(r"^focus_follows_mouse\s+(yes|no)", f"focus_follows_mouse {'yes' if on else 'no'}")),
            spin_row("Border thickness (px)", "The coloured outline that shows which window has focus. 0 hides it.", 0, 8, int(bw.group(1)) if bw else 2,
                     lambda v: i3_edit(r"^default_border pixel \d+", f"default_border pixel {v}"))]),
        group("Terminal", [
            scale_row("Opacity", "100 % is solid black; lower lets the blurred wallpaper through. Open terminals update at once.", 40, 100, 2,
                      float(op.group(1)) * 100 if op else 78, lambda v: f"{int(v)} %", kitty_opacity)]),
        group("Screen", [
            switch_row("Freeze rotation", "Stop the screen rotating with the accelerometer (for example while lying down).", lock.exists(),
                       lambda on: bg(str(SD / "autorotate.sh"), "lock") if on != lock.exists() else None),
            switch_row("Tablet mode", "On-screen keyboard that appears when you touch a text field. Always off after login.",
                       run("pgrep", "-x", "-u", str(os.getuid()), "onboard") != "", lambda on: bg(str(SD / "tablet.sh"), "on" if on else "off"))])]

def page_bar(cfg):
    pb = HOME / ".config/polybar/config.ini"; txt = pb.read_text() if pb.exists() else ""
    m = re.search(r"^modules-right\s*=\s*(.*)$", txt, re.M); cur = m.group(1).split() if m else []
    def bar_item(key, on):
        f = pb; t = f.read_text(); mm = re.search(r"^modules-right\s*=\s*(.*)$", t, re.M)
        have = set(mm.group(1).split()) if mm else set()
        (have.add if on else have.discard)(key)
        order = [k for k, _ in BAR_MODULES]
        new = " ".join([k for k in order if k in have] + [k for k in have if k not in order])
        f.write_text(re.sub(r"^modules-right\s*=.*$", f"modules-right = {new}", t, flags=re.M)); bg("polybar-msg", "cmd", "restart")
    def font(weight=None, size=None):
        t = pb.read_text(); mm = re.search(r"^font-1\s*=\s*(.*)$", t, re.M); curf = mm.group(1) if mm else "JetBrains Mono:weight=light:size=12;4"
        w = weight or (re.search(r"weight=(\w+)", curf).group(1) if re.search(r"weight=(\w+)", curf) else "light")
        z = size or (re.search(r"size=(\d+)", curf).group(1) if re.search(r"size=(\d+)", curf) else "12")
        line = f"font-1 = JetBrains Mono:weight={w}:size={z};4"
        t = re.sub(r"^font-1\s*=.*$", line, t, flags=re.M) if mm else t.replace("font-0 =", line + "\nfont-0 =", 1)
        pb.write_text(t); bg("polybar-msg", "cmd", "restart")
    def marker(v):
        t = pb.read_text()
        if v == "line":
            t = re.sub(r"^label-active-background\s*=.*$", "label-active-background =", t, flags=re.M)
            t = re.sub(r"^label-active-foreground\s*=.*$", "label-active-foreground = ${colors.mauve}", t, flags=re.M)
            t = re.sub(r"^line-size\s*=.*$", "line-size = 3pt", t, flags=re.M)
        else:
            t = re.sub(r"^label-active-background\s*=.*$", "label-active-background = ${colors.mauve}", t, flags=re.M)
            t = re.sub(r"^label-active-foreground\s*=.*$", "label-active-foreground = ${colors.crust}", t, flags=re.M)
            t = re.sub(r"^line-size\s*=.*$", "line-size = 2pt", t, flags=re.M)
        pb.write_text(t); bg("polybar-msg", "cmd", "restart")
    f1 = re.search(r"^font-1\s*=\s*(.*)$", txt, re.M)
    wt = (re.search(r"weight=(\w+)", f1.group(1)) or [None, "light"])[1] if f1 else "light"
    sz = (re.search(r"size=(\d+)", f1.group(1)) or [None, "12"])[1] if f1 else "12"
    mk = "box" if re.search(r"^label-active-background\s*=\s*\S", txt, re.M) else "line"
    return [
        group("Shown in the bar", [switch_row(label, None, key in cur, lambda on, k=key: bar_item(k, on)) for key, label in BAR_MODULES]),
        group("Workspaces", [
            switch_row("Show app icons next to the numbers", "Off by default: it makes each workspace's box wider",
                       cfg["WS_ICONS"] == "1", lambda on: (setv("WS_ICONS", "1" if on else "0"), bg("sh", "-c", 'kill -USR1 "$(cat "${XDG_RUNTIME_DIR:-/tmp}/display-agent.pid")"'))),
            combo_row("Active workspace marker", "A small filled box, or just a thin line under the number.", [("box", "Box"), ("line", "Line")], mk, marker),
            combo_row("Number weight", "How heavy the workspace numbers look.", [("light", "Light"), ("regular", "Regular"), ("medium", "Medium")], wt, lambda v: font(weight=v)),
            spin_row("Number size", "Points.", 8, 18, int(sz), lambda v: font(size=v))])]

def page_spotlight(cfg, win):
    return [
        group("Appearance", [
            scale_row("Transparency", "How much of the screen shows through Spotlight. Left is more see-through, 100 % is solid. Applies the next time you open it.", 35, 100, 1,
                      float(cfg["SPOT_OPACITY"]), lambda v: f"{int(v)} % opaque", lambda v: setv("SPOT_OPACITY", int(v)))]),
        group("Behaviour", [
            switch_row("Recents when opened", "Show your last four apps and files before you type anything.", cfg["SPOT_RECENTS"] == "1", lambda on: setv("SPOT_RECENTS", "1" if on else "0")),
            button_row("Deep search folders", "Where “search inside documents” looks (notes, PDFs and text files).", "Choose…", lambda: deep_roots_dialog(win))]),
        group("Clipboard history", [Adw.ActionRow(title="Everything you copy is kept", subtitle="Text and images, up to 3000 entries. Open it with Super+Shift+V, or type “c ” in Spotlight to search it.")]),
        group("Shortcuts inside Spotlight", [Adw.ActionRow(title="Preview a file", subtitle="Select a result and press Ctrl+Y (images, PDFs, text, folders). Esc goes back."),
                                              Adw.ActionRow(title="Browse every app", subtitle="Alt+A, or “Show all” in the recents view."),
                                              Adw.ActionRow(title="Timers and reminders", subtitle="timer 25m  ·  remind in 10m call back  ·  remind 15:30 stand up  ·  timers (list or cancel)")])]

def page_general(cfg, win, relook):
    def look(k, v): setv(k, v); relook(); bg(str(SD / "accent.sh"))
    cb = Gtk.ColorDialogButton(dialog=Gtk.ColorDialog()); cb.set_valign(Gtk.Align.CENTER)
    rgba = Gdk.RGBA(); rgba.parse(cfg["ACCENT_HEX"]); cb.set_rgba(rgba)
    def picked(btn, _p):
        c = btn.get_rgba(); hx = "#%02x%02x%02x" % (round(c.red * 255), round(c.green * 255), round(c.blue * 255))
        setv("ACCENT_HEX", hx); setv("ACCENT_MODE", "custom"); relook(); bg(str(SD / "accent.sh"))
    cb.connect("notify::rgba", picked)
    crow = Adw.ActionRow(title="Custom accent colour", subtitle="Choosing a colour here switches the accent to Custom"); crow.add_suffix(cb)
    return [
        group("Appearance", [
            combo_row("Theme", "Spotlight, Settings and timer alerts. “Follow the night schedule” is dark between the night-tint hours (Display page).",
                      [("light", "Light"), ("dark", "Dark"), ("schedule", "Follow the night schedule")], cfg["APPEARANCE"], lambda v: look("APPEARANCE", v)),
            combo_row("Accent colour", "Used for selections, switches and highlights, in the bar's active workspace and on the focused window's border",
                      [("amber", "Amber (default)"), ("wallpaper", "From the wallpaper"), ("custom", "Custom")], cfg["ACCENT_MODE"], lambda v: look("ACCENT_MODE", v)), crow]),
        group("Startup", [switch_row("Start with the microphone muted", "Every login begins muted; unmute when you need it.", cfg["MIC_MUTE_LOGIN"] == "1", lambda on: setv("MIC_MUTE_LOGIN", "1" if on else "0"))]),
        group("Your settings", [button_row("Export settings", "Saves your settings, Spotlight aliases and folder lists to a file you can keep", "Export…", lambda: do_export(win)),
                                button_row("Import settings", "Loads a file made by Export (for example on a fresh install)", "Import…", lambda: do_import(win))]),
        group("Timers and reminders", [switch_row("Play a sound when one rings", "Set them in Spotlight: timer 25m, remind in 10m call back, remind 15:30 stand up", cfg["ALARM_SOUND"] == "1", lambda on: setv("ALARM_SOUND", "1" if on else "0"))]),
        group("Screenshots", [switch_row("Keep a file of screenshots", "Besides the clipboard, save each screenshot in ~/Pictures. Off means clipboard only.", cfg["SHOT_SAVE"] == "1", lambda on: setv("SHOT_SAVE", "1" if on else "0"))])]

def bat_dir():
    root = Path(os.environ.get("ROG_PS", "/sys/class/power_supply"))
    return next(iter(sorted(root.glob("BAT*"))), None)

def bat_num(d, name):
    try: return float((d / name).read_text().strip())
    except Exception: return None

def bat_text(d, name):
    try: return (d / name).read_text().strip()
    except Exception: return ""

def bat_facts():
    """(title, value, subtitle) rows describing the battery right now."""
    d = bat_dir()
    if d is None: return [("Battery", "not found", "")]
    cap = bat_num(d, "capacity"); st = bat_text(d, "status"); full = bat_num(d, "energy_full"); des = bat_num(d, "energy_full_design")
    now = bat_num(d, "energy_now"); pw = bat_num(d, "power_now"); v = bat_num(d, "voltage_now"); cyc = bat_num(d, "cycle_count")
    rows = [("Charge", f"{cap:.0f} %  ·  {st}" if cap is not None else "?", "")]
    if full and des: rows.append(("Battery health", f"{full / des * 100:.0f} %", f"Holds {full / 1e6:.1f} Wh today, {des / 1e6:.1f} Wh when new"))
    rows.append(("Charge cycles", f"{cyc:.0f}" if cyc else "not reported", "This battery does not report a cycle count" if not cyc else ""))
    if pw and pw > 0:
        rows.append(("Power draw", f"{pw / 1e6:.1f} W", "Right now, whole machine" if st == "Discharging" else "Going into the battery"))
        if st == "Discharging" and now: hrs = now / pw; rows.append(("Time left", f"{int(hrs)} h {int((hrs % 1) * 60):02d} min", "At the current draw"))
        elif st == "Charging" and full and now: hrs = (full - now) / pw; rows.append(("Time to full", f"{int(hrs)} h {int((hrs % 1) * 60):02d} min", "At the current charging power"))
    else:
        rows.append(("Power draw", "—", "Plugged in and full" if st in ("Full", "Not charging") else ""))
    if v: rows.append(("Voltage", f"{v / 1e6:.2f} V", ""))
    rows.append(("Battery", f"{bat_text(d, 'model_name')}  ·  {bat_text(d, 'technology')}", ""))
    return rows

def page_battery(cfg, win):
    g = Adw.PreferencesGroup(title="Battery status", description="Updates every few seconds while this page is open.")
    rows = []
    def build():
        for r in rows: g.remove(r)
        rows.clear()
        for title, value, sub in bat_facts():
            r = Adw.ActionRow(title=title, subtitle=sub); lab = Gtk.Label(label=value); lab.add_css_class("dim-label"); lab.set_valign(Gtk.Align.CENTER)
            r.add_suffix(lab); g.add(r); rows.append(r)
        return win.get_visible() if win else True
    build()
    GLib.timeout_add_seconds(3, lambda: build() and True)
    tips = Adw.PreferencesGroup(title="Notes")
    tips.add(Adw.ActionRow(title="Reading these numbers", subtitle="A new battery reports 100 % health; around 80 % it holds noticeably less charge than when new. "
                                                                  "Quiet mode (Power & Performance) gives the longest runtime."))
    return [g, tips]

# ---------------------------------------------------------------- Sound: output/input devices, volumes, per-app volume
def pj(*args):
    try: return json.loads(subprocess.run(["pactl", "-f", "json", *args], capture_output=True, text=True, timeout=5).stdout or "[]")
    except Exception: return []

def vol_pct(d):
    try: return int(round(float(next(iter(d["volume"].values()))["value_percent"].strip("%"))))
    except Exception: return 100

def page_sound(cfg, win):
    sinks = pj("list", "sinks"); srcs = [x for x in pj("list", "sources") if not x["name"].endswith(".monitor")]
    dsink = run("pactl", "get-default-sink"); dsrc = run("pactl", "get-default-source")
    cur_s = next((x for x in sinks if x["name"] == dsink), sinks[0] if sinks else None)
    cur_i = next((x for x in srcs if x["name"] == dsrc), srcs[0] if srcs else None)
    groups = []
    rows = []
    if sinks:
        rows.append(combo_row("Device", None, [(x["name"], x["description"]) for x in sinks], cur_s["name"], lambda v: bg("pactl", "set-default-sink", v)))
        rows.append(scale_row("Volume", None, 0, 150, 1, vol_pct(cur_s), lambda v: f"{int(v)} %", lambda v: bg("pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{int(v)}%")))
        rows.append(switch_row("Muted", None, bool(cur_s.get("mute")), lambda on: bg("pactl", "set-sink-mute", "@DEFAULT_SINK@", "1" if on else "0")))
    groups.append(group("Output", rows or [Adw.ActionRow(title="No output device found")]))
    rows = []
    if srcs:
        rows.append(combo_row("Device", None, [(x["name"], x["description"]) for x in srcs], cur_i["name"], lambda v: bg("pactl", "set-default-source", v)))
        rows.append(scale_row("Volume", None, 0, 150, 1, vol_pct(cur_i), lambda v: f"{int(v)} %", lambda v: bg("pactl", "set-source-volume", "@DEFAULT_SOURCE@", f"{int(v)}%")))
        rows.append(switch_row("Muted", "The bar's mic indicator shows this", bool(cur_i.get("mute")), lambda on: bg("pactl", "set-source-mute", "@DEFAULT_SOURCE@", "1" if on else "0")))
    groups.append(group("Input", rows or [Adw.ActionRow(title="No microphone found")]))
    apps = Adw.PreferencesGroup(title="Volume per app", description="Apps that are playing sound right now.")
    state = {"rows": [], "key": None}
    def rebuild():
        inputs = pj("list", "sink-inputs"); key = tuple((x["index"], vol_pct(x)) for x in inputs)
        if key == state["key"]: return win.get_visible() if win else True
        state["key"] = key
        for r in state["rows"]: apps.remove(r)
        state["rows"] = []
        if not inputs:
            r = Adw.ActionRow(title="Nothing is playing"); apps.add(r); state["rows"].append(r)
        for x in inputs:
            p = x.get("properties", {}); name = p.get("application.name") or p.get("media.name") or "Sound"
            r = scale_row(name, p.get("media.name") if p.get("media.name") != name else None, 0, 150, 1, vol_pct(x), lambda v: f"{int(v)} %",
                          lambda v, i=x["index"]: bg("pactl", "set-sink-input-volume", str(i), f"{int(v)}%"))
            apps.add(r); state["rows"].append(r)
        return win.get_visible() if win else True
    rebuild(); GLib.timeout_add_seconds(4, lambda: rebuild() and True)
    groups.append(apps)
    return groups

# ---------------------------------------------------------------- Startup apps (XDG autostart; i3's own `exec` lines are not touched)
SYS_AUTOSTART = Path("/etc/xdg/autostart"); USER_AUTOSTART = HOME / ".config/autostart"

def desktop_field(text, key):
    m = re.search(rf"^{key}=(.*)$", text, re.M); return m.group(1).strip() if m else ""

def startup_entries():
    names = {}
    for d in (SYS_AUTOSTART, USER_AUTOSTART):
        if d.is_dir():
            for f in d.glob("*.desktop"): names[f.name] = None
    out = []
    for n in sorted(names):
        user = USER_AUTOSTART / n; sysf = SYS_AUTOSTART / n
        txt = (user if user.exists() else sysf).read_text(errors="replace")
        base = (sysf if sysf.exists() else user).read_text(errors="replace")
        title = desktop_field(base, "Name") or desktop_field(txt, "Name") or n
        if title.endswith("(hidden by rog-tune)"): title = title.replace(" (hidden by rog-tune)", "")
        hidden = desktop_field(txt, "Hidden").lower() == "true" or desktop_field(txt, "NoDisplay").lower() == "true" and False
        if desktop_field(txt, "OnlyShowIn") and "i3" not in desktop_field(txt, "OnlyShowIn"): pass
        out.append((n, title, desktop_field(base, "Comment") or desktop_field(base, "Exec"), not hidden))
    return out

def set_startup(name, on):
    user = USER_AUTOSTART / name; sysf = SYS_AUTOSTART / name
    USER_AUTOSTART.mkdir(parents=True, exist_ok=True)
    if on:
        if user.exists():
            t = user.read_text()
            if sysf.exists() and re.search(r"^Hidden=true", t, re.M) and len(t.strip().splitlines()) <= 6: user.unlink()      # our stub: just remove it
            else: user.write_text(re.sub(r"^Hidden=true", "Hidden=false", t, flags=re.M))
    else:
        if user.exists():
            t = user.read_text()
            user.write_text(re.sub(r"^Hidden=\w+", "Hidden=true", t, flags=re.M) if re.search(r"^Hidden=", t, re.M) else t.rstrip("\n") + "\nHidden=true\n")
        else:
            user.write_text(f"# rog-settings: switched off from Settings\n[Desktop Entry]\nType=Application\nName={name}\nHidden=true\n")

def page_startup(cfg, win):
    rows = [switch_row(title, sub[:90], on, lambda on_, n=n: set_startup(n, on_)) for n, title, sub, on in startup_entries()]
    return [group("Programs that start when you log in", rows or [Adw.ActionRow(title="No startup entries")],
                  desc="Changes apply at your next login. Programs started from the i3 config itself (the bar, the compositor, the agents) are not listed here.")]

# ---------------------------------------------------------------- Wallpaper
def page_wallpaper(cfg, win):
    def every(v):
        setv("WALL_EVERY", v); bg(str(SD / "wallpaper-timer.sh"))
    return [
        group("Day and night", [
            spin_row("Day wallpapers start at (hour)", "Wallpapers from the day folder are used from this hour…", 0, 23, int(cfg["WALL_DAY_START"]), lambda v: setv("WALL_DAY_START", v)),
            spin_row("Night wallpapers start at (hour)", "…until this hour, then the night folder", 0, 23, int(cfg["WALL_NIGHT_START"]), lambda v: setv("WALL_NIGHT_START", v))],
              desc="Your wallpapers live in ~/Pictures/wallpapers/day and /night."),
        group("Changing", [
            spin_row("Change automatically every (minutes)", "0 means only when you press Super+Y", 0, 1440, int(cfg["WALL_EVERY"]), every, 5),
            button_row("Change it now", "Same as Super+Y", "Next wallpaper", lambda: bg(str(HOME / ".config/wallpaper-config/wallpaper-cycle.sh")))])]

# ---------------------------------------------------------------- Fans (asusctl)
FAN_CURVES = {
    "quiet": {"cpu": "45c:0%,55c:0%,60c:12%,65c:25%,70c:40%,75c:55%,80c:75%,90c:100%", "gpu": "50c:0%,60c:0%,65c:15%,70c:30%,75c:45%,80c:65%,85c:80%,90c:100%"},
    "cool": {"cpu": "40c:10%,50c:20%,55c:35%,60c:50%,65c:62%,70c:75%,80c:90%,90c:100%", "gpu": "40c:10%,50c:20%,55c:35%,60c:50%,65c:62%,70c:75%,80c:90%,90c:100%"}}

def apply_fans(kind):
    for prof in ("Quiet", "Balanced", "Performance"):
        if kind == "default":
            subprocess.run(["asusctl", "fan-curve", "--mod-profile", prof, "--enable-fan-curves", "false"], capture_output=True, timeout=10); continue
        for fan in ("cpu", "gpu"):
            subprocess.run(["asusctl", "fan-curve", "--mod-profile", prof, "--fan", fan, "--data", FAN_CURVES[kind][fan]], capture_output=True, timeout=10)
        subprocess.run(["asusctl", "fan-curve", "--mod-profile", prof, "--enable-fan-curves", "true"], capture_output=True, timeout=10)

def fan_group(cfg):
    if not any(Path(p, "asusctl").exists() for p in os.environ.get("PATH", "").split(":")): return []
    en = run("asusctl", "fan-curve", "--get-enabled")
    cur = cfg["FAN_CURVE"] if "enabled: true" in en else "default"
    return [group("Fans", [combo_row("Fan curve", "How early the fans spin up as the machine warms", [("default", "Firmware default"), ("quiet", "Quieter (later, gentler)"), ("cool", "Cooler (earlier)")], cur,
                                     lambda v: (setv("FAN_CURVE", v), threading.Thread(target=apply_fans, args=(v,), daemon=True).start()))],
                   desc="Every curve still reaches full speed by 90 °C, and the CPU throttles itself long before it can be hurt. “Firmware default” hands control back to the machine.")]

# ---------------------------------------------------------------- System
def page_system(cfg, win):
    def sh1(*a): return run(*a) or "?"
    rows = []
    du = shutil.disk_usage("/"); dh = shutil.disk_usage(str(HOME))
    rows.append(("System disk", f"{du.free / 1e9:.0f} GB free of {du.total / 1e9:.0f} GB"))
    rows.append(("Home disk", f"{dh.free / 1e9:.0f} GB free of {dh.total / 1e9:.0f} GB"))
    try:
        mem = dict(l.split(":") for l in Path("/proc/meminfo").read_text().splitlines()); tot = int(mem["MemTotal"].split()[0]); av = int(mem["MemAvailable"].split()[0])
        rows.append(("Memory", f"{(tot - av) / 1e6:.1f} GB used of {tot / 1e6:.1f} GB"))
    except Exception: pass
    up = float(Path("/proc/uptime").read_text().split()[0]); rows.append(("Up for", f"{int(up // 3600)} h {int(up % 3600 // 60)} min"))
    rows.append(("Kernel", sh1("uname", "-r")))
    g1 = group("This machine", [(lambda t, v: (lambda r: (r.add_suffix(Gtk.Label(label=v, css_classes=["dim-label"])), r)[1])(Adw.ActionRow(title=t)))(t, v) for t, v in rows])
    health = Path("/var/lib/rog/health.txt")
    if health.exists():
        txt = health.read_text(errors="replace").strip(); when = time.strftime("%d %b %Y, %H:%M", time.localtime(health.stat().st_mtime))
        hr = [Adw.ActionRow(title=l.split(":", 1)[0].strip(), subtitle=l.split(":", 1)[1].strip()) if ":" in l else Adw.ActionRow(title=l.strip()) for l in txt.splitlines() if l.strip()][:14]
        g2 = group("SSD health", hr, desc=f"Checked {when} (weekly).")
    else:
        g2 = group("SSD health", [Adw.ActionRow(title="Not set up yet", subtitle="Install smartmontools, then:  sudo ~/rog-tune/rog-tune.sh --apply health")])
    return [g1, g2]

# ---------------------------------------------------------------- export / import of my settings
EXPORT_FILES = [".config/rog/settings.env", ".config/spotlight/aliases", ".config/spotlight/roots", ".config/spotlight/sync.list"]

def do_export(win):
    fd = Gtk.FileDialog(title="Export settings"); fd.set_initial_name(time.strftime("rog-settings-%Y%m%d.tar.gz"))
    def done(d, res):
        try: f = d.save_finish(res)
        except GLib.Error: return
        with tarfile.open(f.get_path(), "w:gz") as t:
            for rel in EXPORT_FILES:
                p = HOME / rel
                if p.exists(): t.add(str(p), arcname=rel)
    fd.save(win, None, done)

def do_import(win):
    fd = Gtk.FileDialog(title="Import settings")
    def done(d, res):
        try: f = d.open_finish(res)
        except GLib.Error: return
        with tarfile.open(f.get_path()) as t:
            for m in t.getmembers():
                if m.name in EXPORT_FILES and m.isfile():
                    dest = HOME / m.name; dest.parent.mkdir(parents=True, exist_ok=True); dest.write_bytes(t.extractfile(m).read())
        for c in (["power-watch.sh", "display"], ["nightlight.sh", "reapply"], ["input-apply.sh"]): bg(str(SD / c[0]), *c[1:])
    fd.open(win, None, done)

def page_backup(cfg, win):
    return [
        group("Back up to hp-server", [
            button_row("Choose folders and back up", "Manual only. Copies the folders you pick to the external drive on hp-server (~/Media/rog-backup). Only new and changed files are sent.",
                       "Choose and back up…", lambda: backup_flow(win), suggested=True),
            switch_row("Mirror deletions", "Also remove files from the backup that you deleted here, so it keeps only the current versions. Off: deleted files stay in the backup.",
                       cfg["BACKUP_MIRROR"] == "1", lambda on: setv("BACKUP_MIRROR", "1" if on else "0"))])]

# ---------------------------------------------------------------- window
FONT_CSS = "window.rogwin { font-size: 118%; } window.rogwin .title-4 { font-size: 120%; }"
def effective_dark(cfg):
    mode = cfg.get("APPEARANCE", "light")
    if mode == "dark": return True
    if mode != "schedule": return False
    try: a = int(cfg["NIGHT_START"]); b = int(cfg["NIGHT_END"])
    except Exception: a, b = 19, 7
    h = time.localtime().tm_hour
    return (h >= a or h < b) if a > b else (a <= h < b)

def effective_accent(cfg):
    m = cfg.get("ACCENT_MODE", "amber")
    try:
        if m == "custom" and re.match(r"^#[0-9a-fA-F]{6}$", cfg.get("ACCENT_HEX", "")): return cfg["ACCENT_HEX"]
        if m == "wallpaper":
            v = (HOME / ".cache/accent-wallpaper").read_text().strip()
            if re.match(r"^#[0-9a-fA-F]{6}$", v): return v
    except Exception: pass
    return "#c47f1c"

def accent_css(cfg):
    h = effective_accent(cfg); r, g, b = (int(h[i:i + 2], 16) for i in (1, 3, 5))
    lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    dark = effective_dark(cfg)
    text = "#%02x%02x%02x" % tuple(min(255, int(x * 1.2 + 25)) if dark else int(x * 0.85) for x in (r, g, b))
    return f"@define-color accent_bg_color {h}; @define-color accent_color {text}; @define-color accent_fg_color {'#1d150b' if lum > 0.62 else '#ffffff'};"

class SettingsWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Settings", default_width=1280, default_height=800)
        self.add_css_class("rogwin")
        cfg = load(); self.accent = Gtk.CssProvider()
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), self.accent, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        fp = Gtk.CssProvider(); fp.load_from_string(FONT_CSS); Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), fp, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        self.apply_look(cfg)
        pages = [("Display", "video-display-symbolic", page_display(cfg)),
                 ("Power & Performance", "power-profile-balanced-symbolic", page_power(cfg)),
                 ("Battery", "battery-symbolic", page_battery(cfg, self)),
                 ("Keyboard & Mouse", "input-keyboard-symbolic", page_input(cfg)),
                 ("Windows & Terminal", "window-new-symbolic", page_windows(cfg)),
                 ("Sound", "audio-volume-high-symbolic", page_sound(cfg, self)),
                 ("Wallpaper", "preferences-desktop-wallpaper-symbolic", page_wallpaper(cfg, self)),
                 ("Top Bar", "view-list-symbolic", page_bar(cfg)),
                 ("Startup Apps", "system-run-symbolic", page_startup(cfg, self)),
                 ("Spotlight", "system-search-symbolic", page_spotlight(cfg, self)),
                 ("General", "preferences-system-symbolic", page_general(cfg, self, lambda: self.apply_look(load()))),
                 ("System", "computer-symbolic", page_system(cfg, self)),
                 ("Backup", "drive-harddisk-symbolic", page_backup(cfg, self))]
        self.stack = Gtk.Stack(); self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        side = Gtk.ListBox(); side.add_css_class("navigation-sidebar"); side.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.reg = []; self.side_rows = {}
        def walk(w):
            c = w.get_first_child()
            while c: yield c; yield from walk(c); c = c.get_next_sibling()
        for name, icon, groups in pages:
            sc = Gtk.ScrolledWindow(); sc.set_hexpand(True); sc.set_vexpand(True)
            clamp = Adw.Clamp(maximum_size=1400, tightening_threshold=1100, margin_top=28, margin_bottom=48, margin_start=40, margin_end=40)   # wide pages for a full-screen window
            body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=32)
            for g in groups: body.append(g)
            clamp.set_child(body); sc.set_child(clamp); self.stack.add_named(sc, name)
            for w in walk(body):
                if isinstance(w, Adw.PreferencesGroup):
                    if w.get_title(): self.reg.append((name, w, w.get_title(), w.get_description() or ""))
                if isinstance(w, Adw.PreferencesRow):
                    sub = w.get_subtitle() if hasattr(w, "get_subtitle") else ""
                    if w.get_title(): self.reg.append((name, w, w.get_title(), sub or ""))
            box = Gtk.Box(spacing=12); box.set_margin_top(10); box.set_margin_bottom(10); box.set_margin_start(6)
            box.append(Gtk.Image.new_from_icon_name(icon)); lab = Gtk.Label(label=name, xalign=0); box.append(lab)
            row = Gtk.ListBoxRow(); row.set_child(box); row.page_name = name; side.append(row); self.side_rows[name] = row
        self.wtitle = Adw.WindowTitle(title="Display", subtitle="")
        side.connect("row-selected", lambda lb, r: self.show_page(r.page_name) if r else None)
        split = Adw.NavigationSplitView(); split.set_min_sidebar_width(300); split.set_max_sidebar_width(360)
        sb = Adw.ToolbarView(); hb = Adw.HeaderBar(); hb.set_title_widget(Adw.WindowTitle(title="Settings", subtitle="")); sb.add_top_bar(hb)
        self.search = Gtk.SearchEntry(placeholder_text="Search settings"); self.search.set_margin_start(10); self.search.set_margin_end(10); self.search.set_margin_bottom(6)
        sb.add_top_bar(self.search)
        self.results = Gtk.ListBox(); self.results.add_css_class("boxed-list"); self.results.set_selection_mode(Gtk.SelectionMode.NONE)
        rsc = Gtk.ScrolledWindow(); rcl = Adw.Clamp(maximum_size=1400, tightening_threshold=1100, margin_top=28, margin_bottom=48, margin_start=40, margin_end=40)
        rcl.set_child(self.results); rsc.set_child(rcl); self.stack.add_named(rsc, "__search__")
        self.search.connect("search-changed", self.on_search)
        sb.set_content(side); split.set_sidebar(Adw.NavigationPage.new(sb, "Settings"))
        self.side = side
        cb = Adw.ToolbarView(); ch = Adw.HeaderBar(); ch.set_title_widget(self.wtitle); cb.add_top_bar(ch); cb.set_content(self.stack)
        split.set_content(Adw.NavigationPage.new(cb, "Display"))
        self.set_content(split)
        side.select_row(side.get_row_at_index(int(os.environ.get("ROG_SETTINGS_PAGE", "0")) % len(pages)))
        def keys(c, kv, kc, st):
            if kv == Gdk.KEY_Escape:
                if self.search.get_text(): self.search.set_text(""); return True
                self.close(); return True
            if kv == Gdk.KEY_f and st & Gdk.ModifierType.CONTROL_MASK: self.search.grab_focus(); return True
            return False
        k = Gtk.EventControllerKey(); k.connect("key-pressed", keys); self.add_controller(k)

    def on_search(self, entry):
        text = entry.get_text().strip().lower()
        if not text:
            r = self.side.get_selected_row()
            if r: self.show_page(r.page_name)
            return
        child = self.results.get_first_child()
        while child: nxt = child.get_next_sibling(); self.results.remove(child); child = nxt
        hits = [(p, w, t, sub) for p, w, t, sub in self.reg if text in f"{t} {sub} {p}".lower()][:40]
        for p, w, t, sub in hits:
            r = Adw.ActionRow(title=t, subtitle=f"{p}" + (f"  ·  {sub}" if sub else "")); r.set_activatable(True)
            r.connect("activated", lambda _r, p=p, w=w: self.jump(p, w)); self.results.append(r)
        if not hits: self.results.append(Adw.ActionRow(title="No settings match", subtitle="Try another word"))
        self.stack.set_visible_child_name("__search__"); self.wtitle.set_title("Search")

    def jump(self, page, row):
        self.search.set_text(""); self.side.select_row(self.side_rows[page]); GLib.idle_add(lambda: (row.grab_focus(), False)[1])

    def show_page(self, name):
        self.stack.set_visible_child_name(name); self.wtitle.set_title(name)

    def apply_look(self, cfg):
        Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK if effective_dark(cfg) else Adw.ColorScheme.FORCE_LIGHT)
        self.accent.load_from_string(accent_css(cfg))

class App(Adw.Application):
    def __init__(self, backup_only=False):
        super().__init__(application_id="rog.Settings"); self.backup_only = backup_only
    def do_activate(self):
        if self.backup_only:
            Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), self._accent(), Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
            Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK if effective_dark(load()) else Adw.ColorScheme.FORCE_LIGHT)
            self.hold(); backup_flow(None, on_done=self.quit)
        else:
            SettingsWindow(self).present()
    def _accent(self):
        p = Gtk.CssProvider(); p.load_from_string(accent_css(load())); return p

def main():
    GLib.set_prgname("RogSettings"); GLib.set_application_name("RogSettings")
    Adw.init()
    sys.exit(App(backup_only="--backup" in sys.argv).run([sys.argv[0]]))

if __name__ == "__main__":
    main()
RSET
	cat >"$W/spotlight.py" <<'RSPOT'
#!/usr/bin/env python3
# rog-tune: Spotlight. One search box for apps, open windows, files, maths/units, clipboard history and system actions.
#   Enter run/open   Ctrl+Enter reveal folder / run in a terminal   Ctrl+C copy (a file copies as the file)   Esc close
#   Ctrl+J/K or Ctrl+N/P or Up/Down move   Alt+1..9 pick a row   Tab next row
#   prefixes:  =2+2 (maths)   c word (clipboard history)   > cmd (run a command)   w word (windows only)
# Searches while I type (plocate for files, qalc for maths). Closes itself when it loses focus. Nothing stays resident.
import json, math, os, re, shlex, subprocess, sys, threading, time
from pathlib import Path
import gi
gi.require_version("Gtk", "3.0"); gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, Gio, GLib, Pango

HOME = Path.home()
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "spotlight"
STATE.mkdir(parents=True, exist_ok=True)
HIST = STATE / "history.json"
SCRIPTS = HOME / ".config/scripts"
MAXROWS = 10

# ---------------------------------------------------------------- helpers
def sh(cmd, timeout=1.0):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout).stdout
    except Exception:
        return ""

def spawn(cmd):
    p = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL, start_new_session=True)
    threading.Thread(target=p.wait, daemon=True).start()     # reap it when it ends (no <defunct> children of this long-lived process)

def copy(text):
    p = subprocess.Popen(["xclip", "-selection", "clipboard"], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    p.stdin.write(text.encode()); p.stdin.close()

def copy_file(path):
    """Alt+Enter on a file: put the file itself on the clipboard. Text -> its text; image -> the picture; anything else -> the file (paste it into a mail, chat or file manager)."""
    import mimetypes
    mt = mimetypes.guess_type(path)[0] or ""
    def pipe(args, data):
        pr = subprocess.Popen(["xclip", "-selection", "clipboard"] + args, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        pr.stdin.write(data); pr.stdin.close()
    try:
        if mt.startswith("image/") and os.path.getsize(path) < 40e6:
            pipe(["-t", mt], open(path, "rb").read()); return
        if (mt.startswith("text/") or mt in ("application/json", "application/x-tex", "application/xml") or path.endswith((".md", ".tex", ".bib", ".org", ".py", ".sh", ".R", ".qmd", ".csv", ".txt"))) and os.path.getsize(path) < 2e6:
            pipe([], open(path, "rb").read()); return
    except Exception:
        pass
    uri = Path(path).resolve().as_uri().encode()
    pipe(["-t", "x-special/gnome-copied-files"], b"copy\n" + uri)

def load_hist():
    try:
        return json.loads(HIST.read_text())
    except Exception:
        return {}

HISTORY = load_hist()

def bump(key):
    n, _ = HISTORY.get(key, [0, 0])
    HISTORY[key] = [n + 1, int(time.time())]
    try:
        HIST.write_text(json.dumps(HISTORY))
    except Exception:
        pass

def frecency(key):
    n, last = HISTORY.get(key, [0, 0])
    if not n:
        return 0.0
    age_days = (time.time() - last) / 86400
    return min(40.0, 8.0 * n) / (1 + age_days / 14)

def match(q, text):
    """0 = no match. Every word of the query must match; prefix > word start > substring > in-order letters."""
    text = text.lower()
    total = 0
    for tok in q.lower().split():
        if text.startswith(tok): s = 100
        elif re.search(r"[\s\-_./]" + re.escape(tok), text): s = 80
        elif tok in text: s = 60
        else:
            s = 0
        if not s:
            return 0
        total += s
    return total / max(1, len(q.split()))

# ---------------------------------------------------------------- sources
class Item:
    __slots__ = ("kind", "title", "sub", "icon", "score", "run", "alt", "reveal", "key")
    def __init__(self, kind, title, sub="", icon="", score=0, run=None, alt=None, reveal=None, key=None):
        self.kind, self.title, self.sub, self.icon, self.score = kind, title, sub, icon, score
        self.run, self.alt, self.reveal, self.key = run, alt, reveal, key

APPS = []
def load_apps():
    del APPS[:]
    for a in Gio.AppInfo.get_all():
        if not a.should_show():
            continue
        kw = " ".join(a.get_keywords() or []) if hasattr(a, "get_keywords") else ""
        APPS.append((a, a.get_display_name() or "", (a.get_description() or ""), kw, a.get_id() or ""))

def launch_app(a):
    d = Gio.DesktopAppInfo.new(a.get_id()) if a.get_id() else None
    term = d.get_string("Terminal") == "true" if d else False
    if term:
        cmd = a.get_commandline() or ""
        cmd = re.sub(r"%[a-zA-Z]", "", cmd).strip()
        spawn(["kitty", "sh", "-lc", cmd]); return
    ctx = Gdk.Display.get_default().get_app_launch_context()
    try:
        a.launch([], ctx)
    except Exception:
        spawn(["sh", "-lc", re.sub(r"%[a-zA-Z]", "", a.get_commandline() or "")])

def apps_for(q):
    out = []
    for a, name, desc, kw, aid in APPS:
        if q:
            s = max(match(q, name) * 1.0, match(q, aid.replace(".desktop", "")) * 0.6)
            for txt, w in ((kw, 0.7), (desc, 0.35)):
                m2 = match(q, txt)
                if m2 >= 60:
                    s = max(s, m2 * w)
            if not s:
                continue
        else:
            s = 0
            if not frecency("app:" + aid):
                continue
        out.append(Item("App", name, desc, "", 20 + s + frecency("app:" + aid), run=lambda a=a: launch_app(a),
                        alt=lambda n=name: n, key="app:" + aid))
        out[-1].icon = a.get_icon()
    return out

_THUMBS = {}
def window_thumb(wid, title):
    """A small picture of a window (only works for windows on the visible workspace); cached for a few seconds."""
    from gi.repository import GdkPixbuf
    k = (wid, title); hit = _THUMBS.get(k)
    if hit and time.time() - hit[0] < 8: return hit[1]
    pix = None
    try:
        r = subprocess.run(["import", "-window", str(wid), "-resize", "96x64", "png:-"], capture_output=True, timeout=1.5)
        if r.returncode == 0 and len(r.stdout) > 400:
            ld = GdkPixbuf.PixbufLoader(); ld.write(r.stdout); ld.close(); pix = ld.get_pixbuf()
    except Exception:
        pix = None
    _THUMBS[k] = (time.time(), pix)
    return pix

def windows_for(q, only=False):
    if not q and not only:
        return []
    try:
        tree = json.loads(sh(["i3-msg", "-t", "get_tree"], 1.5))
    except Exception:
        return []
    out = []
    def walk(n, ws=""):
        if n.get("type") == "workspace":
            ws = n.get("name", "")
        if n.get("window") and n.get("name") and ws and not ws.startswith("__"):
            cls = (n.get("window_properties") or {}).get("class", "")
            s = max(match(q, n["name"]), match(q, cls) * 0.9) if q else 50
            if s:
                cid = n["id"]
                thumb = window_thumb(n["window"], n["name"]) if (only and len(out) < 8) else None     # pictures only in "w " mode
                out.append(Item("Window", n["name"], f"{cls} · workspace {ws}", thumb or cls.lower(), (60 if only else 35) + s,
                                run=lambda cid=cid: sh(["i3-msg", f"[con_id={cid}] focus"])))
        for c in n.get("nodes", []) + n.get("floating_nodes", []):
            walk(c, ws)
    walk(tree)
    return out

def action_items():
    def A(title, keywords, cmd, icon):
        return (title, keywords, cmd, icon)
    s = str(SCRIPTS)
    acts = [
        A("Lock screen", "lock", [str(HOME / ".config/i3lock/lock.sh")], "system-lock-screen"),
        A("Sleep", "suspend sleep", ["systemctl", "suspend"], "system-suspend"),
        A("Restart", "reboot restart", ["systemctl", "reboot"], "system-reboot"),
        A("Shut down", "poweroff shutdown power off", ["systemctl", "poweroff"], "system-shutdown"),
        A("Log out", "logout exit i3", ["i3-msg", "exit"], "system-log-out"),
        A("Performance mode: Quiet (least battery)", "performance mode quiet battery saver silent", [s + "/power-mode.sh", "quiet"], "battery-caution"),
        A("Performance mode: Balanced", "performance mode balanced normal", [s + "/power-mode.sh", "balanced"], "battery-good"),
        A("Performance mode: Performance (CPU and fans unrestricted)", "performance mode fast turbo max", [s + "/power-mode.sh", "performance"], "battery-full-charged"),
        A("Night tint on/off", "night light tint warm", [s + "/nightlight.sh", "toggle"], "weather-clear-night"),
        A("Caffeine on/off (keep screen awake)", "caffeine awake idle presentation", [s + "/caffeine.sh", "toggle"], "coffee"),
        A("Tablet mode on/off", "tablet keyboard touch", [s + "/tablet.sh", "toggle"], "input-tablet"),
        A("Freeze/unfreeze auto-rotate", "rotate rotation lock orientation", [s + "/autorotate.sh", "lock"], "object-rotate-right"),
        A("Next wallpaper", "wallpaper background", [str(HOME / ".config/wallpaper-config/wallpaper-cycle.sh")], "preferences-desktop-wallpaper"),
        A("Browse all apps", "apps all browse show all applications grid", [s + "/rog-ui.sh", "apps"], "view-app-grid"),
        A("Back up to hp-server…", "backup rsync sync server hp external", [s + "/rog-ui.sh", "backup"], "drive-harddisk"),
        A("Settings", "settings preferences options configure toggles", [s + "/rog-ui.sh", "settings"], "preferences-system"),
        A("System update (reads Arch news first)", "update upgrade pacman news arch system packages", ["kitty", "--class", "rog-sync", s + "/rog-update.sh"], "system-software-update"),
        A("Roll back the last update", "rollback roll back undo update downgrade restore packages", ["kitty", "--class", "rog-sync", s + "/rog-update.sh", "--rollback"], "document-revert"),
        A("Task monitor", "task monitor processes cpu memory", [s + "/sysmon.sh"], "utilities-system-monitor"),
        A("Keybinds", "keys shortcuts keybinds help", [s + "/keys.sh"], "input-keyboard"),
        A("Restart i3", "reload restart i3", ["i3-msg", "restart"], "view-refresh"),
    ]
    try:
        if "resume_offset" in Path("/proc/cmdline").read_text():
            acts.append(A("Hibernate", "hibernate", ["systemctl", "hibernate"], "system-suspend-hibernate"))
    except Exception:
        pass
    return acts

def actions_for(q):
    if len(q) < 2:
        return []
    out = []
    for title, kw, cmd, icon in action_items():
        s = max(match(q, title), match(q, kw) * 0.8)
        if s:
            out.append(Item("Action", title, "Action", icon, 12 + s,
                            run=lambda c=cmd: spawn(c), key="act:" + title))
    return out

ROOTS = (str(HOME) + "/", "/mnt/", "/media/", "/run/media/", "/srv/")
JUNK = ("site-packages", "/env/", "/venv/", "/.venv/", "/.local/share/", "/yay/", "/go/pkg/", "/target/debug/", "/target/release/", "/dist-packages/", "/.local/state/", "/.docker/", "/snap/", "/.gradle/", "/.m2/", "/.ollama/", "/libreoffice/", "/.config/Code/", "/.config/BraveSoftware/", "/.cache/", "/.git/", "/node_modules/", "/.local/share/Trash/", "/.zen/", "/.mozilla/", "/.config/google-chrome/",
        "/.config/chromium/", "/.npm/", "/.cargo/registry/", "/.rustup/", "/__pycache__/", "/.local/share/pnpm/", "/.nvm/",
        "/.var/", "/.steam/", "/.wine/", "/proc/", "/sys/", "/usr/lib/", "/usr/share/", "/var/", "/opt/", "/.local/lib/")

def FILEMETA(p):
    return file_meta(p)

def files_for(q):
    if len(q) < 2:
        return []
    out = sh(["plocate", "-i", "-b", "-l", "300", "--", q.replace(" ", "*")], 0.8).splitlines()
    items = []
    home = str(HOME)
    for p in out:
        if not p.startswith(ROOTS) or any(j in p for j in JUNK) or not os.path.exists(p):
            continue
        name = os.path.basename(p)
        s = match(q, name)
        if not s:
            s = 20
        rel = p[len(home):] if p.startswith(home) else p
        hidden = sum(1 for c in rel.split("/")[:-1] if c.startswith("."))
        s = s * 0.5 - 15 * hidden - 1.5 * rel.count("/") - 8 * (name.startswith(".")) + (10 if p.startswith(home) else 0)
        d = os.path.dirname(p).replace(home, "~")
        isdir = os.path.isdir(p)
        items.append(Item("Folder" if isdir else "File", name, FILEMETA(p) + "  ·  " + d, "folder" if isdir else Gio.content_type_get_icon(Gio.content_type_guess(p, None)[0]),
                          s, run=lambda p=p: spawn(["xdg-open", p]), alt=lambda p=p: p,
                          reveal=lambda p=p: spawn(["xdg-open", os.path.dirname(p)]), key="file:" + p))
    items.sort(key=lambda i: -i.score)
    return items[:6]

def recent_files(limit=3):
    out = []
    xbel = HOME / ".local/share/recently-used.xbel"
    try:
        txt = xbel.read_text()
    except Exception:
        return out
    from urllib.parse import unquote
    for m in reversed(re.findall(r'<bookmark href="file://([^"]+)"', txt)):
        p = unquote(m)
        if os.path.exists(p) and not any(j in p for j in JUNK):
            out.append(Item("Recent", os.path.basename(p), os.path.dirname(p).replace(str(HOME), "~"),
                            Gio.content_type_get_icon(Gio.content_type_guess(p, None)[0]), 5,
                            run=lambda p=p: spawn(["xdg-open", p]), alt=lambda p=p: p,
                            reveal=lambda p=p: spawn(["xdg-open", os.path.dirname(p)]), key="file:" + p))
        if len(out) >= limit:
            break
    return out

MATH = re.compile(r"^=|[0-9].*[-+*/^%()×÷]|\d\s*[a-zA-Z°]+\s+(to|in|as)\s+\S+|^(sqrt|sin|cos|tan|log|ln|exp|abs)\b", re.I)
def calc_norm(expr):
    """Say what people mean: `in` is a conversion (not inches), c/f/k after a number or `to` are temperatures, `15% of 80` is a product."""
    expr = re.sub(r"(\d+(?:\.\d+)?)\s*%\s*of\s+", r"(\1/100) * ", expr)
    expr = re.sub(r"\s+(?:in|as)\s+(?=(?!to\b)[A-Za-z°/])", " to ", expr)
    temp = {"c": "celsius", "f": "fahrenheit", "k": "kelvin"}
    expr = re.sub(r"(?<=\d)\s*°?\s*([cfCF])\b(?!\w)", lambda m: " " + temp[m.group(1).lower()], expr)
    expr = re.sub(r"(?<=\bto)\s+°?([cfkCFK])\s*$", lambda m: " " + temp[m.group(1).lower()], expr)
    return expr

def calc_for(q):
    if not MATH.search(q):
        return []
    expr = q.lstrip("=").strip()
    if not expr:
        return []
    shown = expr
    expr = calc_norm(expr)
    r = sh(["qalc", "-t", expr], 1.0).strip().splitlines()
    r = r[-1].strip() if r else ""
    m = re.match(r"^(.+?)\s+to\s+([A-Za-z°]+)$", expr)
    if m and re.search(r"\S\s\+\s\d", r):         # qalc splits miles/feet into "3 mi + 188 yd + ..."; give one number instead
        n = sh(["qalc", "-t", f"({m.group(1)}) / (1 {m.group(2)})"], 1.0).strip().splitlines()
        if n and re.match(r"^-?[0-9.]+(E[-+]?\d+)?$", n[-1].strip()):
            r = f"{n[-1].strip()} {m.group(2)}"
    if not r or r.lower().startswith(("error", "warning")) or r == expr:
        return []
    r = r.replace("≈", "").strip()
    return [Item("Calc", r, f"{shown}  ·  Enter copies", "accessories-calculator", 1000, run=lambda r=r: copy(r), alt=lambda r=r: r)]

CLIPFILE = STATE / "clipboard.json"
CLIPIMG = STATE / "clipimg"
CLIP_MAX = 3000            # entries kept (text and images together); greenclip kept 200
CLIP_MAX_IMAGES = 300
CLIP_MAX_CHARS = 500000
_clip_cache = []           # the resident process keeps the history in memory: searching never re-reads the file

def load_clip():
    global _clip_cache
    if not _clip_cache:
        try:
            _clip_cache = json.loads(CLIPFILE.read_text())
        except Exception:
            _clip_cache = []
    return _clip_cache

def save_clip():
    try:
        tmp = CLIPFILE.with_suffix(".tmp")
        tmp.write_text(json.dumps(_clip_cache)); os.chmod(tmp, 0o600); tmp.replace(CLIPFILE)
    except Exception:
        pass

def prune_clip():
    global _clip_cache
    imgs = 0; keep = []
    for e in _clip_cache:
        if "img" in e:
            imgs += 1
            if imgs > CLIP_MAX_IMAGES:
                try: (CLIPIMG / e["img"]).unlink()
                except Exception: pass
                continue
        keep.append(e)
    _clip_cache = keep[:CLIP_MAX]

def store_clip(text, ts=None):
    """Called by the resident process whenever the clipboard changes (event driven, no polling)."""
    if not text or not text.strip() or len(text) > CLIP_MAX_CHARS:
        return
    load_clip()
    _clip_cache[:] = [e for e in _clip_cache if e.get("s") != text]
    _clip_cache.insert(0, {"t": int(ts or time.time()), "s": text})
    prune_clip(); save_clip()

def store_clip_image(png, w=0, h=0, ts=None):
    import hashlib
    name = hashlib.sha1(png).hexdigest()[:20] + ".png"
    CLIPIMG.mkdir(parents=True, exist_ok=True)
    p = CLIPIMG / name
    if not p.exists():
        p.write_bytes(png); os.chmod(p, 0o600)
    load_clip()
    _clip_cache[:] = [e for e in _clip_cache if e.get("img") != name]
    _clip_cache.insert(0, {"t": int(ts or time.time()), "img": name, "w": w, "h": h})
    prune_clip(); save_clip()

def clip_changed(cb):
    """Clipboard owner changed: text is stored as text; if there is no text but an image (a screenshot), as an image."""
    def got_image(c, pix, d):
        if pix is None: return
        ok, buf = pix.save_to_bufferv("png", [], [])
        if ok and len(buf) < 40_000_000: store_clip_image(bytes(buf), pix.get_width(), pix.get_height())
    def got_text(c, text, d):
        if text is not None and text.strip(): store_clip(text)
        elif text is None: c.request_image(got_image, None)
    cb.request_text(got_text, None)

def clip_for(q):
    from gi.repository import GdkPixbuf
    items = []
    ql = q.lower()
    for i, e in enumerate(load_clip()):
        if "img" in e:
            if ql and not any(w in ("image", "img", "screenshot", "picture", "png") or w in "image screenshot" for w in ql.split()):
                continue
            p = CLIPIMG / e["img"]
            if not p.exists(): continue
            try: pix = GdkPixbuf.Pixbuf.new_from_file_at_size(str(p), 56, 56)
            except Exception: pix = None
            if not e.get("w"):                                  # imported entries have no size on record: read it from the file once
                try:
                    info = GdkPixbuf.Pixbuf.get_file_info(str(p)); e["w"], e["h"] = info[1], info[2]
                except Exception: pass
            items.append(Item("Clip", f"Image  {e.get('w', '?')} × {e.get('h', '?')}", "", pix or "image-x-generic",
                              500 - i, run=lambda p=p: spawn(["sh", "-c", f"xclip -selection clipboard -t image/png -i '{p}'"]),
                              reveal=lambda p=p: spawn(["xdg-open", str(p)])))
        else:
            text = e.get("s", "")
            if ql and ql not in text.lower():
                continue
            lines = text.strip().splitlines() or [text]
            title = lines[0].strip()[:140] + (f"   (+{len(lines) - 1} lines)" if len(lines) > 1 else "")
            items.append(Item("Clip", title, "", "edit-paste", 500 - i,
                              run=lambda t=text: copy(t), alt=lambda t=text: t))
        if len(items) >= MAXROWS:
            break
    return items

def import_greenclip():
    """One-off: bring the old greenclip history in (exact text and images), oldest first so the order is kept."""
    import subprocess as sp
    lines = sp.run(["greenclip", "print"], capture_output=True, text=True).stdout.splitlines()
    now = int(time.time()); n = len(lines); done = 0
    load_clip()
    for k, line in enumerate(reversed(lines)):
        ts = now - (n - k) * 600                          # greenclip kept no times: spread them out, keeping the order
        if not line.strip(): continue
        pr = sp.Popen(["greenclip", "print", line], stdout=sp.DEVNULL, stderr=sp.DEVNULL)
        time.sleep(0.25)
        try:
            if line.startswith("image/"):
                png = sp.run(["xclip", "-selection", "clipboard", "-t", "image/png", "-o"], capture_output=True, timeout=3).stdout
                if png[:4] == b"\x89PNG": store_clip_image(png, ts=ts); done += 1
            else:
                txt = sp.run(["xclip", "-selection", "clipboard", "-o"], capture_output=True, timeout=3).stdout.decode("utf-8", "replace")
                if txt.strip(): store_clip(txt, ts=ts); done += 1
        finally:
            pr.kill()
    print(f"imported {done} of {n} entries from greenclip")

def web_for(q):
    if len(q) < 2:
        return []
    from urllib.parse import quote_plus
    if re.match(r"^(https?://|www\.)\S+$", q):
        url = q if q.startswith("http") else "https://" + q
        return [Item("Web", f"Open {url}", "", "web-browser", 900, run=lambda: spawn(["xdg-open", url]))]
    url = "https://duckduckgo.com/?q=" + quote_plus(q)
    return [Item("Web", f"Search the web for “{q}”", "", "web-browser", -100, run=lambda: spawn(["xdg-open", url]))]

# ---------------------------------------------------------------- timers and reminders
ALARMS = STATE / "alarms.json"
_DUR = re.compile(r"(\d+(?:\.\d+)?)\s*(h|hr|hrs|hours?|m|min|mins|minutes?|s|sec|secs|seconds?)(?![a-z])", re.I)

def parse_duration(text):
    """'25m', '1h30m', '90s', '1 hour 15 min', or a bare number = minutes. Returns (seconds, rest-of-text) or None."""
    t = text.strip(); total = 0; pos = 0; found = False
    for m in _DUR.finditer(t):
        if t[pos:m.start()].strip(): break
        n = float(m.group(1)); u = m.group(2).lower()[0]
        total += n * (3600 if u == "h" else 60 if u == "m" else 1); pos = m.end(); found = True
    if not found:
        m = re.match(r"^(\d+(?:\.\d+)?)\b", t)
        if not m: return None
        total = float(m.group(1)) * 60; pos = m.end()
    return (int(total), t[pos:].strip()) if 0 < total <= 7 * 86400 else None

def parse_clock(text):
    """'15:30', '3pm', '3:30 pm', optionally prefixed by 'tomorrow'. Returns (seconds from now, rest) or None."""
    t = text.strip(); day = 0
    m0 = re.match(r"^(tomorrow|tmrw)\s+", t, re.I)
    if m0: day = 1; t = t[m0.end():]
    m = re.match(r"^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b", t, re.I)
    if not m: return None
    h = int(m.group(1)); mi = int(m.group(2) or 0); ap = (m.group(3) or "").lower()
    if not m.group(2) and not ap: return None              # a lone number is not a time of day
    if ap == "pm" and h < 12: h += 12
    if ap == "am" and h == 12: h = 0
    if h > 23 or mi > 59: return None
    now = time.time(); lt = time.localtime(now)
    due = time.mktime((lt.tm_year, lt.tm_mon, lt.tm_mday + day, h, mi, 0, 0, 0, -1))
    if due <= now and not day: due += 86400
    return (int(math.ceil(due - now)), t[m.end():].strip())

def fmt_secs(n):
    h, r = divmod(int(n), 3600); m, sec = divmod(r, 60)
    return " ".join(x for x in (f"{h} h" if h else "", f"{m} min" if m else "", f"{sec} s" if sec and not h else "") if x) or "0 s"

def load_alarms():
    try: return json.loads(ALARMS.read_text())
    except Exception: return {}

def schedule_alarm(secs, msg):
    unit = f"rog-alarm-{int(time.time())}"
    env = [f"--setenv={k}={os.environ[k]}" for k in ("DISPLAY", "XAUTHORITY", "XDG_RUNTIME_DIR", "DBUS_SESSION_BUS_ADDRESS") if k in os.environ]
    subprocess.run(["systemd-run", "--user", "--collect", f"--unit={unit}", f"--on-active={max(100, int(secs * 1000) - 400)}ms", "--timer-property=AccuracySec=10ms"] + env +   # fire early by the ~0.4 s the alarm window needs to start
                   ["python3", str(SCRIPTS / "alarm.py"), msg or "Time is up"], capture_output=True)
    a = load_alarms(); a[unit] = {"msg": msg or "Timer", "due": int(time.time() + secs)}
    a = {k: v for k, v in a.items() if v["due"] > time.time() - 60}
    ALARMS.write_text(json.dumps(a))

def cancel_alarm(unit):
    subprocess.run(["systemctl", "--user", "stop", unit + ".timer"], capture_output=True)
    a = load_alarms(); a.pop(unit, None); ALARMS.write_text(json.dumps(a))

def alarm_items(q):
    ql = q.strip().lower()
    items = []
    m = re.match(r"^(timer|countdown)\s+(.+)$", ql)
    if m:
        d = parse_duration(m.group(2))
        if d:
            secs, label = d; due = time.strftime("%H:%M", time.localtime(time.time() + secs))
            items.append(Item("Timer", f"Timer for {fmt_secs(secs)}" + (f" — {label}" if label else ""), f"Rings at {due}  ·  press Enter to start",
                              "appointment-soon", 1000, run=lambda s=secs, l=label: schedule_alarm(s, l or f"Timer ({fmt_secs(s)}) is up")))
        return items
    m = re.match(r"^remind(?:er)?(?:\s+me)?\s+(?:to\s+)?(.+)$", ql)
    if m:
        body = m.group(1); res = None
        mi = re.match(r"^in\s+(.+)$", body)
        if mi:
            d = parse_duration(mi.group(1))
            if d: res = d
        if not res:
            mc = re.match(r"^(?:at\s+)?(.+)$", body)
            if mc: res = parse_clock(mc.group(1))
        if res:
            secs, label = res; due = time.strftime("%a %H:%M", time.localtime(time.time() + secs))
            items.append(Item("Timer", (label or "Reminder"), f"Reminder {due}  ·  press Enter to set it",
                              "appointment-soon", 1000, run=lambda s=secs, l=label: schedule_alarm(s, l or "Reminder")))
        return items
    if ql in ("timers", "alarms", "reminders", "timer", "remind"):
        a = load_alarms(); now = time.time()
        for unit, v in sorted(a.items(), key=lambda kv: kv[1]["due"]):
            if v["due"] > now:
                items.append(Item("Timer", v["msg"], f"Rings in {fmt_secs(v['due'] - now)} ({time.strftime('%H:%M', time.localtime(v['due']))})  ·  Enter cancels it",
                                  "appointment-soon", 900, run=lambda u=unit: cancel_alarm(u)))
        if not items:
            items.append(Item("Timer", "No timers or reminders pending", "Try:  timer 25m   ·   remind in 10m call back   ·   remind 15:30 stand up", "appointment-soon", 900))
    return items

# ---------------------------------------------------------------- more sources (each is wrapped so one failure cannot break Spotlight)
KINDS = {"pdf": (".pdf",), "doc": (".doc", ".docx", ".odt", ".rtf", ".pages"), "slides": (".ppt", ".pptx", ".odp", ".key"),
         "sheet": (".xls", ".xlsx", ".ods", ".csv", ".tsv"), "image": (".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".avif", ".bmp", ".tif", ".tiff"),
         "text": (".txt", ".md", ".org", ".rst", ".tex", ".bib"), "code": (".py", ".rs", ".c", ".h", ".cpp", ".js", ".ts", ".sh", ".go", ".java", ".ipynb", ".r"),
         "audio": (".mp3", ".flac", ".ogg", ".opus", ".wav", ".m4a"), "video": (".mp4", ".mkv", ".webm", ".avi", ".mov"), "archive": (".zip", ".tar", ".gz", ".xz", ".7z", ".rar", ".tgz")}

def split_filters(q):
    """kind:pdf  in:notes  modified:today|week|month   (any order); returns ({filters}, remaining text)."""
    flt = {}; rest = []
    for tok in q.split():
        m = re.match(r"^(kind|type|in|modified|mod):(\S*)$", tok, re.I)
        if m and m.group(2):
            k = m.group(1).lower(); k = {"type": "kind", "mod": "modified"}.get(k, k); flt[k] = m.group(2).lower()
        else: rest.append(tok)
    return flt, " ".join(rest)

def filtered_files(flt, text):
    kind = flt.get("kind"); exts = KINDS.get(kind) if kind else None
    if kind and kind != "folder" and not exts: return []
    home = str(HOME); hre = re.escape(home); inn = re.escape(flt["in"]) if flt.get("in") else ""
    if text:
        pat = ["plocate", "-i", "-b", "-l", "4000", "--", text.replace(" ", "*")]
    elif exts:
        pat = ["plocate", "--regex", "-i", "-l", "8000", "--", f"^{hre}/.*{inn}.*({'|'.join(re.escape(e) for e in exts)})$"]
    else:
        pat = ["plocate", "--regex", "-i", "-l", "4000", "--", f"^{hre}/.*{inn or '[^/]'}[^/]*$"]
    out = sh(pat, 3.0).splitlines(); res = []
    cutoff = {"today": 86400, "day": 86400, "week": 7 * 86400, "month": 30 * 86400}.get(flt.get("modified", ""), 0)
    for p in out:
        if not p.startswith(ROOTS) or any(j in p for j in JUNK): continue
        rel = p[len(home):] if p.startswith(home) else p
        if any(c.startswith(".") for c in rel.split("/")[:-1]): continue            # hidden folders are noise for a filtered listing
        if exts and not p.lower().endswith(exts): continue
        if kind == "folder" and not os.path.isdir(p): continue
        if flt.get("in") and flt["in"] not in p.lower().replace(home.lower(), ""): continue
        try: mt = os.stat(p).st_mtime
        except OSError: continue
        if cutoff and time.time() - mt > cutoff: continue
        res.append((mt, p))
    res.sort(reverse=True)
    items = []
    for mt, p in res[:MAXROWS]:
        isdir = os.path.isdir(p)
        items.append(Item("Folder" if isdir else "File", os.path.basename(p), file_meta(p) + "  ·  " + os.path.dirname(p).replace(home, "~"),
                          "folder" if isdir else Gio.content_type_get_icon(Gio.content_type_guess(p, None)[0]), 100 - len(items),
                          run=lambda p=p: spawn(["xdg-open", p]), alt=lambda p=p: p, reveal=lambda p=p: spawn(["xdg-open", os.path.dirname(p)]), key="file:" + p))
    return items

ALIASES_FILE = HOME / ".config/spotlight/aliases"
def alias_items(q):
    try:
        if not ALIASES_FILE.exists():
            ALIASES_FILE.parent.mkdir(parents=True, exist_ok=True)
            ALIASES_FILE.write_text("# your own shortcuts for Spotlight:  name = what to open  (a folder, a file, a web address, or a command)\\n"
                                    "# examples (remove the # to use):\\n# thesis = ~/Documents/thesis\\n# overleaf = https://www.overleaf.com/project\\n# gpu = kitty -e nvidia-smi\\n")
        out = []; ql = q.strip().lower()
        for line in ALIASES_FILE.read_text().splitlines():
            if "=" not in line or line.lstrip().startswith("#"): continue
            name, target = (x.strip() for x in line.split("=", 1))
            if not name or not target or not (ql == name.lower() or name.lower().startswith(ql)): continue
            path = os.path.expanduser(target)
            if re.match(r"^https?://", target) or os.path.exists(path): fn = lambda t=path if os.path.exists(path) else target: spawn(["xdg-open", t])
            else: fn = lambda t=target: spawn(["sh", "-lc", t])
            out.append(Item("Alias", name, target, "emblem-symbolic-link" if False else "go-jump", 1500 if ql == name.lower() else 900, run=fn, key="alias:" + name))
        return out
    except Exception:
        return []

ACTIONS_OF = {}
def app_action_items(q):
    if len(q) < 3: return []
    out = []
    for a, name, desc, kw, aid in APPS:
        acts = ACTIONS_OF.get(aid)
        if acts is None:
            try:
                d = Gio.DesktopAppInfo.new(aid); acts = [(x, d.get_action_name(x)) for x in (d.list_actions() if d else [])]
            except Exception: acts = []
            ACTIONS_OF[aid] = acts
        for act, label in acts:
            sc = match(q, f"{name} {label}")
            if sc and sc >= 60 and match(q.split()[0], name):
                out.append(Item("Action", f"{name}: {label}", "App action", a.get_icon(), 18 + sc * 0.9,
                                run=lambda aid=aid, act=act: Gio.DesktopAppInfo.new(aid).launch_action(act, Gdk.Display.get_default().get_app_launch_context()), key=f"act:{aid}:{act}"))
    return out

_EMOJI = []
def emoji_items(q):
    import unicodedata
    if not _EMOJI:
        for lo, hi in ((0x1F300, 0x1FAFF), (0x2600, 0x27BF), (0x2B00, 0x2BFF), (0x1F000, 0x1F2FF)):
            for cp in range(lo, hi + 1):
                try: _EMOJI.append((chr(cp), unicodedata.name(chr(cp)).lower()))
                except ValueError: pass
        for cp in (0x2764, 0x2705, 0x274C, 0x2728, 0x2B50, 0x203C, 0x2049, 0x2753, 0x2757, 0x00A9, 0x00AE, 0x2122): _EMOJI.append((chr(cp), unicodedata.name(chr(cp), "").lower()))
    words = q.lower().split()
    out = []
    for ch, nm in _EMOJI:
        if all(w in nm for w in words):
            out.append(Item("Emoji", f"{ch}   {nm}", "Enter copies it", "face-smile", 500 - len(out), run=lambda c=ch: copy(c), alt=lambda c=ch: c))
            if len(out) >= MAXROWS: break
    return out

def history_items(q):
    try: lines = (HOME / ".bash_history").read_text(errors="replace").splitlines()
    except Exception: return []
    seen = set(); out = []; ql = q.lower()
    for cmd in reversed(lines):
        cmd = cmd.strip()
        if not cmd or cmd in seen or cmd.startswith("#"): continue
        seen.add(cmd)
        if ql and ql not in cmd.lower(): continue
        out.append(Item("Cmd", cmd[:140], "Shell history  ·  Enter copies  ·  Ctrl+Enter runs it in a terminal", "utilities-terminal", 500 - len(out),
                        run=lambda c=cmd: copy(c), alt=lambda c=cmd: c, reveal=lambda c=cmd: spawn(["kitty", "sh", "-lc", c + "; echo; read -rp 'press Enter to close '"])))
        if len(out) >= MAXROWS: break
    return out

# ---- bookmarks (Chrome, Firefox/Zen, qutebrowser): indexed once, re-read only when a file changed
_BM = {"sig": None, "items": []}
def bookmark_files():
    fs = []
    for pat in (".config/google-chrome/*/Bookmarks", ".config/chromium/*/Bookmarks", ".zen/*/places.sqlite", ".config/mozilla/firefox/*/places.sqlite",
                ".mozilla/firefox/*/places.sqlite", ".config/qutebrowser/quickmarks", ".config/qutebrowser/bookmarks/urls"):
        fs += [Path(p) for p in __import__("glob").glob(str(HOME / pat))]
    return fs

def load_bookmarks():
    files = bookmark_files()
    sig = tuple((str(f), int(f.stat().st_mtime)) for f in files if f.exists())
    if sig == _BM["sig"]: return _BM["items"]
    out = []
    import tempfile, shutil, sqlite3
    for f in files:
        try:
            if f.name == "Bookmarks":
                def walk(n):
                    if n.get("type") == "url": out.append((n.get("name", ""), n.get("url", "")))
                    for c in n.get("children", []): walk(c)
                for r in json.loads(f.read_text()).get("roots", {}).values():
                    if isinstance(r, dict): walk(r)
            elif f.name == "places.sqlite":
                tmp = Path(tempfile.mkdtemp(prefix="bm-")); shutil.copy(f, tmp / "p.sqlite")
                for ext in ("-wal", "-shm"):
                    w = f.with_name(f.name + ext)
                    if w.exists(): shutil.copy(w, tmp / ("p.sqlite" + ext))
                con = sqlite3.connect(str(tmp / "p.sqlite"))
                for t, u in con.execute("SELECT b.title, p.url FROM moz_bookmarks b JOIN moz_places p ON b.fk = p.id WHERE b.type = 1 AND p.url NOT LIKE 'place:%'"):
                    out.append((t or u, u))
                con.close(); shutil.rmtree(tmp, ignore_errors=True)
            elif f.name == "quickmarks":
                for l in f.read_text().splitlines():
                    parts = l.rsplit(" ", 1)
                    if len(parts) == 2: out.append((parts[0], parts[1]))
            elif f.name == "urls":
                for l in f.read_text().splitlines():
                    parts = l.split(" ", 1)
                    if parts and parts[0].startswith("http"): out.append((parts[1] if len(parts) > 1 else parts[0], parts[0]))
        except Exception:
            continue
    seen = set(); items = []
    for t, u in out:
        if u and u not in seen: seen.add(u); items.append((t, u))
    _BM["sig"] = sig; _BM["items"] = items
    return items

def bookmark_items(q):
    if len(q) < 3: return []
    out = []
    for t, u in load_bookmarks():
        sc = max(match(q, t), match(q, u) * 0.6)
        if sc >= 60:
            out.append(Item("Bookmark", t[:100], u[:120], "user-bookmarks", 28 + sc * 0.5, run=lambda u=u: spawn(["xdg-open", u]), alt=lambda u=u: u, key="bm:" + u))
    out.sort(key=lambda i: -i.score)
    return out[:4]

# ---- Zotero library (title, first author, year); Enter opens the item in Zotero, Ctrl+Y previews its PDF
_ZOT = {"sig": None, "path": None}
def zotero_items(q):
    import sqlite3, shutil
    db = None
    for c in (HOME / "Zotero/zotero.sqlite", HOME / ".zotero/zotero.sqlite"):
        if c.exists(): db = c; break
    if db is None or len(q) < 3: return []
    sig = int(db.stat().st_mtime); cache = STATE / "zotero.sqlite"
    if _ZOT["sig"] != sig:
        shutil.copy(db, cache); _ZOT["sig"] = sig
    con = sqlite3.connect(str(cache)); out = []
    try:
        rows = con.execute("""
            SELECT i.itemID, i.key, v.value,
                   (SELECT c.lastName FROM itemCreators ic JOIN creators c ON ic.creatorID = c.creatorID WHERE ic.itemID = i.itemID ORDER BY ic.orderIndex LIMIT 1),
                   (SELECT substr(v2.value, 1, 4) FROM itemData d2 JOIN itemDataValues v2 ON d2.valueID = v2.valueID JOIN fields f2 ON d2.fieldID = f2.fieldID
                     WHERE d2.itemID = i.itemID AND f2.fieldName = 'date')
            FROM items i JOIN itemData d ON d.itemID = i.itemID JOIN fields f ON d.fieldID = f.fieldID AND f.fieldName = 'title'
                 JOIN itemDataValues v ON d.valueID = v.valueID
            WHERE i.itemID NOT IN (SELECT itemID FROM deletedItems) AND v.value LIKE ? ESCAPE '\\' LIMIT 40""",
            ("%" + q.replace("%", "").replace("_", " ") + "%",)).fetchall()
        for iid, key, title, author, year in rows:
            att = con.execute("SELECT a.path, k.key FROM itemAttachments a JOIN items k ON a.itemID = k.itemID WHERE a.parentItemID = ? AND a.path LIKE 'storage:%' LIMIT 1", (iid,)).fetchone()
            pdf = (db.parent / "storage" / att[1] / att[0][len("storage:"):]) if att else None
            sub = " · ".join(x for x in (author, year, "PDF attached" if pdf and pdf.exists() else "") if x) or "Zotero"
            out.append(Item("Zotero", title[:110], sub, "accessories-dictionary", 40 + match(q, title) * 0.4,
                            run=lambda k=key: spawn(["xdg-open", f"zotero://select/library/items/{k}"]),
                            alt=(lambda p=pdf: str(p)) if pdf and pdf.exists() else (lambda t=title: t), key="zot:" + key))
    except Exception:
        out = []
    con.close()
    return sorted(out, key=lambda i: -i.score)[:4]

def last_backup_hint():
    try: ts = float((STATE / "last-backup").read_text())
    except Exception: return None
    days = (time.time() - ts) / 86400
    return int(days) if days >= 7 else None

def search(q):
    q = q.strip()
    if q.startswith(">"):
        cmd = q[1:].strip()
        return [Item("Run", cmd or "type a command", "Enter runs it · Ctrl+Enter in a terminal", "utilities-terminal", 1000,
                     run=(lambda: spawn(["sh", "-lc", cmd])) if cmd else None,
                     reveal=(lambda: spawn(["kitty", "sh", "-lc", cmd + "; read -rp 'done> '"])) if cmd else None)]
    ai = alarm_items(q)
    if ai: return ai
    flt, rest = split_filters(q)
    if flt:
        try: return filtered_files(flt, rest)
        except Exception: return []
    if q.startswith(":") and len(q) > 1:
        try: return emoji_items(q[1:].strip())
        except Exception: return []
    mh = re.match(r"^(h|hist|history)\s+(.*)$", q) if " " in q else None
    if mh or q in ("h", "hist", "history"):
        return history_items(mh.group(2) if mh else "")
    if re.match(r"^c(lip)?\s", q) or q in ("c", "clip"):
        return clip_for(q.split(None, 1)[1] if " " in q else "")
    if re.match(r"^w\s", q) or q == "w":
        return sorted(windows_for(q[2:].strip(), only=True), key=lambda i: -i.score)[:MAXROWS]
    items = calc_for(q) + apps_for(q) + windows_for(q) + actions_for(q) + files_for(q) + web_for(q)
    for src in (alias_items, app_action_items, bookmark_items, zotero_items):
        try: items += src(q)
        except Exception: pass
    if len(q) >= 3 and not any(i.kind in ("File", "Folder", "Recent") for i in items):
        items.append(Item("Deep", f"Search inside documents for “{q}”", "Looks inside your notes, PDFs and text files  ·  press Enter  ·  the first search builds a PDF text cache and is slower",
                          "system-search", -50, key="deep:" + q))
    items.sort(key=lambda i: -i.score)
    return items[:MAXROWS]

# ---------------------------------------------------------------- deep search (inside documents)
def deep_roots():
    f = HOME / ".config/spotlight/roots"
    try:
        r = [Path(os.path.expanduser(l.strip())) for l in f.read_text().splitlines() if l.strip() and not l.startswith("#")]
        r = [p for p in r if p.exists()]
        if r: return r
    except Exception:
        pass
    return [p for p in (HOME / "notes", HOME / "Documents") if p.exists()]

def deep_items(q):
    cmd = ["rg", "--no-heading", "--with-filename", "--line-number", "--max-count", "1", "--max-columns", "240", "--max-columns-preview",
           "-i", "-F", "--pre", str(SCRIPTS / "rg-pre.sh"), "--pre-glob", "*.pdf",
           "-g", "*.{md,txt,tex,pdf,org,rst,bib,csv,html,ipynb,qmd,R,py}",
           "-g", "!{node_modules,.git,site-packages,__pycache__,.venv,venv,.obsidian,.trash}", "--", q] + [str(r) for r in deep_roots()]
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=40).stdout
    except Exception:
        out = ""
    items = []
    for line in out.splitlines():
        m = re.match(r"^(.*?):(\d+):(.*)$", line)
        if not m: continue
        p, ln, text = m.group(1), m.group(2), m.group(3).strip()
        if not os.path.exists(p): continue
        sub = (text[:110] if not p.lower().endswith(".pdf") else text[:110]) or os.path.dirname(p)
        items.append(Item("Match", os.path.basename(p), f"{sub}   ·   {os.path.dirname(p).replace(str(HOME), '~')}",
                          Gio.content_type_get_icon(Gio.content_type_guess(p, None)[0]), 0,
                          run=lambda p=p: spawn(["xdg-open", p]), alt=lambda p=p: p,
                          reveal=lambda p=p: spawn(["xdg-open", os.path.dirname(p)])))
        if len(items) >= 12: break
    return items

# ---------------------------------------------------------------- UI
# ---------------------------------------------------------------- appearance: light / dark / follow the night schedule, and the accent colour
def is_dark():
    mode = setting("APPEARANCE", "light")
    if mode == "dark": return True
    if mode != "schedule": return False
    try: a = int(setting("NIGHT_START", "19")); b = int(setting("NIGHT_END", "7"))
    except ValueError: a, b = 19, 7
    h = time.localtime().tm_hour
    return (h >= a or h < b) if a > b else (a <= h < b)

def accent_hex():
    m = setting("ACCENT_MODE", "amber")
    if m == "custom":
        v = setting("ACCENT_HEX", "")
        if re.match(r"^#[0-9a-fA-F]{6}$", v): return v
    if m == "wallpaper":
        try:
            v = (HOME / ".cache/accent-wallpaper").read_text().strip()
            if re.match(r"^#[0-9a-fA-F]{6}$", v): return v
        except Exception: pass
    return "#c47f1c"

def _rgb(h): return int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16)

def themed(css, alpha, dark, acc):
    """css is written in the light palette with the amber accent; swap colours for dark mode and for another accent."""
    r, g, b = _rgb(acc)
    if dark:
        for a, c in (("rgba(238,233,224,__ALPHA__)", "rgba(31,28,25,__ALPHA__)"), ("rgba(60,45,20,0.16)", "rgba(255,255,255,0.10)"), ("rgba(60,45,20,0.14)", "rgba(255,255,255,0.10)"),
                     ("rgba(60,45,20,0.10)", "rgba(255,236,210,0.13)"), ("#2a251e", "#f6efe4"), ("#7d7466", "#a39685"), ("#7b7164", "#a39685"), ("#8d8274", "#8d8274"),
                     ("#8a6a2e", "#d9a95a")):
            css = css.replace(a.encode(), c.encode())
        caret = "#%02x%02x%02x" % tuple(min(255, int(x * 1.18 + 20)) for x in (r, g, b))
    else:
        caret = "#%02x%02x%02x" % tuple(int(x * 0.92) for x in (r, g, b))
    css = css.replace(b"#b86f12", caret.encode()).replace(b"rgba(196,127,28,0.35)", f"rgba({r},{g},{b},0.35)".encode())
    return css.replace(b"__ALPHA__", f"{alpha:.2f}".encode())

def scope(css, cls):
    """Prefix every rule with .cls so the styles of this window cannot leak into the Settings window (they share one process)."""
    out = []
    for m in re.finditer(rb"([^{}]+)\{([^{}]*)\}", css):
        new = []
        for sel in (x.strip() for x in m.group(1).split(b",")):
            new.append(b"window." + cls + sel[6:] if sel.startswith(b"window") else b"." + cls + b" " + sel)
        out.append(b", ".join(new) + b" {" + m.group(2) + b"}")
    return b"\n".join(out)

CSS = b"""
window { background-color: rgba(238,233,224,__ALPHA__); border: 1px solid rgba(60,45,20,0.16); border-radius: 26px; }
.bar { padding: 8px 26px 4px 26px; }
entry { background: transparent; color: #2a251e; font-size: 25pt; font-weight: 300; border: none; box-shadow: none; padding: 12px 6px; caret-color: #b86f12; min-height: 54px; }
entry selection { background: rgba(196,127,28,0.35); color: #2a251e; }
.mag { color: #7b7164; }
separator { background: rgba(60,45,20,0.14); min-height: 1px; margin: 0 22px; }
list { background: transparent; padding: 10px 14px 14px 14px; }
row { padding: 9px 14px; border-radius: 14px; }
row:selected { background: rgba(60,45,20,0.10); }
.t { color: #2a251e; font-size: 14pt; }
.big { font-size: 24pt; font-weight: 300; }
.s { color: #7d7466; font-size: 10.5pt; }
.n { color: transparent; font-size: 9pt; }
row:selected .n { color: #8d8274; }
.empty { color: #7d7466; font-size: 12pt; padding: 18px 26px; }
.head { color: #7d7466; font-size: 10pt; font-weight: bold; padding: 12px 26px 4px 26px; }
.tiles { padding: 4px 16px 8px 16px; }
.allbtn { color: #7d7466; font-size: 10pt; padding: 12px 26px 4px 26px; }
flowbox { background: transparent; padding: 4px 14px 10px 14px; }
.tile { padding: 12px 6px 8px 6px; border-radius: 16px; }
.alltile { padding: 16px 6px 12px 6px; }
.alltile .tl { font-size: 12.5pt; }
.hint { color: #8a6a2e; font-size: 10pt; padding: 8px 26px 6px 26px; }
.foot { color: #8d8274; font-size: 9.5pt; padding: 2px 26px 12px 26px; }
.pvname { color: #2a251e; font-size: 14pt; padding: 6px 26px 2px 26px; }
.pvmeta { color: #7d7466; font-size: 10pt; padding: 0 26px 8px 26px; }
textview, textview text { background: transparent; color: #2a251e; font-family: monospace; font-size: 10.5pt; }
.tile.sel { background: rgba(60,45,20,0.10); }
.tl { color: #2a251e; font-size: 11pt; }
.frow { padding: 8px 14px; border-radius: 14px; margin: 0 14px; }
.frow.sel { background: rgba(60,45,20,0.10); }
"""

def when(ts):
    d = time.localtime(ts); now = time.localtime()
    days = (time.mktime(now[:3] + (0,) * 6) - time.mktime(d[:3] + (0,) * 6)) / 86400
    hm = time.strftime("%H:%M", d)
    if days < 1: return f"Today, {hm}"
    if days < 2: return f"Yesterday, {hm}"
    return time.strftime("%d %b %Y", d)

def file_meta(p):
    try:
        st = os.stat(p)
    except Exception:
        return ""
    ct = Gio.content_type_guess(p, None)[0]
    if os.path.isdir(p): kind = "Folder"
    elif ct == "application/octet-stream" or ct.startswith("inode/"):
        ext = os.path.splitext(p)[1].lstrip(".")
        kind = f"{ext.upper()} file" if ext else "Document"
    else: kind = Gio.content_type_get_description(ct)
    size = "" if os.path.isdir(p) else " · " + GLib.format_size(st.st_size)
    return f"{kind}{size} · {when(st.st_mtime)}"

def setting(key, default):
    try:
        for l in (HOME / ".config/rog/settings.env").read_text().splitlines():
            if l.startswith(key + "="):
                return l.split("=", 1)[1].strip().strip('"')
    except Exception:
        pass
    return default

def recent_apps(n=4):
    out = []
    byid = {aid: (a, name) for a, name, desc, kw, aid in APPS}
    for key, (cnt, last) in sorted(HISTORY.items(), key=lambda kv: -kv[1][1]):
        if key.startswith("app:") and key[4:] in byid:
            a, name = byid[key[4:]]
            out.append(Item("App", name, "", a.get_icon(), 0, run=lambda a=a: launch_app(a), key=key))
        if len(out) >= n: break
    return out

def recent_file_items(n=4):
    seen, out = set(), []
    hist = [k[5:] for k, v in sorted(HISTORY.items(), key=lambda kv: -kv[1][1]) if k.startswith("file:")]
    for p in hist + [i.alt() for i in recent_files_all()]:
        if p in seen or not os.path.exists(p) or any(j in p for j in JUNK): continue
        seen.add(p)
        out.append(Item("File", os.path.basename(p) or p, file_meta(p) + "  ·  " + os.path.dirname(p).replace(str(HOME), "~"),
                        Gio.content_type_get_icon(Gio.content_type_guess(p, None)[0]), 0, run=lambda p=p: spawn(["xdg-open", p]),
                        alt=lambda p=p: p, reveal=lambda p=p: spawn(["xdg-open", os.path.dirname(p)]), key="file:" + p))
        if len(out) >= n: break
    return out

def recent_files_all():
    global MAXRECENT
    return recent_files(limit=12)

class Spot(Gtk.Window):
    def __init__(self, daemon=False):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.daemon = daemon
        self.get_style_context().add_class("spotlight")
        self.set_wmclass("spotlight", "Spotlight")
        self.set_title("Spotlight")
        self.set_decorated(False)
        self.cur_w = 860; self.set_size_request(860, -1)
        self.set_resizable(False)
        self.set_opacity(0.0)                               # stay invisible until placed: no first-frame garbage, no jump
        scr = self.get_screen(); vis = scr.get_rgba_visual()
        if vis: self.set_visual(vis)
        self.prov = Gtk.CssProvider(); self.alpha = None; self.apply_alpha()
        Gtk.StyleContext.add_provider_for_screen(scr, self.prov, Gtk.STYLE_PROVIDER_PRIORITY_USER)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL); self.add(box)
        bar = Gtk.Box(spacing=12); bar.get_style_context().add_class("bar")
        mag = Gtk.Image.new_from_icon_name("system-search-symbolic", Gtk.IconSize.DND); mag.set_pixel_size(30)
        mag.get_style_context().add_class("mag"); bar.pack_start(mag, False, False, 0)
        self.entry = Gtk.Entry(); self.entry.set_placeholder_text("Spotlight Search"); self.entry.set_has_frame(False)
        bar.pack_start(self.entry, True, True, 0)
        box.pack_start(bar, False, False, 0)
        self.sep = Gtk.Separator(); box.pack_start(self.sep, False, False, 0)
        self.home = Gtk.Box(orientation=Gtk.Orientation.VERTICAL); box.pack_start(self.home, False, False, 0)
        self.list = Gtk.ListBox(); self.list.set_selection_mode(Gtk.SelectionMode.SINGLE); self.list.set_activate_on_single_click(True)
        box.pack_start(self.list, False, False, 0)
        self.footer = Gtk.Label(label="Ctrl+Y preview   ·   Ctrl+Enter reveal or run in terminal   ·   Ctrl+C copy   ·   Alt+A all apps", xalign=0)
        self.footer.get_style_context().add_class("foot"); box.pack_start(self.footer, False, False, 0)
        self.items = []; self.timer = 0; self.focused = False; self.deep_q = None
        self.home_items = []; self.home_widgets = []; self.home_sel = 0; self.mode = "list"; self.revealed = False
        self.chg = self.entry.connect("changed", self.on_changed)
        self.connect("key-press-event", self.on_key)
        self.connect("key-release-event", self.on_key_release)
        self.space_down = False; self.space_timer = 0; self.space_peek = False
        self.connect("focus-in-event", lambda *a: setattr(self, "focused", True))
        self.connect("focus-out-event", self.on_focus_out)
        self.connect("map-event", self.on_map)
        self.connect_after("draw", self.on_draw)
        self.placed = self.drawn = False
        self.list.connect("row-activated", lambda lb, row: self.activate(row.get_index(), 0))
        if not daemon: self.connect("destroy", Gtk.main_quit)
        self.show_home()

    # ---- placement: fixed distance from the top, centred, revealed only after i3 has put it there
    def set_width(self, w):
        changed = (w != self.cur_w); self.cur_w = w
        self.set_size_request(w, -1); self.resize(w, 1)
        if changed and self.get_mapped(): GLib.timeout_add(60, self.recenter)

    def recenter(self):                                    # the box is anchored at its top-left: keep it centred after a width change
        try:
            d = Gdk.Display.get_default(); mon = d.get_primary_monitor() or d.get_monitor(0); g = mon.get_geometry()
            w, h = self.get_size()
            subprocess.run(["i3-msg", f'[class="^Spotlight$"] move absolute position {g.x + (g.width - w) // 2} px {g.y + int(g.height * 0.15)} px'], capture_output=True, timeout=2)
        except Exception:
            pass
        return False

    def _showall(self):
        # a resident (hidden) window must not be mapped by building its content: only show the children until present_fresh() maps it
        if self.daemon and not self.get_visible(): self.get_child().show_all()
        else: self.show_all()

    def on_map(self, *a):
        self.placed = False; self.drawn = False
        GLib.idle_add(self.place)

    def on_draw(self, *a):                                 # first real paint after a map: the window is ARGB, so showing it earlier = a blurred blank box
        if not self.drawn:
            self.drawn = True; self.maybe_reveal()
        return False

    def maybe_reveal(self):
        if self.placed and self.drawn and not self.revealed:
            GLib.timeout_add(14, self.reveal)

    def place(self):
        try:
            d = Gdk.Display.get_default(); mon = d.get_primary_monitor() or d.get_monitor(0); g = mon.get_geometry()
            w, h = self.get_size()
            x = g.x + (g.width - w) // 2; y = g.y + int(g.height * 0.15)
            subprocess.run(["i3-msg", f'[class="^Spotlight$"] move absolute position {x} px {y} px'], capture_output=True, timeout=2)
        except Exception:
            pass
        self.placed = True; self.maybe_reveal()
        return False

    def reveal(self):
        self.set_opacity(1.0); self.revealed = True
        return False

    def on_focus_out(self, *a):
        if self.focused:
            GLib.timeout_add(150, self.close_if_unfocused)

    def close_if_unfocused(self):
        if not self.is_active():
            self.dismiss()
        return False

    def dismiss(self):
        if not self.daemon:
            self.destroy(); return
        try:                                               # a resident process that has grown past 150 MB restarts itself (the clipboard history is on disk)
            rss = int(open("/proc/self/statm").read().split()[1]) * os.sysconf("SC_PAGE_SIZE") / 1e6
            if rss > 150: GLib.idle_add(lambda: os.execv(sys.executable, [sys.executable, os.path.abspath(__file__), "--daemon"]))
        except Exception: pass
        if self.timer:
            GLib.source_remove(self.timer); self.timer = 0
        self.deep_q = None; self.focused = False; self.revealed = False
        self.set_opacity(0.0); self.hide()

    def apply_alpha(self):                                 # (name kept) alpha from the Settings slider, light/dark, accent
        try: a = max(0.30, min(1.0, float(setting("SPOT_OPACITY", "62")) / 100))
        except ValueError: a = 0.62
        key = (a, is_dark(), accent_hex())
        if key != self.alpha:                              # only re-style when something changed
            self.alpha = key
            self.prov.load_from_data(scope(themed(CSS, key[0], key[1], key[2]), b"spotlight"))

    def present_fresh(self):                               # resident mode: show again from a clean state
        self.apply_alpha()
        if self.timer:
            GLib.source_remove(self.timer); self.timer = 0
        self.deep_q = None
        self.entry.handler_block(self.chg); self.entry.set_text(""); self.entry.handler_unblock(self.chg)
        self.show_home()
        self.focused = False; self.set_opacity(0.0)
        self.show(); self.present(); self.entry.grab_focus()

    def on_changed(self, *a):
        self.deep_q = None
        if self.timer:
            GLib.source_remove(self.timer)
        self.timer = GLib.timeout_add(90, self.refresh)   # debounce: search once typing pauses

    def refresh(self):
        self.timer = 0
        q = self.entry.get_text().strip()
        if not q:
            self.show_home(); return False
        if re.match(r"^/\s*\S", q):                        # "/ phrase" goes straight to the deep search
            self.start_deep(q[1:].strip()); return False
        self.render(search(q), q)
        return False

    # ---- empty state: recent apps as a grid, recent files as a list (4 each)
    def clear_home(self):
        for c in self.home.get_children(): self.home.remove(c)
        self.home_items, self.home_widgets, self.home_sel = [], [], 0

    def show_home(self):
        self.mode = "home"
        for c in self.list.get_children(): self.list.remove(c)
        self.items = []; self.clear_home()
        if setting("SPOT_RECENTS", "1") == "1":
            apps, files = recent_apps(4), recent_file_items(4)
            if apps:
                hb = Gtk.Box(); h = Gtk.Label(label="Recent apps", xalign=0); h.get_style_context().add_class("head"); hb.pack_start(h, True, True, 0)
                ev0 = Gtk.EventBox(); sa = Gtk.Label(label="Show all  (Alt+A)", xalign=1); sa.get_style_context().add_class("allbtn"); ev0.add(sa)
                ev0.connect("button-press-event", lambda w, e: self.show_all_apps()); hb.pack_end(ev0, False, False, 0)
                self.home.pack_start(hb, False, False, 0)
                row = Gtk.Box(homogeneous=True, spacing=6); row.get_style_context().add_class("tiles")
                for it in apps:
                    ev = Gtk.EventBox(); v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6); v.get_style_context().add_class("tile")
                    img = Gtk.Image.new_from_gicon(it.icon, Gtk.IconSize.DIALOG) if it.icon else Gtk.Image.new_from_icon_name("application-x-executable", Gtk.IconSize.DIALOG)
                    img.set_pixel_size(52); v.pack_start(img, False, False, 0)
                    l = Gtk.Label(label=it.title); l.set_ellipsize(Pango.EllipsizeMode.END); l.set_max_width_chars(16); l.get_style_context().add_class("tl")
                    v.pack_start(l, False, False, 0); ev.add(v)
                    idx = len(self.home_items)
                    ev.connect("button-press-event", lambda w, e, i=idx: self.activate_home(i))
                    row.pack_start(ev, True, True, 0); self.home_items.append(it); self.home_widgets.append(v)
                self.home.pack_start(row, False, False, 0)
            if files:
                h = Gtk.Label(label="Recent files", xalign=0); h.get_style_context().add_class("head"); self.home.pack_start(h, False, False, 0)
                for it in files:
                    ev = Gtk.EventBox(); r = self.make_row(it, 99); r.get_style_context().add_class("frow"); ev.add(r)
                    idx = len(self.home_items)
                    ev.connect("button-press-event", lambda w, e, i=idx: self.activate_home(i))
                    self.home.pack_start(ev, False, False, 0); self.home_items.append(it); self.home_widgets.append(r)
                sp = Gtk.Box(); sp.set_size_request(-1, 10); self.home.pack_start(sp, False, False, 0)
        has = bool(self.home_items)
        dd = last_backup_hint() if setting("SPOT_RECENTS", "1") == "1" else None
        if dd is not None:
            ev = Gtk.EventBox(); lb = Gtk.Label(label=f"Your last backup was {dd} days ago  —  click to back up", xalign=0); lb.get_style_context().add_class("hint"); ev.add(lb)
            ev.connect("button-press-event", lambda w, e: (spawn([str(SCRIPTS / "rog-ui.sh"), "backup"]), self.dismiss())); self.home.pack_start(ev, False, False, 0); has = True
        self._showall()
        self.sep.set_visible(has); self.home.set_visible(has); self.list.set_visible(False); self.footer.set_visible(False)
        self.paint_home()
        self.set_width(860)

    # ---- browse every installed app (alphabetical grid); typing still searches
    def show_all_apps(self):
        self.mode = "all"
        for c in self.list.get_children(): self.list.remove(c)
        self.items = []; self.clear_home()
        hb = Gtk.Box(); h = Gtk.Label(label="All apps", xalign=0); h.get_style_context().add_class("head"); hb.pack_start(h, True, True, 0)
        ev0 = Gtk.EventBox(); bk = Gtk.Label(label="Back  (Esc)", xalign=1); bk.get_style_context().add_class("allbtn"); ev0.add(bk)
        ev0.connect("button-press-event", lambda w, e: self.show_home()); hb.pack_end(ev0, False, False, 0)
        self.home.pack_start(hb, False, False, 0)
        sc = Gtk.ScrolledWindow(); sc.set_min_content_height(560); sc.set_max_content_height(560); sc.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        fb = Gtk.FlowBox(); fb.set_selection_mode(Gtk.SelectionMode.NONE); fb.set_homogeneous(True)
        fb.set_min_children_per_line(4); fb.set_max_children_per_line(4); fb.set_column_spacing(6); fb.set_row_spacing(4)
        for a, name, desc, kw, aid in sorted(APPS, key=lambda t: t[1].lower()):
            it = Item("App", name, "", a.get_icon(), 0, run=lambda a=a: launch_app(a), key="app:" + aid)
            ev = Gtk.EventBox(); v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6); v.get_style_context().add_class("tile"); v.get_style_context().add_class("alltile")
            img = Gtk.Image.new_from_gicon(it.icon, Gtk.IconSize.DIALOG) if it.icon else Gtk.Image.new_from_icon_name("application-x-executable", Gtk.IconSize.DIALOG)
            img.set_pixel_size(64); v.pack_start(img, False, False, 0)
            l = Gtk.Label(label=name); l.set_ellipsize(Pango.EllipsizeMode.END); l.set_max_width_chars(18); l.get_style_context().add_class("tl")
            v.pack_start(l, False, False, 0); ev.add(v)
            idx = len(self.home_items)
            ev.connect("button-press-event", lambda w, e, i=idx: self.activate_home(i))
            fb.add(ev); self.home_items.append(it); self.home_widgets.append(v)
        sc.add(fb); self.home.pack_start(sc, False, False, 0)
        self.all_scroll = sc; self.all_flow = fb
        self.show_all() if not (self.daemon and not self.get_visible()) else self.get_child().show_all()
        self.sep.set_visible(True); self.home.set_visible(True); self.list.set_visible(False); self.footer.set_visible(False)
        self.set_width(1000); self.paint_home()

    def scroll_to_selected(self):
        if self.mode != "all" or not self.home_widgets: return
        w = self.home_widgets[self.home_sel]
        r = w.translate_coordinates(self.all_flow, 0, 0)           # (x, y), or None before the first layout
        if r:
            adj = self.all_scroll.get_vadjustment(); adj.clamp_page(r[1] - 6, r[1] + w.get_allocated_height() + 6)

    # ---- Quick-Look style preview of the selected file (Ctrl+Y)
    def item_path(self, it):
        try:
            p = it.alt() if it.alt else None
            return p if p and os.path.exists(p) else None
        except Exception:
            return None

    def show_preview(self):
        row = self.list.get_selected_row()
        if not row or not (0 <= row.get_index() < len(self.items)): return
        idx = row.get_index(); it = self.items[idx]; p = self.item_path(it)
        if not p:
            return
        self.prev = (list(self.items), self.entry.get_text().strip(), idx)
        self.mode = "preview"
        for c in self.list.get_children(): self.list.remove(c)
        self.clear_home()
        nm = Gtk.Label(label=os.path.basename(p) or p, xalign=0); nm.set_ellipsize(Pango.EllipsizeMode.MIDDLE); nm.get_style_context().add_class("pvname"); self.home.pack_start(nm, False, False, 0)
        mt = Gtk.Label(label=file_meta(p) + "   ·   Esc or Ctrl+Y goes back   ·   Enter opens", xalign=0); mt.get_style_context().add_class("pvmeta"); self.home.pack_start(mt, False, False, 0)
        sc = Gtk.ScrolledWindow(); sc.set_min_content_height(520); sc.set_max_content_height(520); sc.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        sc.add(self.preview_widget(p)); self.pv_scroll = sc; self.pv_path = p
        self.home.pack_start(sc, False, False, 0)
        self._showall()
        self.sep.set_visible(True); self.home.set_visible(True); self.list.set_visible(False); self.footer.set_visible(False)
        self.set_width(1000)

    def leave_preview(self):
        items, q, idx = self.prev
        self.render(items, q)
        r = self.list.get_row_at_index(idx)
        if r: self.list.select_row(r)

    def preview_widget(self, p):
        from gi.repository import GdkPixbuf
        mime = Gio.content_type_guess(p, None)[0] or ""
        low = p.lower()
        try:
            if os.path.isdir(p):
                names = sorted(os.listdir(p), key=str.lower)[:200]
                txt = "\n".join((n + ("/" if os.path.isdir(os.path.join(p, n)) else "")) for n in names) or "(empty folder)"
                return self.text_view(txt)
            if mime.startswith("image/"):
                pix = GdkPixbuf.Pixbuf.new_from_file_at_size(p, 960, 560)
                return Gtk.Image.new_from_pixbuf(pix)
            if mime == "application/pdf" or low.endswith(".pdf"):
                out = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "spotlight-preview"
                subprocess.run(["pdftoppm", "-png", "-r", "80", "-f", "1", "-l", "1", "-singlefile", p, str(out)], capture_output=True, timeout=8)
                img = out.with_suffix(".png")
                if img.exists():
                    pix = GdkPixbuf.Pixbuf.new_from_file_at_size(str(img), 960, 3000); img.unlink()
                    return Gtk.Image.new_from_pixbuf(pix)
            textish = mime.startswith("text/") or low.endswith((".md", ".tex", ".bib", ".py", ".json", ".csv", ".yaml", ".yml", ".toml", ".conf", ".ini",
                                                                 ".sh", ".rs", ".c", ".h", ".js", ".ts", ".html", ".css", ".log", ".org", ".rst", ".ipynb", ".qmd", ".r"))
            if textish:
                with open(p, "rb") as f: data = f.read(60000)
                return self.text_view(data.decode("utf-8", "replace"))
        except Exception as e:
            return self.text_view(f"Cannot preview this file ({e}).")
        return self.text_view(f"{file_meta(p)}\n\nNo preview for this kind of file. Press Enter to open it.")

    def text_view(self, txt):
        tv = Gtk.TextView(); tv.set_editable(False); tv.set_cursor_visible(False); tv.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        tv.set_left_margin(26); tv.set_right_margin(26); tv.set_top_margin(8); tv.get_buffer().set_text(txt); return tv

    def paint_home(self):
        for i, w in enumerate(self.home_widgets):
            ctx = w.get_style_context()
            (ctx.add_class if i == self.home_sel else ctx.remove_class)("sel")
        self.scroll_to_selected()

    def activate_home(self, i, mode=0):
        if 0 <= i < len(self.home_items):
            self.run_item(self.home_items[i], mode)

    # ---- results
    def render(self, found, q, note=None):
        self.mode = "list"
        self.clear_home(); self.home.set_visible(False)
        for c in self.list.get_children():
            self.list.remove(c)
        self.items = list(found)
        for n, it in enumerate(self.items):
            row = Gtk.ListBoxRow(); row.add(self.make_row(it, n)); self.list.add(row)
        if note or (q and not self.items):
            lab = Gtk.Label(label=note or "No results", xalign=0); lab.get_style_context().add_class("empty")
            r = Gtk.ListBoxRow(); r.set_selectable(False); r.set_activatable(False); r.add(lab); self.list.add(r)
        self._showall()
        vis = bool(self.items or q or note)
        self.sep.set_visible(vis); self.list.set_visible(vis); self.home.set_visible(False)
        self.footer.set_visible(bool(self.items) and self.mode == "list")
        if self.items:
            self.list.select_row(self.list.get_row_at_index(0))
        self.set_width(860)

    def start_deep(self, q):
        import threading
        self.deep_q = q
        self.render([], q, f"Searching inside documents for “{q}”…")
        def work():
            res = deep_items(q)
            GLib.idle_add(self.show_deep, q, res)
        threading.Thread(target=work, daemon=True).start()

    def show_deep(self, q, res):
        if self.deep_q == q:                               # I may have typed on since
            self.render(res, q, None if res else f"Nothing inside your documents matches “{q}”")
        return False

    def make_row(self, it, n):
        h = Gtk.Box(spacing=16)
        if isinstance(it.icon, str) and it.icon:
            img = Gtk.Image.new_from_icon_name(it.icon, Gtk.IconSize.DND)
        elif it.icon is not None and it.icon.__class__.__name__ == "Pixbuf":
            img = Gtk.Image.new_from_pixbuf(it.icon)
        elif it.icon:
            img = Gtk.Image.new_from_gicon(it.icon, Gtk.IconSize.DND)
        else:
            img = Gtk.Image.new_from_icon_name("application-x-executable", Gtk.IconSize.DND)
        if it.icon is None or it.icon.__class__.__name__ != "Pixbuf": img.set_pixel_size(40)
        h.pack_start(img, False, False, 0)
        v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL); v.set_valign(Gtk.Align.CENTER)
        t = Gtk.Label(label=it.title, xalign=0); t.set_ellipsize(Pango.EllipsizeMode.END); t.set_max_width_chars(52)
        t.get_style_context().add_class("t")
        if it.kind == "Calc": t.get_style_context().add_class("big")
        v.pack_start(t, False, False, 0)
        if it.sub:
            s = Gtk.Label(label=it.sub, xalign=0); s.set_ellipsize(Pango.EllipsizeMode.MIDDLE); s.set_max_width_chars(80); s.get_style_context().add_class("s")
            v.pack_start(s, False, False, 0)
        h.pack_start(v, True, True, 0)
        if n < 9:
            nn = Gtk.Label(label=f"Alt+{n+1}", xalign=1); nn.get_style_context().add_class("n"); h.pack_end(nn, False, False, 6)
        return h

    def move(self, d):
        if self.mode in ("home", "all"):
            if self.home_items:
                self.home_sel = (self.home_sel + d) % len(self.home_items); self.paint_home()
            return
        if not self.items:
            return
        cur = self.list.get_selected_row(); i = cur.get_index() if cur else -1
        self.list.select_row(self.list.get_row_at_index((i + d) % len(self.items)))

    def vmove(self, d):                                    # up/down in the home view: grid row <-> file list
        if not self.home_items: return
        napps = sum(1 for it in self.home_items if it.kind == "App")
        if d > 0 and self.home_sel < napps and len(self.home_items) > napps: self.home_sel = napps
        elif d > 0: self.home_sel = min(len(self.home_items) - 1, self.home_sel + 1) if self.home_sel >= napps else self.home_sel
        elif d < 0 and self.home_sel == napps and napps: self.home_sel = 0
        elif d < 0 and self.home_sel > napps: self.home_sel -= 1
        self.paint_home()

    def run_item(self, it, mode):
        if it.kind == "Deep":                              # ask-first deep search: stay open and show the matches
            self.start_deep(it.key[5:]); return
        fn = it.run
        if mode == 1 and it.reveal: fn = it.reveal
        if mode == 2 and it.alt:                           # one copy key for everything: a file copies as the file itself, anything else as its text
            fp = self.item_path(it) if it.kind in ("File", "Folder", "Recent", "Match") else None
            if fp: fn = lambda: copy_file(fp)
            else: txt = it.alt(); fn = lambda: copy(txt)
        if not fn:
            return
        if it.key and not it.key.startswith("deep:"): bump(it.key)
        fn()
        self.dismiss()

    def activate(self, i, mode):
        if 0 <= i < len(self.items):
            self.run_item(self.items[i], mode)

    # ---- hold Space = peek at the selected file (like macOS Quick Look); a quick tap still types a space
    def previewable_selection(self):
        if self.mode != "list": return False
        row = self.list.get_selected_row()
        if not row or not (0 <= row.get_index() < len(self.items)): return False
        return self.item_path(self.items[row.get_index()]) is not None

    def insert_space(self):
        t = self.entry.get_text(); p = self.entry.get_position()
        self.entry.set_text(t[:p] + " " + t[p:]); self.entry.set_position(p + 1)

    def space_fire(self):
        self.space_timer = 0
        if self.space_down and self.previewable_selection():
            self.space_peek = True; self.show_preview()
        elif self.space_down:                              # nothing to preview: it was just a slow space
            self.space_down = False; self.insert_space()
        return False

    def flush_space(self):                                 # another key arrived while Space was pending: type the space first, keep order
        if self.space_timer: GLib.source_remove(self.space_timer); self.space_timer = 0
        if self.space_down and not self.space_peek: self.insert_space()
        self.space_down = False

    def on_key_release(self, w, e):
        if e.keyval == Gdk.KEY_space and self.space_down:
            if self.space_timer: GLib.source_remove(self.space_timer); self.space_timer = 0
            if self.space_peek and self.mode == "preview": self.leave_preview()
            else: self.insert_space()                      # released before the threshold: an ordinary space
            self.space_down = False; self.space_peek = False
            return True
        return False

    def on_key(self, w, e):
        k = e.keyval; st = e.state & Gtk.accelerator_get_default_mod_mask()
        ctrl = bool(st & Gdk.ModifierType.CONTROL_MASK); alt = bool(st & Gdk.ModifierType.MOD1_MASK); shift = bool(st & Gdk.ModifierType.SHIFT_MASK)
        if k == Gdk.KEY_space and not (ctrl or alt):
            if self.space_down: return True                # autorepeat while held
            if self.mode == "list" and self.previewable_selection():
                self.space_down = True; self.space_peek = False
                self.space_timer = GLib.timeout_add(380, self.space_fire); return True
        elif self.space_down and not self.space_peek:
            self.flush_space()
        home = self.mode in ("home", "all")
        if self.mode == "preview":
            if k == Gdk.KEY_Escape or (ctrl and k == Gdk.KEY_y):
                self.leave_preview(); return True
            if k in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
                spawn(["xdg-open", self.pv_path]); self.dismiss(); return True
            adj = self.pv_scroll.get_vadjustment(); stp = {Gdk.KEY_Down: 60, Gdk.KEY_Up: -60, Gdk.KEY_Page_Down: 420, Gdk.KEY_Page_Up: -420}.get(k)
            if stp: adj.set_value(max(0, min(adj.get_upper() - adj.get_page_size(), adj.get_value() + stp))); return True
        if ctrl and k == Gdk.KEY_y and self.mode == "list":
            self.show_preview(); return True
        if k == Gdk.KEY_Escape or (ctrl and k in (Gdk.KEY_bracketleft, Gdk.KEY_c)):
            if self.mode == "all": self.show_home(); return True      # first Esc goes back to the home view
            self.dismiss(); return True
        if alt and k == Gdk.KEY_a and self.mode != "all":
            self.show_all_apps(); return True
        if self.mode == "all" and k in (Gdk.KEY_Down, Gdk.KEY_Up) or (self.mode == "all" and ctrl and k in (Gdk.KEY_j, Gdk.KEY_k, Gdk.KEY_n, Gdk.KEY_p)):
            step = 4 if k in (Gdk.KEY_Down, Gdk.KEY_j, Gdk.KEY_n) else -4
            self.home_sel = max(0, min(len(self.home_items) - 1, self.home_sel + step)); self.paint_home(); return True
        if home and (k in (Gdk.KEY_Right,) or (ctrl and k == Gdk.KEY_l)):
            self.move(1); return True
        if home and (k in (Gdk.KEY_Left,) or (ctrl and k == Gdk.KEY_h)):
            self.move(-1); return True
        if k in (Gdk.KEY_Down,) or (ctrl and k in (Gdk.KEY_j, Gdk.KEY_n)):
            (self.vmove(1) if self.mode == "home" else self.move(1)); return True
        if k in (Gdk.KEY_Up,) or (ctrl and k in (Gdk.KEY_k, Gdk.KEY_p)):
            (self.vmove(-1) if self.mode == "home" else self.move(-1)); return True
        if k == Gdk.KEY_Tab:
            self.move(1); return True
        if k == Gdk.KEY_ISO_Left_Tab:
            self.move(-1); return True
        if k in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            m = 2 if alt else 1 if (ctrl or shift) else 0
            if home: self.activate_home(self.home_sel, m)
            else:
                row = self.list.get_selected_row(); self.activate(row.get_index() if row else 0, m)
            return True
        if alt and Gdk.KEY_1 <= k <= Gdk.KEY_9 and not home:
            self.activate(k - Gdk.KEY_1, 0); return True
        if ctrl and not shift and k == Gdk.KEY_c and not self.entry.get_selection_bounds():   # Ctrl+C copies the highlighted result (text in the box still copies as usual)
            if home: self.activate_home(self.home_sel, 2)
            else:
                row = self.list.get_selected_row()
                if row: self.activate(row.get_index(), 2)
            return True
        if ctrl and k == Gdk.KEY_u:
            self.entry.set_text(""); return True
        return False

def daemon(first=None):
    """Resident mode: Spotlight is built once and shown on request (~instant); commands arrive on a FIFO. (Settings is NOT kept in memory.)"""
    import signal
    RT = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")); fifo = RT / "rog-ui.fifo"; pidf = RT / "rog-ui.pid"
    try:                                                   # one resident instance only: hand the command to the running one instead
        old = int(pidf.read_text())
        if old != os.getpid() and b"spotlight.py" in Path(f"/proc/{old}/cmdline").read_bytes():
            if first:
                fd0 = os.open(fifo, os.O_WRONLY | os.O_NONBLOCK); os.write(fd0, (first + "\n").encode()); os.close(fd0)
            return
    except Exception:
        pass
    load_apps()
    Gio.AppInfoMonitor.get().connect("changed", lambda m: load_apps())     # new/removed apps show up without a restart
    spot = Spot(daemon=True)
    cb = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
    cb.connect("owner-change", lambda c, ev: clip_changed(c))
    clip_changed(cb)
    def handle(cmd):
        if cmd == "clip":
            spot.present_fresh(); spot.entry.set_text("c "); spot.entry.set_position(-1)
        elif cmd == "apps":
            spot.present_fresh(); spot.show_all_apps()
        elif cmd == "spotlight":
            if spot.get_visible(): spot.dismiss()
            else: spot.present_fresh()
        elif cmd == "quit": Gtk.main_quit()
    try: os.mkfifo(fifo, 0o600)
    except FileExistsError: pass
    fd = os.open(fifo, os.O_RDWR | os.O_NONBLOCK)
    def on_data(fd_, cond):
        try: data = os.read(fd_, 4096).decode()
        except BlockingIOError: return True
        for c in data.split():
            handle(c)
        return True
    GLib.io_add_watch(fd, GLib.IO_IN, on_data)
    pidf.write_text(str(os.getpid()))
    signal.signal(signal.SIGTERM, lambda *a: Gtk.main_quit())
    if first: GLib.idle_add(lambda: (handle(first), False)[1])
    Gtk.main()
    try:
        if pidf.read_text().strip() == str(os.getpid()): pidf.unlink()   # never delete a newer instance's files
    except Exception: pass

def main():
    if "--search" in sys.argv:                       # headless: print what the box would show (used for testing)
        load_apps()
        q = " ".join(a for a in sys.argv[1:] if a != "--search")
        for it in search(q):
            print(f"{it.score:7.1f}  {it.kind:7} {it.title}  |  {it.sub}")
        return
    if "--import-greenclip" in sys.argv:
        import_greenclip(); return
    if "--daemon" in sys.argv:
        rest = [a for a in sys.argv[1:] if a != "--daemon"]
        daemon(rest[0] if rest else None); return
    load_apps()
    w = Spot(); w.show(); w.present(); w.entry.grab_focus()
    Gtk.main()

if __name__ == "__main__":
    main()
RSPOT
	sed -i -E 's|exec --no-startup-id python3 ~/.config/scripts/spotlight.py|exec --no-startup-id ~/.config/scripts/rog-ui.sh spotlight|; s|exec --no-startup-id python3 ~/.config/scripts/settings.py|exec --no-startup-id ~/.config/scripts/rog-ui.sh settings|' "$W/i3"
	# clipboard history now lives in the resident Spotlight process (event driven); the polling greenclip daemon and its rofi menu go
	sed -i -E "s|^(exec --no-startup-id sh -lc 'pgrep -x greenclip.*)$|# rog-tune: \\1|" "$W/i3"
	sed -i -E '/^bindsym \$mod\+Shift\+v exec rofi \\$/,/^  -theme .*rasi$/ { s/\\$//; s/^/# rog-tune: /; }' "$W/i3"
	if ! grep -q "rog-tune: clip" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: clip — Super+Shift+V: clipboard history in Spotlight (recorded by the resident process, no polling daemon)
bindsym $mod+Shift+v exec --no-startup-id ~/.config/scripts/rog-ui.sh clip
E
	fi
	if ! grep -q "rog-ui.sh start" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: spotlight — Spotlight and Settings live in one resident process (started once; opening is instant)
exec_always --no-startup-id ~/.config/scripts/rog-ui.sh start
E
	fi
	cat >"$W/rog-ui.sh" <<'RUI'
#!/usr/bin/env bash
# rog-tune: client for the resident Spotlight/Settings process (it starts at login, so opening is near-instant).
#   rog-ui.sh spotlight          show Spotlight (toggles); lives in a small resident process
#   rog-ui.sh apps               browse every installed app (also: Alt+A inside Spotlight)
#   rog-ui.sh clip               Spotlight pre-filled with "c ": my clipboard history (the same process records it)
#   rog-ui.sh settings | backup  open Settings / the backup chooser as ordinary windows (nothing stays in memory afterwards)
#   rog-ui.sh start | restart | quit   manage the resident Spotlight process
RT=${XDG_RUNTIME_DIR:-/tmp}; FIFO=$RT/rog-ui.fifo; PIDF=$RT/rog-ui.pid
SCRIPT=$HOME/.config/scripts/spotlight.py
alive() { [[ -r $PIDF ]] && grep -q spotlight.py "/proc/$(<"$PIDF")/cmdline" 2>/dev/null && [[ -p $FIFO ]]; }
launch() { setsid python3 "$SCRIPT" --daemon "$@" >/dev/null 2>&1 </dev/null & }
case ${1:-spotlight} in
start) alive || launch ;;
restart) if [[ -r $PIDF ]]; then old=$(<"$PIDF"); kill "$old" 2>/dev/null; for _ in {1..20}; do [[ -d /proc/$old ]] || break; sleep 0.1; done; fi; launch ;;
quit) [[ -r $PIDF ]] && kill "$(<"$PIDF")" 2>/dev/null ;;
settings) if pgrep -xf "python3 $HOME/.config/scripts/settings.py" >/dev/null; then i3-msg '[class="^RogSettings$"] focus' >/dev/null; else setsid python3 "$HOME/.config/scripts/settings.py" >/dev/null 2>&1 </dev/null & fi ;;
backup) setsid python3 "$HOME/.config/scripts/settings.py" --backup >/dev/null 2>&1 </dev/null & ;;
*) if alive; then printf '%s\n' "$1" >"$FIFO"; else launch "$1"; fi ;;
esac
RUI
	cat >"$W/rog-update.sh" <<'RUPD'
#!/usr/bin/env bash
# rog-tune: update the system the careful way: show the Arch news since my last update first, then (if I agree) run pacman -Syu.
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
RUPD
	cat >"$W/alarm.py" <<'RALARM'
#!/usr/bin/env python3
# rog-tune: the window a Spotlight timer or reminder shows when it rings. Stays until I dismiss it (Enter / Esc); S snoozes 5 minutes.
#   alarm.py "message"        (started by systemd-run --user when the time comes)
import json, os, subprocess, sys, threading, time
from pathlib import Path
import gi
gi.require_version("Gtk", "3.0"); gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GLib

HOME = Path.home()
MSG = " ".join(sys.argv[1:]) or "Time is up"
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "spotlight"
CSS = b"""
window.alarm { background-color: rgba(238,233,224,0.97); border: 3px solid #c47f1c; border-radius: 22px; }
.alarm .big { color: #2a251e; font-size: 30pt; font-weight: 300; padding: 34px 44px 10px 44px; }
.alarm .sub { color: #7d7466; font-size: 12pt; padding: 0 44px 30px 44px; }
"""

def is_dark():
    mode = setting("APPEARANCE", "light")
    if mode == "dark": return True
    if mode != "schedule": return False
    try: a = int(setting("NIGHT_START", "19")); b = int(setting("NIGHT_END", "7"))
    except ValueError: a, b = 19, 7
    h = time.localtime().tm_hour
    return (h >= a or h < b) if a > b else (a <= h < b)

def accent_hex():
    m = setting("ACCENT_MODE", "amber")
    try:
        if m == "custom" and len(setting("ACCENT_HEX", "")) == 7: return setting("ACCENT_HEX", "")
        if m == "wallpaper":
            v = (HOME / ".cache/accent-wallpaper").read_text().strip()
            if len(v) == 7: return v
    except Exception: pass
    return "#c47f1c"

def themed_css():
    css = CSS.decode()
    if is_dark():
        for a, c in (("rgba(238,233,224,0.97)", "rgba(31,28,25,0.97)"), ("#2a251e", "#f6efe4"), ("#7d7466", "#a39685")): css = css.replace(a, c)
    return css.replace("#c47f1c", accent_hex()).encode()

def setting(key, default):
    try:
        for l in (HOME / ".config/rog/settings.env").read_text().splitlines():
            if l.startswith(key + "="): return l.split("=", 1)[1].strip().strip('"')
    except Exception: pass
    return default

stop = threading.Event()
def ring():
    snd = "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
    if setting("ALARM_SOUND", "1") != "1" or not os.path.exists(snd): return
    for _ in range(4):
        if stop.is_set(): return
        subprocess.run(["paplay", snd], capture_output=True)
        stop.wait(1.5)

def snooze():
    unit = f"rog-alarm-{int(time.time())}"
    env = [f"--setenv={k}={os.environ[k]}" for k in ("DISPLAY", "XAUTHORITY", "XDG_RUNTIME_DIR", "DBUS_SESSION_BUS_ADDRESS") if k in os.environ]
    subprocess.run(["systemd-run", "--user", "--collect", f"--unit={unit}", "--on-active=300s", "--timer-property=AccuracySec=50ms"] + env + ["python3", str(Path(__file__).resolve()), MSG], capture_output=True)
    try:
        f = STATE / "alarms.json"; a = json.loads(f.read_text()) if f.exists() else {}
        a[unit] = {"msg": MSG, "due": int(time.time() + 300)}; f.write_text(json.dumps(a))
    except Exception: pass

class Win(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_wmclass("rogalarm", "RogAlarm"); self.set_title("Alarm"); self.set_decorated(False)
        self.set_default_size(620, -1); self.set_keep_above(True)
        scr = self.get_screen(); vis = scr.get_rgba_visual()
        if vis: self.set_visual(vis)
        self.get_style_context().add_class("alarm")
        prov = Gtk.CssProvider(); prov.load_from_data(themed_css()); Gtk.StyleContext.add_provider_for_screen(scr, prov, Gtk.STYLE_PROVIDER_PRIORITY_USER)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL); box.get_style_context().add_class("alarm"); self.add(box)
        t = Gtk.Label(label="⏰  " + MSG, xalign=0); t.set_line_wrap(True); t.set_max_width_chars(34); t.get_style_context().add_class("big"); box.pack_start(t, False, False, 0)
        s = Gtk.Label(label="Enter or Esc to dismiss   ·   S to snooze 5 minutes", xalign=0); s.get_style_context().add_class("sub"); box.pack_start(s, False, False, 0)
        self.connect("key-press-event", self.on_key); self.connect("destroy", lambda *a: (stop.set(), Gtk.main_quit()))
        self.show_all(); self.present()
        threading.Thread(target=ring, daemon=True).start()

    def on_key(self, w, e):
        if e.keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter, Gdk.KEY_Escape): self.destroy(); return True
        if e.keyval in (Gdk.KEY_s, Gdk.KEY_S): snooze(); self.destroy(); return True
        return False

if __name__ == "__main__":
    Win(); Gtk.main()
RALARM
	cat >"$W/power-menu.py" <<'RPOW'
#!/usr/bin/env python3
# rog-tune: power menu (Super+Escape). One row of big tiles: Lock, Log out, Sleep, Hibernate, Restart, Shut down.
#   h / l / arrows / Tab move · 1-6 pick · Enter runs · Esc or q closes
#   Lock and Sleep run at once; Log out, Hibernate, Restart and Shut down ask for a second Enter so a slip never ends the session.
import os, subprocess, sys, time
from pathlib import Path
import gi
gi.require_version("Gtk", "3.0"); gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GLib

HOME = Path.home()
def setting(key, default):
    try:
        for l in (HOME / ".config/rog/settings.env").read_text().splitlines():
            if l.startswith(key + "="): return l.split("=", 1)[1].strip().strip('"')
    except Exception: pass
    return default

def is_dark():
    mode = setting("APPEARANCE", "light")
    if mode == "dark": return True
    if mode != "schedule": return False
    try: a = int(setting("NIGHT_START", "19")); b = int(setting("NIGHT_END", "7"))
    except ValueError: a, b = 19, 7
    h = time.localtime().tm_hour
    return (h >= a or h < b) if a > b else (a <= h < b)

def accent_hex():
    m = setting("ACCENT_MODE", "amber")
    try:
        if m == "custom" and len(setting("ACCENT_HEX", "")) == 7: return setting("ACCENT_HEX", "")
        if m == "wallpaper":
            v = (HOME / ".cache/accent-wallpaper").read_text().strip()
            if len(v) == 7: return v
    except Exception: pass
    return "#c47f1c"

CSS = """
window.power { background-color: transparent; }
.pcard { background-color: rgba(238,233,224,0.97); border-radius: 26px; border: 1px solid rgba(42,37,30,0.10); padding: 22px 26px 18px 26px; }
.phead { color: #7d7466; font-size: 11pt; padding: 0 6px 14px 6px; }
.ptile { background: transparent; border: 2px solid transparent; border-radius: 20px; padding: 16px 8px 12px 8px; min-width: 112px; box-shadow: none; transition: all 120ms ease; }
.ptile image { color: #2a251e; }
.ptile.armed image { color: #ffffff; }
.ptile label { color: #2a251e; font-size: 12pt; }
.ptile .num { color: #7d7466; font-size: 9pt; }
.ptile.sel { background-color: rgba(196,127,28,0.16); border-color: #c47f1c; }
.ptile.armed { background-color: #c47f1c; border-color: #c47f1c; }
.ptile.armed label { color: #ffffff; }
.pmsg { color: #7d7466; font-size: 11pt; padding: 12px 6px 0 6px; }
.pmsg.warn { color: #c47f1c; font-weight: 600; }
"""
def themed_css():
    css = CSS
    if is_dark():
        for a, c in (("rgba(238,233,224,0.97)", "rgba(31,28,25,0.97)"), ("rgba(42,37,30,0.10)", "rgba(238,233,224,0.12)"),
                     ("#2a251e", "#f6efe4"), ("#7d7466", "#a39685")): css = css.replace(a, c)
    acc = accent_hex(); r, g, b = (int(acc[i:i + 2], 16) for i in (1, 3, 5))
    return css.replace("rgba(196,127,28,0.16)", f"rgba({r},{g},{b},0.18)").replace("#c47f1c", acc).encode()

def detach(cmd):
    subprocess.Popen(cmd, start_new_session=True, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# label, icon, command, needs a second Enter, confirmation text
ACTIONS = [
    ("Lock", "system-lock-screen", [str(HOME / ".config/i3lock/lock.sh")], False, ""),
    ("Log out", "system-log-out", ["i3-msg", "exit"], True, "Press Enter again to log out"),
    ("Sleep", "system-suspend", ["systemctl", "suspend"], False, ""),
    ("Hibernate", "system-suspend-hibernate", ["systemctl", "hibernate"], True, "Press Enter again to hibernate (saves to disk, powers off)"),
    ("Restart", "system-reboot", ["systemctl", "reboot"], True, "Press Enter again to restart"),
    ("Shut down", "system-shutdown", ["systemctl", "poweroff"], True, "Press Enter again to shut down"),
]
try:
    if "resume=" not in Path("/proc/cmdline").read_text(): ACTIONS = [a for a in ACTIONS if a[0] != "Hibernate"]
except Exception: pass

def status_line():
    parts = [os.uname().nodename]
    try:
        s = int(float(Path("/proc/uptime").read_text().split()[0])); d, s = divmod(s, 86400); h, s = divmod(s, 3600)
        parts.append("up " + (f"{d}d " if d else "") + f"{h}h {s // 60:02d}m")
    except Exception: pass
    try:
        for b in sorted(Path("/sys/class/power_supply").glob("BAT*")):
            parts.append(f"battery {(b / 'capacity').read_text().strip()}% ({(b / 'status').read_text().strip().lower()})"); break
    except Exception: pass
    return "   ·   ".join(parts)

class Win(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_wmclass("rogpower", "RogPower"); self.set_title("Power"); self.set_decorated(False); self.set_keep_above(True)
        scr = self.get_screen(); vis = scr.get_rgba_visual()
        if vis: self.set_visual(vis)
        self.set_app_paintable(True)
        self.get_style_context().add_class("power")
        prov = Gtk.CssProvider(); prov.load_from_data(themed_css()); Gtk.StyleContext.add_provider_for_screen(scr, prov, Gtk.STYLE_PROVIDER_PRIORITY_USER)
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL); card.get_style_context().add_class("pcard"); self.add(card)
        head = Gtk.Label(label=status_line(), xalign=0.5); head.get_style_context().add_class("phead"); card.pack_start(head, False, False, 0)
        row = Gtk.Box(spacing=6); card.pack_start(row, False, False, 0)
        self.tiles = []; self.sel = 0; self.armed = None
        for i, (label, icon, cmd, ask, msg) in enumerate(ACTIONS):
            b = Gtk.Button(); b.set_relief(Gtk.ReliefStyle.NONE); b.set_can_focus(False); b.get_style_context().add_class("ptile")
            v = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
            im = Gtk.Image.new_from_icon_name(icon + "-symbolic", Gtk.IconSize.DIALOG); im.set_pixel_size(40); v.pack_start(im, False, False, 0)
            t = Gtk.Label(label=label); v.pack_start(t, False, False, 0)
            n = Gtk.Label(label=str(i + 1)); n.get_style_context().add_class("num"); v.pack_start(n, False, False, 0)
            b.add(v); b.connect("clicked", lambda w, i=i: self.choose(i)); row.pack_start(b, True, True, 0); self.tiles.append(b)
        self.msg = Gtk.Label(label="h / l move   ·   Enter runs   ·   Esc closes", xalign=0.5); self.msg.get_style_context().add_class("pmsg"); card.pack_start(self.msg, False, False, 0)
        self.connect("key-press-event", self.on_key); self.connect("destroy", Gtk.main_quit)
        self.refresh(); self.show_all(); self.present()

    def refresh(self):
        for i, b in enumerate(self.tiles):
            c = b.get_style_context()
            for k in ("sel", "armed"): c.remove_class(k)
            if i == self.sel: c.add_class("armed" if self.armed == i else "sel")
        ctx = self.msg.get_style_context()
        if self.armed is not None: self.msg.set_text(ACTIONS[self.armed][4]); ctx.add_class("warn")
        else: self.msg.set_text("h / l move   ·   Enter runs   ·   Esc closes"); ctx.remove_class("warn")

    def move(self, d): self.sel = (self.sel + d) % len(ACTIONS); self.armed = None; self.refresh()

    def choose(self, i):
        if i != self.sel: self.sel = i; self.armed = None
        self.run()

    def run(self):
        label, icon, cmd, ask, msg = ACTIONS[self.sel]
        if ask and self.armed != self.sel: self.armed = self.sel; self.refresh(); return
        self.hide(); Gdk.flush()
        detach(cmd); GLib.timeout_add(200, Gtk.main_quit)

    def on_key(self, w, e):
        k = e.keyval
        if k in (Gdk.KEY_Escape, Gdk.KEY_q): self.destroy(); return True
        if k in (Gdk.KEY_Right, Gdk.KEY_l, Gdk.KEY_Tab): self.move(1); return True
        if k in (Gdk.KEY_Left, Gdk.KEY_h, Gdk.KEY_ISO_Left_Tab): self.move(-1); return True
        if k in (Gdk.KEY_Return, Gdk.KEY_KP_Enter, Gdk.KEY_space): self.run(); return True
        if Gdk.KEY_1 <= k <= Gdk.KEY_9 and k - Gdk.KEY_1 < len(ACTIONS): self.sel = k - Gdk.KEY_1; self.armed = None; self.run(); return True
        return False

if __name__ == "__main__":
    # a second press of the key while the menu is open closes it
    try:
        me = os.getpid(); r = subprocess.run(["pgrep", "-xf", f"python3 {Path(__file__).resolve()}"], capture_output=True, text=True).stdout.split()
        others = [p for p in r if int(p) != me]
        if others: os.kill(int(others[0]), 15); sys.exit(0)
    except Exception: pass
    Win(); Gtk.main()
RPOW
	cat >"$W/rg-pre.sh" <<'RPRE'
#!/usr/bin/env bash
# rog-tune: ripgrep --pre helper for Spotlight's deep search: PDF text is extracted once and cached (by path + mtime)
f=$1; C=${XDG_CACHE_HOME:-$HOME/.cache}/spotlight/pdf; mkdir -p "$C"
k=$(printf '%s' "$f$(stat -c %Y "$f")" | md5sum | cut -d' ' -f1)
[[ -s $C/$k ]] || pdftotext -q -layout "$f" "$C/$k.tmp" 2>/dev/null && mv -f "$C/$k.tmp" "$C/$k" 2>/dev/null
cat "$C/$k" 2>/dev/null
exit 0
RPRE
	cat >"$W/sync-server.sh" <<'RSYN'
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
RSYN
	ADD+=("$SD/spotlight.py|$W/spotlight.py" "$SD/rg-pre.sh|$W/rg-pre.sh" "$SD/sync-server.sh|$W/sync-server.sh" "$SD/settings.py|$W/settings.py" "$SD/rog-ui.sh|$W/rog-ui.sh" "$SD/alarm.py|$W/alarm.py" "$SD/power-menu.py|$W/power-menu.py" "$SD/rog-update.sh|$W/rog-update.sh")
fi
if has caffeine; then
	# nothing in the bar: take the module out of an earlier version of this part
	ini_set "$W/pb" bar/toph modules-right "pulseaudio brightness battery memory cpu network mic"
	awk '/^; rog-tune: caffeine/{skip=1; next} /^\[module\/caffeine\]/{skip=1; next} skip && /^\[/{skip=0} !skip' "$W/pb" >"$W/pb.n" && mv "$W/pb.n" "$W/pb"
	if ! grep -q "$MARK: caffeine" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: caffeine — Super+Shift+I keeps the screen on and unlocked until I press it again
bindsym $mod+Shift+i exec --no-startup-id ~/.config/scripts/caffeine.sh toggle
E
	fi
	cat >"$W/caffeine.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: caffeine. While on: no auto-lock, no screen blanking (closing the lid still suspends, Super+Shift+L still locks).
#   caffeine.sh toggle | on | off | status
F=${XDG_STATE_HOME:-$HOME/.local/state}/caffeine; mkdir -p "${F%/*}"
case ${1:-toggle} in
toggle) if [[ -e $F ]]; then exec "$0" off; else exec "$0" on; fi ;;
on) : >"$F"; xset s off -dpms 2>/dev/null ;;
off) rm -f "$F"; "$HOME/.config/scripts/power-watch.sh" timers ;;
status) if [[ -e $F ]]; then echo on; elif [[ -e ${XDG_RUNTIME_DIR:-/tmp}/autocaffeine.on ]]; then echo auto; else echo off; fi ;;
esac
E
	if ! grep -q "$MARK: autocaffeine" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: autocaffeine — screen stays on while a window is fullscreen or an app uses the microphone
exec_always --no-startup-id ~/.config/scripts/autocaffeine.sh
E
	fi
	cat >"$W/autocaffeine.sh" <<'RAUTO'
#!/usr/bin/env bash
# rog-tune: automatic caffeine. The screen stays on and unlocked while a window is fullscreen on the visible workspace (video,
# presentations) or an app is using the microphone (calls); otherwise the normal lock/blank timers apply. Music does not count.
# Event driven (i3 + PulseAudio events); the manual toggle (caffeine.sh) works independently of it.
RT=${XDG_RUNTIME_DIR:-/tmp}; PIDF=$RT/autocaffeine.pid; MARK=$RT/autocaffeine.on
if [[ -r $PIDF ]] && grep -q autocaffeine "/proc/$(<"$PIDF")/cmdline" 2>/dev/null; then pkill -P "$(<"$PIDF")" 2>/dev/null; kill "$(<"$PIDF")" 2>/dev/null; fi
echo $$ >"$PIDF"
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
if [[ ${AUTOCAFFEINE:-1} == 0 ]]; then rm -f "$MARK"; "$HOME/.config/scripts/power-watch.sh" timers; exit 0; fi
fullscreen() {
	local ws; ws=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')
	i3-msg -t get_tree | jq -e --arg n "$ws" '[.. | objects | select(.type == "workspace" and .name == $n) | .. | objects | select(.window != null and .fullscreen_mode == 1)] | length > 0' >/dev/null
}
calling() {
	pactl -f json list source-outputs 2>/dev/null | jq -e '[.[] | select(.corked == false) | select((.properties["application.name"] // "") | test("peak|pavucontrol|volume|polybar|mission";"i") | not)] | length > 0' >/dev/null
}
update() {
	if fullscreen || calling; then
		[[ -e $MARK ]] || { : >"$MARK"; xset s off -dpms 2>/dev/null; }
	elif [[ -e $MARK ]]; then
		rm -f "$MARK"; "$HOME/.config/scripts/power-watch.sh" timers
	fi
}
fifo=$(mktemp -u "$RT/ac.XXXXXX"); mkfifo "$fifo"; exec 3<>"$fifo"; rm -f "$fifo"
cleanup() { kill $(jobs -p) 2>/dev/null; rm -f "$MARK"; }
trap cleanup EXIT; trap 'exit 0' TERM INT
pactl subscribe 2>/dev/null | grep --line-buffered "source-output" >&3 &
i3-msg -t subscribe -m '["window","workspace"]' 2>/dev/null | grep --line-buffered -E '"change":"(fullscreen_mode|close)"|"current":' >&3 &
update
while :; do
	read -r -t 120 -u 3 _ || true
	sleep 0.4; while read -r -t 0.05 -u 3 _; do :; done    # one evaluation per burst of events
	update
done
RAUTO
	ADD+=("$SD/caffeine.sh|$W/caffeine.sh" "$SD/autocaffeine.sh|$W/autocaffeine.sh")
fi
if has tablet; then
	if ! grep -q "$MARK: tablet" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: tablet — Super+Shift+T toggles tablet mode (on-screen keyboard); it is OFF at every login
bindsym $mod+Shift+t exec --no-startup-id ~/.config/scripts/tablet.sh toggle
E
	fi
	cat >"$W/tablet.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: tablet mode = an on-screen keyboard (onboard) docked at the bottom that appears when a text field gets focus.
# Off by default and after every login. Needs: sudo pacman -S onboard
#   tablet.sh toggle | on | off | status
command -v onboard >/dev/null || { echo "install onboard first: sudo pacman -S onboard" >&2; exit 1; }
running() { pgrep -x -u "$UID" onboard >/dev/null; }
on() {
	gsettings set org.onboard.auto-show enabled true
	gsettings set org.onboard.window docking-enabled true
	gsettings set org.onboard.window.landscape dock-expand true 2>/dev/null || true
	gsettings set org.onboard.window.portrait dock-expand true 2>/dev/null || true
	running || { onboard >/dev/null 2>&1 & disown; }
	rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/autorotate.lock"   # tablets rotate
}
off() { pkill -x -u "$UID" onboard || true; }
case ${1:-toggle} in
toggle) if running; then off; else on; fi ;;
on) on ;; off) off ;; status) running && echo on || echo off ;;
esac
E
	ADD+=("$SD/tablet.sh|$W/tablet.sh")
fi
if has pin; then
	if ! grep -q "$MARK: pin" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: pin — Super+Shift+P floats the window above everything on every workspace; press again to tile it back
bindsym $mod+Shift+p exec --no-startup-id ~/.config/scripts/pin.sh
E
	fi
	cat >"$W/pin.sh" <<'E'
#!/usr/bin/env bash
# rog-tune: pin the focused window (floating + sticky), or put it back
fl=$(i3-msg -t get_tree | jq -r '[.. | objects | select(.focused == true)][0].floating // "auto_off"')
case $fl in
user_on | auto_on) i3-msg 'sticky disable, floating disable' >/dev/null ;;
*) i3-msg 'floating enable, sticky enable, resize set 900 560, move position center' >/dev/null ;;
esac
E
	ADD+=("$SD/pin.sh|$W/pin.sh")
fi

if has input; then
	sed -i '/# rog-tune: xset$/d' "$W/i3"      # the old fixed key-repeat line: input-apply.sh now owns it (and reads your Settings)
	if ! grep -q "$MARK: input" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: input — touchpad, pointer speed and key repeat from the Settings app; the mic can start muted
exec_always --no-startup-id ~/.config/scripts/input-apply.sh
exec --no-startup-id ~/.config/scripts/login-apply.sh
E
	fi
	cat >"$W/input-apply.sh" <<'RIN'
#!/usr/bin/env bash
# rog-tune: apply touchpad / pointer / keyboard settings (at login, on i3 restart, and when Settings changes them)
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
export DISPLAY=${DISPLAY:-:0}
command -v xset >/dev/null && { xset r rate "${KEY_DELAY:-250}" "${KEY_RATE:-50}"; xset b off; }
command -v xinput >/dev/null || exit 0
xinput list --name-only | sort -u | while IFS= read -r d; do
	props=$(xinput list-props "$d" 2>/dev/null) || continue
	if grep -q "libinput Tapping Enabled (" <<<"$props"; then
		xinput set-prop "$d" "libinput Tapping Enabled" "${TP_TAP:-1}"
		xinput set-prop "$d" "libinput Natural Scrolling Enabled" "${TP_NATURAL:-0}"
		xinput set-prop "$d" "libinput Disable While Typing Enabled" "${TP_DWT:-1}" 2>/dev/null
	fi
	grep -q "libinput Accel Speed (" <<<"$props" && xinput set-prop "$d" "libinput Accel Speed" "${PTR_SPEED:-0}"
done
exit 0
RIN
	cat >"$W/login-apply.sh" <<'RLG'
#!/usr/bin/env bash
# rog-tune: things that happen once per login (not on every i3 restart)
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
if [[ ${MIC_MUTE_LOGIN:-0} == 1 ]]; then sleep 3; pactl set-source-mute @DEFAULT_SOURCE@ 1; fi
# put the screen back to the brightness I chose last (the login screen raises a nearly-dark screen so it can be read)
b=$HOME/.local/state/rog/brightness
if [[ -r $b ]] && [[ $(<"$b") =~ ^[0-9]+$ ]]; then
	BL=(); [[ -d /sys/class/backlight/nvidia_wmi_ec_backlight ]] && BL=(-d nvidia_wmi_ec_backlight)
	brightnessctl -q -n1 "${BL[@]}" set "$(<"$b")%"
fi
RLG
	ADD+=("$SD/input-apply.sh|$W/input-apply.sh" "$SD/login-apply.sh|$W/login-apply.sh")
fi
if has barfont; then
	# workspace numbers in their own, lighter font (the Settings app can change weight and size)
	grep -q '^font-1' "$W/pb" || ini_set "$W/pb" bar/toph font-1 "JetBrains Mono:weight=light:size=12;4"
	for st in active occupied urgent empty; do ini_set "$W/pb" module/xworkspaces "label-$st" '%{T2}%name%%{T-}'; done
	# a compact box: the bar is drawn 10 pt shorter inside two transparent borders, so the active workspace's fill (and its underline) shrink with it
	ini_set "$W/pb" bar/toph height 18pt; ini_set "$W/pb" bar/toph line-size 2pt
	ini_set "$W/pb" bar/toph border-top-size 5pt; ini_set "$W/pb" bar/toph border-bottom-size 5pt; ini_set "$W/pb" bar/toph border-color '#d9000000'
	for st in active occupied urgent empty; do ini_set "$W/pb" module/xworkspaces "label-$st-padding" 1; done   # equal padding everywhere = even spacing
fi

if has display; then
	if ! grep -q "$MARK: display" "$W/i3"; then cat >>"$W/i3" <<'E'

# rog-tune: display — adaptive refresh (idle = lower rate) and cinema mode (fullscreen video player = a rate that fits the film), one small agent
exec_always --no-startup-id python3 ~/.config/scripts/display-agent.py
E
	fi
	cat >"$W/display-agent.py" <<'RAG'
#!/usr/bin/env python3
# rog-tune: the display agent. One small process, no polling while it has nothing to do:
#   adaptive refresh  after N seconds without input the panel drops to the idle rate; the first key or touch brings the full rate back
#   cinema mode       a fullscreen video player (mpv, vlc, ...) switches the panel to a rate that divides the film's frame rate evenly
# The actual rate is chosen by `power-watch.sh refresh` (so Quiet mode, power source and these two always agree); this process only
# sets/clears two flag files and asks for a refresh.
import ctypes, json, math, os, select, signal, socket, subprocess, sys, threading, time
from pathlib import Path

HOME = Path.home()
RT = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
ENV = HOME / ".config/rog/settings.env"
PW = HOME / ".config/scripts/power-watch.sh"
LOW, CIN, PAUSE, PIDF = RT / "adaptive.low", RT / "cinema.on", RT / "display-agent.pause", RT / "display-agent.pid"
CINHZ = RT / "cinema.hz"            # set when mpv reports the video's exact frame rate (read by power-watch.sh)
MPV_SOCK = HOME / ".cache/mpv-ipc"
PLAYERS = {"mpv", "vlc", "celluloid", "io.github.celluloid_player.celluloid", "smplayer", "totem", "kodi", "haruna", "mplayer",
           "parole", "jellyfinmediaplayer", "jellyfin media player", "dragon", "mpc-qt", "stremio"}

def cfg(key, default):
    try:
        for l in ENV.read_text().splitlines():
            if l.startswith(key + "="): return l.split("=", 1)[1].strip().strip('"')
    except Exception: pass
    return os.environ.get(key, default)

# ---- seconds since the last key/touch, from the X screensaver extension (no fork, no polling of other processes)
class Idle:
    def __init__(self):
        self.xcb = ctypes.CDLL("libxcb.so.1"); self.ss = ctypes.CDLL("libxcb-screensaver.so.0")
        self.xcb.xcb_connect.restype = ctypes.c_void_p; self.xcb.xcb_connect.argtypes = [ctypes.c_char_p, ctypes.c_void_p]
        self.conn = self.xcb.xcb_connect(None, None)
        self.xcb.xcb_get_setup.restype = ctypes.c_void_p; self.xcb.xcb_get_setup.argtypes = [ctypes.c_void_p]
        class Iter(ctypes.Structure): _fields_ = [("data", ctypes.POINTER(ctypes.c_uint32)), ("rem", ctypes.c_int), ("index", ctypes.c_int)]
        self.xcb.xcb_setup_roots_iterator.restype = Iter; self.xcb.xcb_setup_roots_iterator.argtypes = [ctypes.c_void_p]
        self.root = self.xcb.xcb_setup_roots_iterator(self.xcb.xcb_get_setup(self.conn)).data[0]    # first field of xcb_screen_t = root window
        self.ss.xcb_screensaver_query_info.restype = ctypes.c_uint; self.ss.xcb_screensaver_query_info.argtypes = [ctypes.c_void_p, ctypes.c_uint32]
        self.ss.xcb_screensaver_query_info_reply.restype = ctypes.c_void_p
        self.ss.xcb_screensaver_query_info_reply.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_void_p]
        self.libc = ctypes.CDLL("libc.so.6"); self.libc.free.argtypes = [ctypes.c_void_p]

    def ms(self):
        cookie = self.ss.xcb_screensaver_query_info(self.conn, self.root)
        rep = self.ss.xcb_screensaver_query_info_reply(self.conn, cookie, None)
        if not rep: return 0
        v = ctypes.c_uint32.from_address(rep + 16).value                 # ms_since_user_input
        self.libc.free(rep); return v

def sh(*cmd, t=3):
    try: return subprocess.run(list(cmd), capture_output=True, text=True, timeout=t).stdout
    except Exception: return ""

def refresh(): subprocess.run([str(PW), "refresh"], capture_output=True, timeout=20)

def busy_reasons():
    """Things that mean 'do not drop the refresh rate now': locked, screen off, caffeine (fullscreen/call), audio playing."""
    if sh("pgrep", "-x", "i3lock").strip(): return "locked"
    if "Monitor is Off" in sh("xset", "q"): return "screen off"
    if (RT / "autocaffeine.on").exists() or (Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "caffeine").exists(): return "caffeine"
    if sh("pactl", "list", "short", "sink-inputs").strip(): return "audio"
    return ""

def cinema_wanted():
    try: tree = json.loads(sh("i3-msg", "-t", "get_tree", t=4)); wss = json.loads(sh("i3-msg", "-t", "get_workspaces", t=4))
    except Exception: return False
    cur = next((w["name"] for w in wss if w.get("focused")), None)
    def walk(n, ws=None):
        if n.get("type") == "workspace": ws = n.get("name")
        if n.get("window") and n.get("fullscreen_mode") == 1 and ws == cur:
            cls = ((n.get("window_properties") or {}).get("class") or "").lower()
            if cls in PLAYERS: return True
        return any(walk(c, ws) for c in n.get("nodes", []) + n.get("floating_nodes", []))
    return walk(tree)

def mpv_fps():
    """Ask mpv (through its control socket) for the playing video's frame rate; None if it is not available."""
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.settimeout(1.0); s.connect(str(MPV_SOCK))
        s.sendall(b'{"command":["get_property","container-fps"]}\n'); buf = b""
        while b"\n" not in buf: buf += s.recv(4096)
        s.close()
        for line in buf.splitlines():
            d = json.loads(line)
            if d.get("error") == "success" and d.get("data"): return float(d["data"])
    except Exception: pass
    return None

def film_rate(fps):
    """The lowest rate (at least 58 Hz, at most 165) that shows every frame for the same number of refreshes: fps * 1, 2, 3 ..."""
    m = max(1, math.ceil(58.0 / fps - 1e-9)); r = fps * m
    while r > 165 and m > 1: m -= 1; r = fps * m
    return round(r, 3)

def match_fps_later():
    """Cinema mode with mpv: the file may take a moment to load, so retry a few times, then set the exact rate."""
    for _ in range(10):
        time.sleep(0.6)
        if not CIN.exists(): return
        fps = mpv_fps()
        if fps:
            CINHZ.write_text(str(film_rate(fps))); refresh(); return

WS_GLYPH = {"kitty": "\uf120", "firefox": "\uf269", "zen": "\uf269", "zen-alpha": "\uf269", "google-chrome": "\uf268", "chromium": "\uf268", "qutebrowser": "\uf0ac",
            "code": "\uf121", "thunar": "\uf07b", "mpv": "\uf04b", "vlc": "\uf04b", "obsidian": "\uf249", "ferdium": "\uf086", "discord": "\uf392",
            "signal": "\uf086", "libreoffice": "\uf15c", "zotero": "\uf02d", "evince": "\uf1c1", "zathura": "\uf1c1", "okular": "\uf1c1", "anki": "\uf24d"}

def sync_icons():
    """Workspace names like '2 \uf120 \uf269' (icons of what is on them) when WS_ICONS=1, plain numbers when 0. Safe: i3 binds use `workspace number N`."""
    on = cfg("WS_ICONS", "0") == "1"
    try:
        tree = json.loads(sh("i3-msg", "-t", "get_tree", t=4)); wss = json.loads(sh("i3-msg", "-t", "get_workspaces", t=4))
    except Exception: return
    icons = {}
    def walk(n, ws=None):
        if n.get("type") == "workspace": ws = n.get("name")
        if n.get("window") and ws and not ws.startswith("__"):
            cls = ((n.get("window_properties") or {}).get("class") or "").lower()
            g = WS_GLYPH.get(cls) or WS_GLYPH.get(cls.split(".")[-1]) or "\uf2d0"
            if g not in icons.setdefault(ws, []): icons[ws].append(g)
        for c in n.get("nodes", []) + n.get("floating_nodes", []): walk(c, ws)
    walk(tree)
    for w in wss:
        name = w["name"]; num = str(w.get("num", ""))
        if not num.isdigit() or num == "-1": continue
        want = (num + " " + " ".join(icons.get(name, [])[:3])).strip() if on else num
        if want != name:
            sh("i3-msg", f'rename workspace "{name}" to "{want}"')

def single_instance():
    # every other copy goes, not only the one in the pid file: after an i3 restart a copy can be left over, and several of them fight over the flags
    me = os.getpid(); olds = []
    for d in Path("/proc").iterdir():
        try:
            if d.name.isdigit() and int(d.name) != me:
                cmd = (d / "cmdline").read_bytes().split(b"\0")
                if len(cmd) > 1 and b"python" in cmd[0] and cmd[1].endswith(b"display-agent.py"): olds.append(int(d.name))
        except Exception: pass
    for sig in (signal.SIGTERM, signal.SIGKILL):
        for p in olds:
            try: os.kill(p, sig)
            except Exception: pass
        if sig == signal.SIGTERM and olds: time.sleep(0.4)
    PIDF.write_text(str(me))

def cam_watch():
    """Camera in use: inotify on the webcam's device node (no polling); the flag file + a bar ping when it changes."""
    import threading
    try:
        libc = ctypes.CDLL("libc.so.6", use_errno=True)
        devs = []
        for p in sorted(Path("/sys/class/video4linux").glob("video*")):
            try:
                if (p / "index").read_text().strip() == "0": devs.append("/dev/" + p.name)
            except Exception: pass
        if not devs: return
        fd = libc.inotify_init1(0)
        for d in devs: libc.inotify_add_watch(fd, d.encode(), 0x20 | 0x8 | 0x10)      # IN_OPEN | IN_CLOSE_WRITE | IN_CLOSE_NOWRITE
        flag = RT / "camera.on"; state = None
        while True:
            now = subprocess.run(["fuser", "-s", *devs], capture_output=True).returncode == 0
            if now != state:
                state = now
                (flag.touch() if now else flag.unlink(missing_ok=True))
                subprocess.run(["polybar-msg", "action", "#camera.hook.0"], capture_output=True)
            os.read(fd, 4096); time.sleep(0.25)                                       # blocks until the camera is opened or closed
    except Exception:
        return

def main():
    import threading
    threading.Thread(target=cam_watch, daemon=True).start()
    single_instance()
    idle = Idle()
    def bye(*a):
        for f in (LOW, CIN, CINHZ, RT / "camera.on"): f.unlink(missing_ok=True)
        try: refresh()
        except Exception: pass
        PIDF.unlink(missing_ok=True)
        subprocess.run(["pkill", "-P", str(os.getpid())], capture_output=True)       # the i3 subscription and any xinput wait
        os._exit(0)                                     # leave for certain, whatever the main loop was blocked on
    signal.signal(signal.SIGTERM, bye); signal.signal(signal.SIGINT, bye)
    signal.signal(signal.SIGUSR1, lambda *a: sync_icons())
    if cfg("WS_ICONS", "0") == "1": sync_icons()
    i3 = subprocess.Popen(["i3-msg", "-t", "subscribe", "-m", '["window","workspace"]'], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)
    xin = None
    while True:
        thr = max(5, int(cfg("ADAPTIVE_IDLE_S", "60")))
        enabled = cfg("ADAPTIVE", "1") == "1" and not PAUSE.exists()
        # ---- waiting for input while the rate is low: block on the first input event (no polling at all)
        if LOW.exists():
            if xin is None: xin = subprocess.Popen(["xinput", "test-xi2", "--root"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)
            r, _, _ = select.select([xin.stdout, i3.stdout], [], [], None)
            if xin.stdout in r:
                xin.stdout.readline(); xin.kill(); xin.wait(); xin = None
                LOW.unlink(missing_ok=True); refresh(); continue
        else:
            if xin is not None: xin.kill(); xin.wait(); xin = None
            ms = idle.ms(); idle_s = ms / 1000.0
            if enabled and not CIN.exists() and idle_s >= thr:
                if not busy_reasons():
                    base = sh(str(PW), "rate").strip()
                    # measured on this laptop: 60 Hz and 90 Hz draw the same, 120+ Hz draws ~0.4-0.5 W more, so only drop from 110 Hz and up
                    if base and float(base) >= float(cfg("ADAPTIVE_MIN_HZ", "110")) and float(base) > float(cfg("IDLE_HZ", "60")):
                        LOW.touch(); refresh(); continue            # idle long enough: drop the rate, then wait for input below
                wait = 30.0                                          # busy (audio, call, locked...) or nothing to lower: look again in 30 s
            else:
                # sleep exactly until the earliest moment the idle threshold could be reached (no fixed-rate polling)
                wait = max(2.0, thr - idle_s) if enabled else 3600
            r, _, _ = select.select([i3.stdout], [], [], wait)
            if not r: continue
        # ---- an i3 event: re-evaluate cinema mode (only for fullscreen/close/workspace changes)
        if i3.stdout in r:
            line = i3.stdout.readline()
            if not line: time.sleep(1); continue
            if any(x in line for x in ('"fullscreen_mode"', '"close"', '"current"', '"new"', '"move"')):
                want = cfg("CINEMA", "1") == "1" and cinema_wanted()
                if want and not CIN.exists():
                    CIN.touch(); LOW.unlink(missing_ok=True); CINHZ.unlink(missing_ok=True); refresh()
                    threading.Thread(target=match_fps_later, daemon=True).start()      # mpv: switch to the video's exact multiple
                elif not want and CIN.exists(): CIN.unlink(missing_ok=True); CINHZ.unlink(missing_ok=True); refresh()
                if '"close"' in line or '"new"' in line or '"move"' in line or '"current"' in line:
                    if cfg("WS_ICONS", "0") == "1": sync_icons()

if __name__ == "__main__":
    main()
RAG
	ini_set "$W/pb" bar/toph modules-right "$(ini_get "$W/pb" bar/toph modules-right | sed -E 's/(^| )camera( |$)/ /; s/^ +//') camera"
	if ! grep -q '^\[module/camera\]' "$W/pb"; then cat >>"$W/pb" <<'E'

; rog-tune: camera — a red camera while any app has the webcam open (hidden otherwise); set by the display agent
[module/camera]
type = custom/ipc
hook-0 = ~/.config/scripts/camera.sh bar
initial = 1
E
	fi
	cat >"$W/accent.sh" <<'RACC'
#!/usr/bin/env bash
# rog-tune: apply the accent colour where Spotlight/Settings cannot reach: the bar's active workspace and the focused window's border.
#   accent.sh              apply what Settings -> General says (Amber, From the wallpaper, or Custom)
#   accent.sh wallpaper    (called when the wallpaper changes) work out the wallpaper's accent first, then apply
[[ -r $HOME/.config/rog/settings.env ]] && . "$HOME/.config/rog/settings.env"
CACHE=$HOME/.cache/accent-wallpaper
if [[ ${1:-} == wallpaper ]]; then
	wp=$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null); [[ -r $wp ]] || exit 0
	hex=$(magick "$wp" -resize 64x64! -depth 8 txt:- 2>/dev/null | python3 -c '
import sys, re, colorsys
best = None
for line in sys.stdin:
    m = re.search(r"\((\d+),(\d+),(\d+)", line)
    if not m: continue
    r, g, b = (int(x) / 255 for x in m.groups()); h, l, s = colorsys.rgb_to_hls(r, g, b)
    score = s * (1 - abs(l - 0.5) * 1.4)                       # saturated and neither too dark nor too light
    if best is None or score > best[0]: best = (score, h, s)
if best:
    h, s = best[1], max(best[2], 0.55)
    r, g, b = colorsys.hls_to_rgb(h, 0.55, min(s, 0.85)); print("#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255)))
')
	[[ $hex =~ ^#[0-9a-f]{6}$ ]] && echo "$hex" >"$CACHE"
	[[ ${ACCENT_MODE:-amber} == wallpaper ]] || exit 0
fi
case ${ACCENT_MODE:-amber} in
custom) hex=${ACCENT_HEX:-#e0a458} ;;
wallpaper) hex=$(cat "$CACHE" 2>/dev/null); hex=${hex:-#e0a458} ;;
*) hex=#e0a458 ;;
esac
[[ $hex =~ ^#[0-9a-fA-F]{6}$ ]] || exit 0
PB=$HOME/.config/polybar/config.ini; I3=$HOME/.config/i3/config
cur=$(grep -m1 -E '^mauve = ' "$PB" | sed -E 's/^mauve = //')
[[ $cur == "$hex" ]] && exit 0                      # nothing to change: no bar restart, no reload
sed -i -E "s/^mauve = .*/mauve = $hex/" "$PB"
sed -i -E "s/^(client\.focused[[:space:]]+)#[0-9a-fA-F]{6}( #[0-9a-fA-F]{6} #[0-9a-fA-F]{6} )#[0-9a-fA-F]{6} #[0-9a-fA-F]{6}/\1$hex\2$hex $hex/" "$I3"
polybar-msg cmd restart >/dev/null 2>&1; i3-msg reload >/dev/null 2>&1
RACC
	cat >"$W/camera.sh" <<'RCAM'
#!/usr/bin/env bash
# rog-tune: polybar camera indicator. The display agent sets the flag while any app has the webcam open; the bar shows a red camera then.
[[ ${1:-bar} == bar ]] || exit 0
[[ -e ${XDG_RUNTIME_DIR:-/tmp}/camera.on ]] && printf '%%{F#e06c5a}%s cam%%{F-}' "$(python3 -c "print(chr(0xf030))")"
RCAM
	cat >"$W/vaapi-check.sh" <<'RVA'
#!/usr/bin/env bash
# rog-tune: is hardware video decoding available? Needs libva-utils (sudo pacman -S libva-utils). Read-only.
command -v vainfo >/dev/null || { echo "Install libva-utils first:  sudo pacman -S libva-utils   (then run this again)"; exit 1; }
echo "== driver and decode profiles (VLD = hardware decode):"
LIBVA_DRIVER_NAME=${LIBVA_DRIVER_NAME:-radeonsi} vainfo 2>&1 | grep -E "Driver version|VAProfile(H264|HEVC|VP9|AV1)" | sed 's/^/  /'
echo
echo "== where it is enabled:"
for f in "$HOME"/.config/chrome-flags.conf "$HOME"/.config/google-chrome-flags.conf; do [[ -r $f ]] && { echo "  $f:"; grep -E "vaapi|VaapiVideo|hardware" "$f" | sed 's/^/    /'; }; done
grep -rhs "media.ffmpeg.vaapi" "$HOME"/.zen/*/user.js "$HOME"/.config/mozilla/firefox/*/user.js 2>/dev/null | sed 's/^/  firefox-family user.js: /'
echo
echo "To turn it on for the browsers: ~/rog-tune/rog-lean-session.sh --apply vaapi   (then restart them). Check chrome://gpu or about:support after."
RVA
	ADD+=("$SD/display-agent.py|$W/display-agent.py" "$SD/camera.sh|$W/camera.sh" "$SD/vaapi-check.sh|$W/vaapi-check.sh" "$SD/accent.sh|$W/accent.sh")
fi

# ---- show
show_diff() { diff -u --label "$2" --label "$2 (new)" "$1" "$3" || true; }
show_diff "$I3" i3/config "$W/i3"; show_diff "$PB" polybar/config.ini "$W/pb"; show_diff "$KC" kitty.conf "$W/kc"; show_diff "$BRC" .bashrc "$W/brc"
for n in wallcycle:wallpaper-cycle.sh wallcycle-rev:wallpaper-cycle-reverse.sh; do [[ -e $W/${n%%:*} ]] && show_diff "$H/.config/wallpaper-config/${n#*:}" "wallpaper-config/${n#*:}" "$W/${n%%:*}"; done
[[ -e $W/lock.sh ]] && show_diff "$H/.config/i3lock/lock.sh" i3lock/lock.sh "$W/lock.sh"
[[ -e $W/rofi-main ]] && { show_diff "$H/.config/rofi/catppuccin-mocha.rasi" rofi/catppuccin-mocha.rasi "$W/rofi-main"; show_diff "$H/.config/rofi/powermenu.rasi" rofi/powermenu.rasi "$W/rofi-power"; }
for a in "${ADD[@]+"${ADD[@]}"}"; do echo "write ${a%%|*}"; done
for d in "${hide_autostart[@]+"${hide_autostart[@]}"}"; do echo "hide autostart entry: $d"; done
has automount && echo "now: systemctl --user disable --now home-sarang-mnt-server.automount"
has vaapi && echo "also: media.ffmpeg.vaapi.enabled for Firefox/Zen profiles (user.js); install libva-utils to check with vainfo"
((APPLY)) || { echo ":: dry run, nothing changed. Re-run with --apply."; exit 0; }

backup() { [[ -e $BK/$1.before ]] || cp -a "$2" "$BK/$1.before"; }
[[ -e $H/.config/picom/picom.conf ]] && backup picom.conf "$H/.config/picom/picom.conf"; backup i3config "$I3"; backup polybar.ini "$PB"; backup kitty.conf "$KC"; backup bashrc "$BRC"
cp "$W/i3" "$I3"; cp "$W/pb" "$PB"; cp "$W/kc" "$KC"; cp "$W/brc" "$BRC"
[[ -e $W/lock.sh ]] && { backup lock "$H/.config/i3lock/lock.sh"; cp "$W/lock.sh" "$H/.config/i3lock/lock.sh"; chmod +x "$H/.config/i3lock/lock.sh"; }
for n in wallcycle:wallpaper-cycle.sh wallcycle-rev:wallpaper-cycle-reverse.sh; do
	[[ -e $W/${n%%:*} ]] && { backup "${n%%:*}" "$H/.config/wallpaper-config/${n#*:}"; cp "$W/${n%%:*}" "$H/.config/wallpaper-config/${n#*:}"; }
done
if [[ -e $W/rofi-main ]]; then
	backup rofi-main "$H/.config/rofi/catppuccin-mocha.rasi"; backup rofi-power "$H/.config/rofi/powermenu.rasi"
	cp "$W/rofi-main" "$H/.config/rofi/catppuccin-mocha.rasi"; cp "$W/rofi-power" "$H/.config/rofi/powermenu.rasi"
fi
for a in "${ADD[@]+"${ADD[@]}"}"; do
	d=${a%%|*}; s=${a#*|}; mkdir -p "$(dirname "$d")"
	if [[ $d == */chrome-flags.conf || $d == */dunstrc || $d == */settings.ini || $d == */psd.conf ]]; then # never overwrite a file I wrote myself
		if [[ -e $d ]] && ! grep -qxF "$d" "$BK/created.list" 2>/dev/null; then echo "keeping existing $d"; continue; fi
		grep -qxF "$d" "$BK/created.list" 2>/dev/null || echo "$d" >>"$BK/created.list"
	fi
	cp "$s" "$d"; [[ $d == *.sh ]] && chmod +x "$d"
done
mkdir -p "$AS"
for d in "${hide_autostart[@]+"${hide_autostart[@]}"}"; do
	printf '# %s\n[Desktop Entry]\nType=Application\nName=%s (hidden by rog-tune)\nHidden=true\n' "$MARK" "$d" >"$AS/$d.desktop"
done
if has display; then
	mkdir -p "$H/.config/mpv"
	grep -q "rog-tune" "$H/.config/mpv/mpv.conf" 2>/dev/null || printf '\n# rog-tune: lets cinema mode ask mpv for the video'"'"'s exact frame rate\ninput-ipc-server=~/.cache/mpv-ipc\n' >>"$H/.config/mpv/mpv.conf"
fi
if has vaapi; then
	for prof in "$H"/.config/mozilla/firefox/*/ "$H"/.zen/*/; do
		[[ -e $prof/prefs.js ]] || continue
		grep -q "$MARK" "$prof/user.js" 2>/dev/null || printf '// %s\nuser_pref("media.ffmpeg.vaapi.enabled", true);\nuser_pref("media.hardware-video-decoding.force-enabled", true);\n// /%s\n' "$MARK" "$MARK" >>"$prof/user.js"
	done
fi
if has automount && systemctl --user is-enabled --quiet home-sarang-mnt-server.automount 2>/dev/null; then
	: >"$BK/automount.was-enabled"; live systemctl --user disable --now home-sarang-mnt-server.automount
fi
has picom && { live pkill -x -u "$USER" picom || true; }
has hz60 && { live xrandr --output eDP-1 --rate 60 || true; }
has autostart && { live pkill -x -u "$USER" nm-applet || true; }
has ui && { live pkill -x -u "$USER" dunst || true; }
if has psd; then
	if command -v psd >/dev/null; then live systemctl --user enable psd.service && : >"$BK/psd.enabled"; echo "psd enabled: it starts at your next login (close the browsers first if you want it now: systemctl --user start psd)"
	else echo "!! psd: profile-sync-daemon is not installed (sudo pacman -S profile-sync-daemon); config written, rerun after installing" >&2; fi
fi
if has quiet; then
	live systemctl --user mask --now dunst.service 2>/dev/null && : >"$BK/dunst.masked" || true
	live pkill -x -u "$USER" dunst || true
fi
if has compositor && [[ ! -L $H/.config/picom/picom.conf ]]; then rm -f "$H/.config/picom/picom.conf"; ln -s picom-ac.conf "$H/.config/picom/picom.conf"; fi
has compositor && ! pgrep -x -u "$USER" picom >/dev/null && { live picom -b --config "$H/.config/picom/picom.conf" || true; }
echo ":: done. Reload i3 with Super+Shift+R (or log out/in). Undo: $0 --undo"
