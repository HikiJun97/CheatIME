import AppKit
import UniformTypeIdentifiers

enum SettingsFile {
    private static let app = "CheatIME"
    private static let version = 1
    private static let skipped: Set<String> = [K.settingsTab, K.styleTarget]

    private static var domain: String { Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName }

    private static func exported(_ key: String, _ value: Any) -> Bool {
        !skipped.contains(key) && !key.hasPrefix("SU") && !key.hasPrefix("NS") && !key.hasPrefix("Apple")
            && (value is String || value is NSNumber)
    }

    static func data() throws -> Data {
        let saved = UserDefaults.standard.persistentDomain(forName: domain) ?? [:]
        let settings = saved.filter { exported($0.key, $0.value) }
        return try JSONSerialization.data(withJSONObject: ["app": app, "version": version, "settings": settings],
                                          options: [.prettyPrinted, .sortedKeys])
    }

    static func settings(in data: Data) throws -> [String: Any] {
        guard let file = try? JSONSerialization.jsonObject(with: data) as? [String: Any], file["app"] as? String == app,
              let settings = file["settings"] as? [String: Any]
        else { throw Failure.notSettings }
        return settings
    }

    static func apply(_ settings: [String: Any]) {
        let d = UserDefaults.standard
        for (key, value) in d.persistentDomain(forName: domain) ?? [:] where exported(key, value) {
            d.removeObject(forKey: key)
        }
        for (key, value) in settings where exported(key, value) {
            d.set(value, forKey: key)
        }
    }

    static func export() throws -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "CheatIME Settings.json"
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        try data().write(to: url, options: .atomic)
        return true
    }

    static func `import`() throws -> Bool {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        let settings = try settings(in: Data(contentsOf: url))
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("설정을 가져올까요?", comment: "")
        alert.informativeText = NSLocalizedString("지금 설정이 모두 파일의 설정으로 바뀝니다.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("가져오기", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("취소", comment: ""))
        guard alert.runModal() == .alertFirstButtonReturn else { return false }
        apply(settings)
        return true
    }

    enum Failure: LocalizedError {
        case notSettings

        var errorDescription: String? { NSLocalizedString("CheatIME 설정 파일이 아닙니다.", comment: "") }
    }
}
