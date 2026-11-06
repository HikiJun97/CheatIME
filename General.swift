import SwiftUI
import ServiceManagement

final class LoginItem: ObservableObject {
    @Published var status = SMAppService.mainApp.status
    @Published var error: String?

    func set(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        status = SMAppService.mainApp.status
    }

    func refresh() {
        status = SMAppService.mainApp.status
    }
}

final class AppLanguage: ObservableObject {
    static let languages = ["en", "ko", "ja"]
    private static let initial = savedLanguage()
    @Published var relaunchError: String?
    @Published var selection: String {
        didSet {
            if selection == "system" {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set([selection], forKey: "AppleLanguages")
            }
        }
    }

    var changed: Bool { selection != Self.initial }

    init() {
        Self.captureLaunchLanguage()
        selection = Self.savedLanguage()
    }

    static func captureLaunchLanguage() {
        _ = initial
    }

    private static func savedLanguage() -> String {
        let saved = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName)?["AppleLanguages"]
        let first = (saved as? [String])?.first.map { String($0.prefix(2)) }
        return first.flatMap { languages.contains($0) ? $0 : nil } ?? "system"
    }

    func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, error in
            let message = error?.localizedDescription
            Task { @MainActor in
                if let message {
                    self.relaunchError = message
                } else {
                    NSApp.terminate(nil)
                }
            }
        }
    }
}

final class SettingsFileState: ObservableObject {
    @Published var message: String?
    @Published var failed = false

    func run(_ action: () throws -> String?) {
        do {
            message = try action()
            failed = false
        } catch {
            message = error.localizedDescription
            failed = true
        }
    }
}

struct GeneralTab: View {
    @StateObject private var login = LoginItem()
    @StateObject private var language = AppLanguage()
    @ObservedObject private var updates = Updates.shared
    @StateObject private var settingsFile = SettingsFileState()

    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"

    var body: some View {
        Form {
            Section {
                Toggle("로그인 시 실행", isOn: Binding(get: { login.status == .enabled }, set: { login.set($0) }))
                if login.status == .requiresApproval {
                    HStack {
                        Text("시스템 설정에서 승인해야 합니다.").foregroundStyle(.orange)
                        Spacer()
                        Button("로그인 항목 열기") { SMAppService.openSystemSettingsLoginItems() }
                    }
                }
                if let error = login.error {
                    Text(error).foregroundStyle(.red)
                }
            }
            Section {
                LabeledContent("뱃지 켜기/끄기 단축키") { ShortcutRecorder() }
            }
            Section {
                Picker("언어", selection: $language.selection) {
                    Text("시스템 언어").tag("system")
                    Text(verbatim: "English").tag("en")
                    Text(verbatim: "한국어").tag("ko")
                    Text(verbatim: "日本語").tag("ja")
                }
                if language.changed {
                    HStack {
                        Text("CheatIME를 다시 시작하면 적용됩니다.").foregroundStyle(.secondary)
                        Spacer()
                        Button("다시 시작", action: language.relaunch)
                    }
                    if let error = language.relaunchError {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            Section {
                LabeledContent("설정 파일") {
                    HStack {
                        Button("내보내기…") { settingsFile.run { try SettingsFile.export() ? String(localized: "설정을 내보냈습니다.") : nil } }
                        Button("가져오기…") {
                            settingsFile.run { try SettingsFile.import() ? String(localized: "설정을 가져왔습니다.") : nil }
                        }
                    }
                }
                if let message = settingsFile.message {
                    Text(message).foregroundStyle(settingsFile.failed ? .red : .secondary)
                }
            }
            Section {
                Toggle("자동으로 업데이트 확인", isOn: Binding(get: { updates.automaticallyChecks }, set: { updates.automaticallyChecks = $0 }))
                LabeledContent("버전") {
                    HStack {
                        Text(version)
                        Button("업데이트 확인…", action: updates.check)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            login.refresh()
        }
    }
}
