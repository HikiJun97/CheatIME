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

struct GeneralTab: View {
    @StateObject private var login = LoginItem()

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
                LabeledContent("버전", value: version)
            }
        }
        .formStyle(.grouped)
    }
}
