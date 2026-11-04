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
}

final class AppLanguage: ObservableObject {
    static let languages = ["en", "ko", "ja"]
    private let initial: String
    @Published var selection: String {
        didSet {
            if selection == "system" {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set([selection], forKey: "AppleLanguages")
            }
        }
    }

    var changed: Bool { selection != initial }

    init() {
        let saved = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName)?["AppleLanguages"]
        let first = (saved as? [String])?.first.map { String($0.prefix(2)) }
        initial = first.flatMap { Self.languages.contains($0) ? $0 : nil } ?? "system"
        selection = initial
    }

    func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
}

struct GeneralTab: View {
    @StateObject private var login = LoginItem()
    @StateObject private var language = AppLanguage()

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
                }
            }
            Section {
                LabeledContent("버전", value: version)
            }
        }
        .formStyle(.grouped)
    }
}
