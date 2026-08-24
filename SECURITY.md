# Security policy

## Supported versions

Security fixes are applied to the latest commit on `main` and included in the next release.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting for this repository. Do not include secrets or private desktop captures in a public issue.

Include the affected plugin version, Omarchy version, reproduction steps, and the security impact.

## Process and file surface

The service listens to Hyprland's in-process window event stream and runs the bundled `bin/oligarchy-screensaver-text` writer only while a window with class `org.omarchy.screensaver` exists. It makes no network requests and does not elevate privileges.

The writer reads the bundled banner and taglines, preserves the first existing `~/.config/omarchy/branding/screensaver.txt` at `~/.local/share/oligarchy/screensaver.txt.omarchy-backup`, and atomically replaces the branding file with a temporary file and rename. It writes no other paths.
