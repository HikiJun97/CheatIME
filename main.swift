import Cocoa
import Carbon
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlay = Overlay()
    let switcher = Switcher()
    let menu = NSMenu()
    var statusItem: NSStatusItem!
    var showItem: NSMenuItem!
    var updateItem: NSMenuItem!
    var updateSubscription: AnyCancellable?
    var settingsWindow: NSWindow?
    var lastSourceID: String?
    var refreshScheduled = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLanguage.captureLaunchLanguage()
        _ = InputSources.shared
        _ = Updates.shared
        AppList.shared.refresh()
        menu.addItem(withTitle: NSLocalizedString("설정…", comment: ""),
                     action: #selector(openSettings), keyEquivalent: ",").target = self
        showItem = menu.addItem(withTitle: NSLocalizedString("뱃지 표시", comment: ""),
                                action: #selector(toggleBadge), keyEquivalent: "")
        showItem.target = self
        updateItem = menu.addItem(withTitle: NSLocalizedString("업데이트 확인…", comment: ""),
                                  action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: NSLocalizedString("CheatIME 종료", comment: ""),
                     action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = statusIcon(badge: false)
        statusItem.button?.setAccessibilityLabel("CheatIME")
        statusItem.menu = menu
        overlay.contextMenu = menu
        Hotkey.shared.action = { [weak self] in self?.toggleBadge() }
        updateSubscription = Updates.shared.$pendingVersion.sink { [weak self] version in
            MainActor.assumeIsolated { self?.showPendingUpdate(version) }
        }

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
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleRefresh() }
        }
        let moves: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        NSEvent.addGlobalMonitorForEvents(matching: moves) { [overlay] _ in
            MainActor.assumeIsolated { overlay.mouseMoved() }
        }
        NSEvent.addLocalMonitorForEvents(matching: moves) { [overlay] event in
            MainActor.assumeIsolated { overlay.mouseMoved() }
            return event
        }

        refresh()
        if firstLaunch { openSettings() }
    }

    func showPendingUpdate(_ version: String?) {
        updateItem.title = version.map { String(format: NSLocalizedString("새 버전 %@ 설치…", comment: ""), $0) }
            ?? NSLocalizedString("업데이트 확인…", comment: "")
        statusItem.button?.image = statusIcon(badge: version != nil)
    }

    func statusIcon(badge: Bool) -> NSImage? {
        guard let base = NSImage(named: "CheatIMETemplate") else { return nil }
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            base.draw(in: rect)
            if badge {
                NSGraphicsContext.current?.compositingOperation = .clear
                NSBezierPath(ovalIn: NSRect(x: 10.5, y: 10.5, width: 8, height: 8)).fill()
                NSGraphicsContext.current?.compositingOperation = .sourceOver
                NSColor.black.setFill()
                NSBezierPath(ovalIn: NSRect(x: 12, y: 12, width: 5, height: 5)).fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    func scheduleRefresh() {
        guard !refreshScheduled else { return }
        refreshScheduled = true
        Task { @MainActor in
            refreshScheduled = false
            refresh()
        }
    }

    func refresh() {
        let source = currentInputSourceID()
        let d = UserDefaults.standard
        let changed = lastSourceID != nil && lastSourceID != source
        if changed, d.bool(forKey: K.sound) {
            NSSound(named: d.string(forKey: K.soundName) ?? "Tink")?.play()
        }
        lastSourceID = source
        if changed { overlay.flash() } else { overlay.update() }
        Hotkey.shared.update()
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

let firstLaunch = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")?.isEmpty ?? true
registerDefaults()
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
