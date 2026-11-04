import SwiftUI
import UniformTypeIdentifiers

struct SwitchRule: Codable, Identifiable, Hashable {
    var id = UUID()
    var app: String
    var source: String
    var restore = false
    var enabled = true
}

func decodeRules(_ json: String) -> [SwitchRule] {
    (try? JSONDecoder().decode([SwitchRule].self, from: Data(json.utf8))) ?? []
}

func encodeRules(_ rules: [SwitchRule]) -> String {
    (try? String(data: JSONEncoder().encode(rules), encoding: .utf8)) ?? "[]"
}

final class Switcher {
    private var pending: (app: String, source: String)?

    func appActivated(_ app: String) {
        guard app != Bundle.main.bundleIdentifier else { return }
        if let pending, pending.app != app {
            selectInputSource(pending.source)
            self.pending = nil
        }
        let rules = decodeRules(UserDefaults.standard.string(forKey: K.rules) ?? "[]")
        guard let rule = rules.first(where: { $0.enabled && $0.app == app }) else { return }
        if rule.restore && pending == nil {
            pending = (app, currentInputSourceID())
        }
        selectInputSource(rule.source)
    }
}

struct RulesTab: View {
    @AppStorage(K.rules) private var rulesJSON = "[]"

    @ObservedObject private var inputs = InputSources.shared
    private var sources: [InputSourceInfo] { inputs.sources }

    var body: some View {
        let rules = decodeRules(rulesJSON)
        Form {
            Section {
                Text("앱이 앞으로 나올 때 입력기를 자동으로 바꿉니다.")
                    .foregroundStyle(.secondary)
            }
            Section("규칙") {
                if rules.isEmpty {
                    Text("아직 규칙이 없습니다.").foregroundStyle(.secondary)
                }
                ForEach(rules) { rule in
                    RuleRow(rule: binding(rule.id), sources: sources) { remove(rule.id) }
                }
            }
            Section {
                Button("앱 추가…", action: addRule)
            }
        }
        .formStyle(.grouped)
    }

    private func binding(_ id: UUID) -> Binding<SwitchRule> {
        Binding(
            get: { decodeRules(rulesJSON).first { $0.id == id } ?? SwitchRule(app: "", source: "") },
            set: { new in
                rulesJSON = encodeRules(decodeRules(rulesJSON).map { $0.id == id ? new : $0 })
            })
    }

    private func remove(_ id: UUID) {
        rulesJSON = encodeRules(decodeRules(rulesJSON).filter { $0.id != id })
    }

    private func addRule() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK, let url = panel.url, let app = appInfo(at: url) else { return }
        var rules = decodeRules(rulesJSON)
        guard !rules.contains(where: { $0.app == app.id }) else { return }
        let source = sources.first { $0.lang == "en" } ?? sources.first
        rules.append(SwitchRule(app: app.id, source: source?.id ?? ""))
        rulesJSON = encodeRules(rules)
    }
}

struct RuleRow: View {
    @Binding var rule: SwitchRule
    let sources: [InputSourceInfo]
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Toggle("사용", isOn: $rule.enabled)
                    .labelsHidden()
                    .toggleStyle(.checkbox)
                if let app = appInfo(id: rule.app) {
                    AppLabel(app: app)
                } else {
                    Text(rule.app)
                }
                Spacer()
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                Picker("입력기", selection: $rule.source) {
                    ForEach(sources, id: \.id) { Text($0.name).tag($0.id) }
                }
                .labelsHidden()
                .frame(width: 170)
                Button(action: onDelete) {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
                .help("규칙 삭제")
            }
            Toggle("앱을 떠날 때 이전 입력기로 되돌리기", isOn: $rule.restore)
                .toggleStyle(.checkbox)
                .padding(.leading, 26)
        }
        .opacity(rule.enabled ? 1 : 0.5)
    }
}
