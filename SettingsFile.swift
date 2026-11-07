import AppKit
import UniformTypeIdentifiers

enum SettingsFile {
    private static let app = "CheatIME"
    private static let version = 1

    private static func portable(_ key: String) -> Bool {
        K.portable[key] != nil || key.hasPrefix("lang.") || key.hasPrefix("mode.")
    }

    private static func exported(_ key: String, _ value: Any) -> Bool {
        guard portable(key) else { return false }
        if let expected = K.portable[key] { return sameType(value, expected) }
        return value is String || value is NSNumber
    }

    private static func sameType(_ value: Any, _ expected: Any) -> Bool {
        switch (value, expected) {
        case (is String, is String): true
        case let (a as NSNumber, b as NSNumber): isBool(a) == isBool(b)
        default: false
        }
    }

    private static func isBool(_ n: NSNumber) -> Bool { CFGetTypeID(n) == CFBooleanGetTypeID() }

    static func data() throws -> Data {
        let settings = savedSettings().filter { exported($0.key, $0.value) }
        return try JSONSerialization.data(withJSONObject: ["app": app, "version": version, "settings": settings],
                                          options: [.prettyPrinted, .sortedKeys])
    }

    static func settings(in data: Data) throws -> [String: Any] {
        guard let file = try? JSONSerialization.jsonObject(with: data) as? [String: Any], file["app"] as? String == app,
              let settings = file["settings"] as? [String: Any]
        else { throw Failure.notSettings }
        guard file["version"] as? Int ?? version <= version else { throw Failure.newerVersion }
        return settings
    }

    static func apply(_ settings: [String: Any]) {
        let d = UserDefaults.standard
        for key in savedSettings().keys where portable(key) {
            d.removeObject(forKey: key)
        }
        for (key, value) in settings where exported(key, value) {
            d.set(value, forKey: key)
        }
        migrate()
        InputSources.shared.reload()
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
        case newerVersion

        var errorDescription: String? {
            switch self {
            case .notSettings: NSLocalizedString("CheatIME 설정 파일이 아닙니다.", comment: "")
            case .newerVersion: NSLocalizedString("더 새로운 버전의 CheatIME에서 만든 설정 파일입니다. CheatIME를 업데이트한 뒤 다시 가져오세요.", comment: "")
            }
        }
    }
}
