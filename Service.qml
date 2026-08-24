pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
  id: root

  // Injected by omarchy-shell for third-party service plugins.
  property var manifest: null

  readonly property string pluginDir: manifest && manifest.__sourceDir
    ? String(manifest.__sourceDir) : ""
  readonly property string screensaverClass: "org.omarchy.screensaver"
  readonly property int rotationIntervalMs: 6000

  property var screensaverWindows: ({})
  property int screensaverWindowCount: 0
  property bool rotationPending: false

  function eventParts(event, count) {
    try {
      if (event && event.parse) return event.parse(count)
    } catch (error) {
    }
    return String(event && event.data ? event.data : "").split(",")
  }

  function setScreensaverWindow(address, visible) {
    var key = String(address || "")
    if (!key) return

    var next = ({})
    var count = 0
    for (var existing in root.screensaverWindows) {
      if (existing !== key && root.screensaverWindows[existing]) {
        next[existing] = true
        count++
      }
    }
    if (visible) {
      next[key] = true
      count++
    }

    root.screensaverWindows = next
    root.screensaverWindowCount = count
  }

  function requestRotation() {
    if (!root.pluginDir || root.screensaverWindowCount === 0) return
    if (writer.running) {
      root.rotationPending = true
      return
    }

    root.rotationPending = false
    writer.command = ["bash", root.pluginDir + "/bin/oligarchy-screensaver-text"]
    writer.running = true
  }

  function handleScreensaverWindowOpened(address) {
    var wasInactive = root.screensaverWindowCount === 0
    root.setScreensaverWindow(address, true)
    if (!wasInactive) return

    root.requestRotation()
    rotationTimer.start()
  }

  function handleScreensaverWindowClosed(address) {
    if (!root.screensaverWindows[String(address || "")]) return
    root.setScreensaverWindow(address, false)
    if (root.screensaverWindowCount > 0) return

    rotationTimer.stop()
    root.rotationPending = false
  }

  function handleHyprlandEvent(event) {
    var name = String(event && event.name ? event.name : "")
    if (name === "openwindow") {
      var opened = root.eventParts(event, 4)
      if (String(opened[2] || "") === root.screensaverClass)
        root.handleScreensaverWindowOpened(opened[0])
    } else if (name === "closewindow") {
      var closed = root.eventParts(event, 1)
      root.handleScreensaverWindowClosed(closed[0])
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) { root.handleHyprlandEvent(event) }
  }

  Timer {
    id: rotationTimer
    interval: root.rotationIntervalMs
    repeat: true
    onTriggered: root.requestRotation()
  }

  Process {
    id: writer

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var message = String(text || "").trim()
        if (message) console.warn("oligarchy screensaver: " + message)
      }
    }

    onExited: function(exitCode) {
      if (exitCode !== 0)
        console.warn("oligarchy screensaver writer exited with code " + exitCode)
      if (root.rotationPending && root.screensaverWindowCount > 0)
        Qt.callLater(root.requestRotation)
    }
  }

  Component.onCompleted:
    console.log("oligarchy screensaver service ready")
}
