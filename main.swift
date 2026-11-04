import Cocoa
import Carbon
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlay = Overlay()
    let switcher = Switcher()
    let menu = NSMenu()
    var statusItem: NSStatusItem!
    var showItem: NSMenuItem!
    var settingsWindow: NSWindow?
    var lastLanguage: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = InputSources.shared
        _ = Updates.shared
        menu.addItem(withTitle: NSLocalizedString("설정…", comment: ""),
                     action: #selector(openSettings), keyEquivalent: ",").target = self
        showItem = menu.addItem(withTitle: NSLocalizedString("뱃지 표시", comment: ""),
                                action: #selector(toggleBadge), keyEquivalent: "")
        showItem.target = self
        menu.addItem(withTitle: NSLocalizedString("업데이트 확인…", comment: ""),
                     action: #selector(checkForUpdates), keyEquivalent: "").target = self
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
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier ?? ""
            MainActor.assumeIsolated {
                self?.switcher.appActivated(app)
                self?.refresh()
            }
        }
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main, using: onChange)
        let moves: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        NSEvent.addGlobalMonitorForEvents(matching: moves) { [overlay] _ in
            MainActor.assumeIsolated { overlay.mouseMoved() }
        }
        NSEvent.addLocalMonitorForEvents(matching: moves) { [overlay] event in
            MainActor.assumeIsolated { overlay.mouseMoved() }
            return event
        }
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [overlay] _ in
            MainActor.assumeIsolated { overlay.caretTick() }
        }

        refresh()
    }

    func refresh() {
        let lang = currentLanguage()
        let d = UserDefaults.standard
        let changed = lastLanguage != nil && lastLanguage != lang
        if changed, d.bool(forKey: K.sound) {
            NSSound(named: d.string(forKey: K.soundName) ?? "Tink")?.play()
        }
        lastLanguage = lang
        if changed { overlay.flash() } else { overlay.update() }
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

    @objc func checkForUpdates() {
        Updates.shared.check()
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let controller = NSHostingController(rootView: SettingsView())
            controller.sceneBridgingOptions = [.toolbars, .title]
            let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable, .miniaturizable],
                                  backing: .buffered, defer: false)
            window.contentViewController = controller
            window.toolbarStyle = .unified
            window.center()
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
