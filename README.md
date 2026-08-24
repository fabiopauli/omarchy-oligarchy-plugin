# Oligarchy Screensaver for Omarchy

An [oligarchy.fyi](https://oligarchy.fyi) skin for Omarchy Quattro's screensaver: the site's exact 100-column pixel `OLIGARCHY` banner plus its 13 rotating taglines.

This is a headless `service` plugin. It listens to Hyprland's window events inside `omarchy-shell`, starts a six-second timer while an `org.omarchy.screensaver` window exists, and stops the timer when the last screensaver window closes. It adds no bar button; a second launcher would duplicate existing screensaver controls without helping the rotation service.

## Install

Add and enable the plugin:

```bash
omarchy plugin add https://github.com/fabiopauli/omarchy-oligarchy-plugin.git --enable
```

Try it with:

```bash
omarchy-launch-screensaver force
```

Inspect the running service with:

```bash
omarchy-shell io.github.fabiopauli.oligarchy-screensaver status
```

The first write backs up the previous banner to:

```text
~/.local/share/oligarchy/screensaver.txt.omarchy-backup
```

The backup is outside the plugin checkout, so removing the plugin does not discard it.

## Remove and restore the previous banner

Disable the service before restoring the banner so it cannot overwrite the restored file during a running screensaver:

```bash
omarchy plugin disable io.github.fabiopauli.oligarchy-screensaver
cp ~/.local/share/oligarchy/screensaver.txt.omarchy-backup \
  ~/.config/omarchy/branding/screensaver.txt
omarchy plugin remove io.github.fabiopauli.oligarchy-screensaver --yes
```

If no backup exists, reset to Omarchy's current stock banner instead:

```bash
omarchy branding screensaver reset
```

## How it works

Omarchy opens a fullscreen terminal on each monitor and runs `ttfx` over `~/.config/omarchy/branding/screensaver.txt`. The file is otherwise static.

`Service.qml` follows the same Hyprland window-event pattern as Omarchy's idle service. On the first screensaver window it runs the bundled writer immediately and every six seconds thereafter. Multiple monitor windows share one timer and one tagline. No polling process, `socat`, systemd user unit, PATH shim, or separate daemon is involved.

`bin/oligarchy-screensaver-text` chooses a random tagline other than the one currently displayed, pads it against the banner's fixed 100-column width, and atomically swaps a temporary file into place. The rename prevents `ttfx` from seeing a torn banner if it reads during a rotation.

## Banner fixture

The banner is not figlet output and not a rasterised or traced image. oligarchy.fyi's logo is a vectorised `<pre>`, and [`bin/oligarchy-make-logo`](bin/oligarchy-make-logo) decodes the SVG rectangles back into their exact original `▀▄█▌` characters on a 100 × 9 grid.

Verify the fixture with:

```bash
fixture=$(mktemp)
cp share/logo.txt "$fixture"
./bin/oligarchy-make-logo
diff -u "$fixture" share/logo.txt
rm -f "$fixture"
```

## Development

```bash
omarchy plugin validate .
shellcheck bin/oligarchy-screensaver-text
python -m py_compile bin/oligarchy-make-logo
```

QML load diagnostics are written to the active Quickshell log under `$XDG_RUNTIME_DIR/quickshell/by-pid/<pid>/log.log`.

## Security and privacy

Omarchy plugins run unsandboxed. This plugin observes only Hyprland window metadata and invokes its bundled local writer. It does not use the network, elevate privileges, or inspect window contents. See [`SECURITY.md`](SECURITY.md) for the complete file and process surface.

## License

[MIT](LICENSE)
