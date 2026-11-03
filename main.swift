import Cocoa
import Carbon
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlay = Overlay()
    let menu = NSMenu()
    var statusItem: NSStatusItem!
    var showItem: NSMenuItem!
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menu.addItem(withTitle: NSLocalizedString("설정…", comment: ""),
                     action: #selector(openSettings), keyEquivalent: ",").target = self
        showItem = menu.addItem(withTitle: NSLocalizedString("뱃지 표시", comment: ""),
                                action: #selector(toggleBadge), keyEquivalent: "")
        showItem.target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: NSLocalizedString("CheatIME 종료", comment: ""),
                     action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let icon = NSImage(named: "CheatIMETemplate")
        icon?.isTemplate = true
        icon?.size = NSSize(width: 18, height: 18)
        statusItem.button?.image = icon
        statusItem.button?.setAccessibilityLabel("CheatIME")
        statusItem.menu = menu
        overlay.contextMenu = menu

        let onChange: @Sendable (Notification) -> Void = { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil, queue: .main, using: onChange)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main, using: onChange)
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main, using: onChange)
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [overlay] _ in
            MainActor.assumeIsolated { overlay.followMouse() }
        }

        refresh()
    }

    func refresh() {
        overlay.update()
        showItem.state = UserDefaults.standard.bool(forKey: K.visible) ? .on : .off
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return false
    }

    @objc func toggleBadge() {
        let d = UserDefaults.standard
        d.set(!d.bool(forKey: K.visible), forKey: K.visible)
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let controller = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: controller)
            window.setContentSize(controller.view.fittingSize)
            window.center()
            window.title = NSLocalizedString("CheatIME 설정", comment: "")
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.orderFrontRegardless()
    }
}

registerDefaults()
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
