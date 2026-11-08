#!/usr/bin/env bash
# rog-tune: pin the focused window (floating + sticky), or put it back
fl=$(i3-msg -t get_tree | jq -r '[.. | objects | select(.focused == true)][0].floating // "auto_off"')
case $fl in
user_on | auto_on) i3-msg 'sticky disable, floating disable' >/dev/null ;;
*) i3-msg 'floating enable, sticky enable, resize set 900 560, move position center' >/dev/null ;;
esac
