import Carbon
import SwiftUI

final class Hotkey {
    static let shared = Hotkey()
    var action: () -> Void = {}
    var paused = false {
        didSet { paused ? unregister() : update() }
    }
    private var ref: EventHotKeyRef?
    private var registered: [Int]?

    private init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            MainActor.assumeIsolated { Hotkey.shared.action() }
            return noErr
        }, 1, &spec, nil, nil)
    }

    func update() {
        let d = UserDefaults.standard
        let key = d[K.toggleKey], modifiers = d[K.toggleModifiers]
        guard !paused, registered != [key, modifiers] else { return }
        unregister()
        guard key >= 0 else { return }
        let status = RegisterEventHotKey(UInt32(key), UInt32(modifiers), EventHotKeyID(signature: 0x4348_4954, id: 1),
                                         GetApplicationEventTarget(), 0, &ref)
        if status == noErr { registered = [key, modifiers] }
    }

    private func unregister() {
        if let ref { UnregisterEventHotKey(ref) }
        ref = nil
        registered = nil
    }
}

func shortcutName(key: Int, modifiers: Int) -> String {
    var name = ""
    if modifiers & controlKey != 0 { name += "⌃" }
    if modifiers & optionKey != 0 { name += "⌥" }
    if modifiers & shiftKey != 0 { name += "⇧" }
    if modifiers & cmdKey != 0 { name += "⌘" }
    return name + keyName(key)
}

private func keyName(_ key: Int) -> String {
    let fKeys = [kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10,
                 kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20]
    if let i = fKeys.firstIndex(of: key) { return "F\(i + 1)" }
    let special = [kVK_Space: "␣", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
                   kVK_Escape: "⎋", kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
                   kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
                   kVK_ANSI_KeypadClear: "⌧", kVK_ANSI_KeypadEnter: "⌤"]
    if let name = special[key] { return name }
    let keypad = [kVK_ANSI_Keypad0: "0", kVK_ANSI_Keypad1: "1", kVK_ANSI_Keypad2: "2", kVK_ANSI_Keypad3: "3",
                  kVK_ANSI_Keypad4: "4", kVK_ANSI_Keypad5: "5", kVK_ANSI_Keypad6: "6", kVK_ANSI_Keypad7: "7",
                  kVK_ANSI_Keypad8: "8", kVK_ANSI_Keypad9: "9", kVK_ANSI_KeypadDecimal: ".",
                  kVK_ANSI_KeypadMultiply: "*", kVK_ANSI_KeypadPlus: "+", kVK_ANSI_KeypadMinus: "-",
                  kVK_ANSI_KeypadDivide: "/", kVK_ANSI_KeypadEquals: "="]
    if let name = keypad[key] { return String(format: NSLocalizedString("키패드 %@", comment: ""), name) }
    guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
          let data = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
    else { return "?" }
    let layout = Unmanaged<CFData>.fromOpaque(data).takeUnretainedValue()
    var dead: UInt32 = 0
    var chars = [UniChar](repeating: 0, count: 4)
    var length = 0
    CFDataGetBytePtr(layout).withMemoryRebound(to: UCKeyboardLayout.self, capacity: 1) { layout in
        _ = UCKeyTranslate(layout, UInt16(key), UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
                           OptionBits(kUCKeyTranslateNoDeadKeysMask), &dead, chars.count, &length, &chars)
    }
    return String(utf16CodeUnits: chars, count: length).uppercased()
}

final class ShortcutRecording: ObservableObject {
    @Published private(set) var monitor: Any?
    private var observers: [NSObjectProtocol] = []

    func start() {
        Hotkey.shared.paused = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated { self?.record(event) }
            return nil
        }
        let stop: @Sendable (Notification) -> Void = { [weak self] _ in
            MainActor.assumeIsolated { self?.stop() }
        }
        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main, using: stop),
            center.addObserver(forName: NSWindow.willCloseNotification, object: NSApp.keyWindow, queue: .main, using: stop),
        ]
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        Hotkey.shared.paused = false
    }

    private func record(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if Int(event.keyCode) == kVK_Escape && flags.isEmpty { return stop() }
        guard !flags.isDisjoint(with: [.command, .option, .control]) else { return NSSound.beep() }
        var carbon = 0
        if flags.contains(.command) { carbon |= cmdKey }
        if flags.contains(.option) { carbon |= optionKey }
        if flags.contains(.control) { carbon |= controlKey }
        if flags.contains(.shift) { carbon |= shiftKey }
        let d = UserDefaults.standard
        d[K.toggleKey] = Int(event.keyCode)
        d[K.toggleModifiers] = carbon
        stop()
    }
}

struct ShortcutRecorder: View {
    @AppStorage(K.toggleKey) private var key: Int
    @AppStorage(K.toggleModifiers) private var modifiers: Int
    @StateObject private var recording = ShortcutRecording()

    var body: some View {
        HStack {
            Button {
                recording.monitor == nil ? recording.start() : recording.stop()
            } label: {
                if recording.monitor != nil {
                    Text("키를 누르세요")
                } else if key < 0 {
                    Text("단축키 입력")
                } else {
                    Text(verbatim: shortcutName(key: key, modifiers: modifiers))
                }
            }
            if key >= 0 && recording.monitor == nil {
                Button {
                    key = -1
                    modifiers = 0
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .help("지우기")
            }
        }
        .onDisappear(perform: recording.stop)
    }
}
