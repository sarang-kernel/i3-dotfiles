---
title: "Lock screen"
parent: "i3 desktop"
nav_order: 9
---

# Lock screen

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>


## What you see

A blurred, darkened copy of the current wallpaper, the date and a large thin clock near the top, and a round ring with my name at the bottom. With plain `i3lock` (no `-color` fork) it falls back to the simple lock.

## How it is started

| Trigger | How |
|---|---|
| `Super+Shift+L` | i3 runs `~/.config/i3lock/lock.sh` directly |
| Power menu, Spotlight ("lock") | the same script |
| **Idle timeout** | `xss-lock --transfer-sleep-lock -- lock.sh` (started by i3) runs it when the X screensaver timer fires. The timer length comes from `power-watch.sh` (`xset s`): 10 min on AC, 2 min on battery |
| Suspend / hibernate | `--transfer-sleep-lock` makes xss-lock take a logind inhibitor, so the screen locks *before* the machine sleeps |
| Caffeine on | The timers are switched off (`xset s off`), so the idle path never fires; the manual shortcut still works |

## `lock.sh` step by step

1. If the bar is visible it is hidden (`polybar-msg cmd hide`) and a trap shows it again on any exit, so the bar never sits on top of the lock.
2. The background is `~/.cache/lock-bg.png`, made by `login-bg.sh` whenever the wallpaper changes (i3lock only reads PNG).
3. Common options: `--nofork --ignore-empty-password --show-failed-attempts -c 14110f`.
4. If `i3lock --version` mentions *Raymond Li* (i3lock-color) it adds the rich options: a `%H:%M` clock at 150 pt (Noto Sans Light) and a date line, a ring of radius 54 with the user's name below it (the real name from `/etc/passwd`, capitalised), fixed translucent-white ring colours, and `Incorrect password` in a warm orange on failure. `--pass-media-keys --pass-volume-keys` keep the volume keys working.
5. If the rich invocation exits within two seconds with an error (an option this build does not know) it falls back to a plain `i3lock` with the common options.

`i3lock/avatar/avatar.jpg` and `.eps` are leftovers from an earlier lock screen; the current script does not use them.

## The lock screen that did not show

The idle path once failed to repaint: the old screen stayed up after the timeout and the lock only appeared after I moved the mouse. The fix history is on the [Compositor page](compositor.html#why-unredir-if-possible--false) and in [Changes](../changes/).

## Testing the timeout path without waiting ten minutes

```bash
xset s activate        # fires the same xss-lock path as an idle timeout
pkill -x i3lock        # unlock it again from another machine over ssh if you must
```

(`xset s activate` locks *your real session*; do not do it on a machine you cannot reach another way.)

## Related

[Power and display scripts](../scripts/power-display.html) set the timers; [Settings → Power & Performance](../scripts/settings-app.html) changes them; the **login** screen is a different program (greetd + ReGreet, configured by `rog-tune`'s `greetd` part).
