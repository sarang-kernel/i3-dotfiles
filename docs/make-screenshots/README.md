# make-screenshots

How I take the README pictures without my real windows (or my Wi-Fi name) ending up in them: a throwaway Xvfb screen (`:99`) with its own
i3, bar, Spotlight and Settings, driven by `xdotool`. Needs `xorg-server-xvfb`, `xdotool`, `ffmpeg`, `imagemagick`, `kitty`, `fastfetch`.

```
./prep.sh                 # generate the throwaway configs under ~/shots/vx
~/shots/vx/scene.sh       # about 7 minutes, writes out/*.png (it is software-rendered, so it is slow and I keep the compositor off)
~/shots/vx/demo.sh        # records out of the same session: demo.mp4 and demo.gif
```
Then I look at every picture before it goes anywhere near the repo.
