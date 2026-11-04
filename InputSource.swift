import Cocoa
import Carbon

func property<T>(_ src: TISInputSource, _ key: CFString) -> T? {
    guard let ptr = TISGetInputSourceProperty(src, key) else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue() as? T
}

func currentLanguage() -> String {
    let src = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    let langs: [String] = property(src, kTISPropertyInputSourceLanguages) ?? []
    return langs.first ?? ""
}

nonisolated struct InputSourceInfo: Hashable, Codable {
    let id: String
    let name: String
    let lang: String
}

func enabledInputSources() -> [InputSourceInfo] {
    let list = TISCreateInputSourceList(nil, false).takeRetainedValue() as! [TISInputSource]
    return list.compactMap { src in
        let category: String? = property(src, kTISPropertyInputSourceCategory)
        let selectable: Bool = property(src, kTISPropertyInputSourceIsSelectCapable) ?? false
        guard category == kTISCategoryKeyboardInputSource as String, selectable,
              let id: String = property(src, kTISPropertyInputSourceID) else { return nil }
        let langs: [String] = property(src, kTISPropertyInputSourceLanguages) ?? []
        return InputSourceInfo(id: id, name: property(src, kTISPropertyLocalizedName) ?? id, lang: langs.first ?? "")
    }
}

final class InputSources: ObservableObject {
    static let shared = InputSources()
    nonisolated static let listArgument = "--list-input-sources"
    @Published private(set) var sources: [InputSourceInfo] = []
    @Published private(set) var languages: [String] = []

    private init() {
        apply(enabledInputSources())
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String),
            object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { InputSources.shared.reload() }
        }
        reload()
    }

    private func apply(_ new: [InputSourceInfo]) {
        if new != sources { sources = new }
        var langs: [String] = []
        for source in new where !source.lang.isEmpty && !langs.contains(source.lang) {
            langs.append(source.lang)
        }
        if langs != languages { languages = langs }
    }

    private func reload() {
        guard let url = Bundle.main.executableURL else { return }
        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = url
            process.arguments = [Self.listArgument]
            let pipe = Pipe()
            process.standardOutput = pipe
            guard (try? process.run()) != nil else { return }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard let list = try? JSONDecoder().decode([InputSourceInfo].self, from: data) else { return }
            DispatchQueue.main.async { InputSources.shared.apply(list) }
        }
    }
}

func currentInputSourceID() -> String {
    property(TISCopyCurrentKeyboardInputSource().takeRetainedValue(), kTISPropertyInputSourceID) ?? ""
}

func selectInputSource(_ id: String) {
    guard id != currentInputSourceID() else { return }
    let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
    let list = TISCreateInputSourceList(filter, false).takeRetainedValue() as! [TISInputSource]
    if let src = list.first { TISSelectInputSource(src) }
}

extension NSScreen {
    var uuid: String {
        let id = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID
        guard let cf = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return "\(id)" }
        return CFUUIDCreateString(nil, cf) as String
    }
}
