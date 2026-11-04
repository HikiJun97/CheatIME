import SwiftUI

struct AppInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
}

func installedApps() -> [AppInfo] {
    let fm = FileManager.default
    let dirs = ["/Applications", "/Applications/Utilities", "/System/Applications", "/System/Applications/Utilities",
                fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path]
    var paths = dirs.flatMap { dir in
        ((try? fm.contentsOfDirectory(atPath: dir)) ?? []).filter { $0.hasSuffix(".app") && !$0.hasPrefix(".") }.map { "\(dir)/\($0)" }
    }
    paths += NSWorkspace.shared.runningApplications
        .filter { $0.activationPolicy == .regular }
        .compactMap { $0.bundleURL?.path }
    var seen = Set<String>()
    var apps: [AppInfo] = []
    for path in paths {
        guard let app = appInfo(at: URL(fileURLWithPath: path)), app.id != Bundle.main.bundleIdentifier,
              seen.insert(app.id).inserted else { continue }
        apps.append(app)
    }
    return apps.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
}

func appInfo(at url: URL) -> AppInfo? {
    guard let id = Bundle(url: url)?.bundleIdentifier else { return nil }
    var name = FileManager.default.displayName(atPath: url.path)
    if name.hasSuffix(".app") { name = String(name.dropLast(4)) }
    return AppInfo(id: id, name: name, path: url.path)
}

func appInfo(id: String) -> AppInfo? {
    NSWorkspace.shared.urlForApplication(withBundleIdentifier: id).flatMap(appInfo(at:))
}

struct AppLabel: View {
    let app: AppInfo

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                .resizable()
                .frame(width: 18, height: 18)
            Text(app.name)
        }
    }
}

final class SearchText: ObservableObject {
    @Published var value = ""
}

struct AppsTab: View {
    @AppStorage(K.appFilter) private var appFilter = false
    @AppStorage(K.filterApps) private var filterApps = ""
    @StateObject private var search = SearchText()

    private let apps = installedApps()

    var body: some View {
        let chosen = Set(filterApps.split(separator: ",").map(String.init))
        let query = search.value
        let matches = apps.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
        let on = matches.filter { chosen.contains($0.id) }
        let off = matches.filter { !chosen.contains($0.id) }
        Form {
            Section {
                Toggle("선택한 앱이 앞에 있을 때만 뱃지 표시", isOn: $appFilter)
                TextField("앱 검색", text: $search.value)
                    .roundedInputBorder()
            }
            Section("선택한 앱 (\(on.count))") {
                if on.isEmpty {
                    Text("체크한 앱이 여기에 표시됩니다.").foregroundStyle(.secondary)
                }
                ForEach(on) { app in
                    Toggle(isOn: binding(app.id)) { AppLabel(app: app) }.toggleStyle(.checkbox)
                }
            }
            .disabled(!appFilter)
            Section("다른 앱 (\(off.count))") {
                ForEach(off) { app in
                    Toggle(isOn: binding(app.id)) { AppLabel(app: app) }.toggleStyle(.checkbox)
                }
            }
            .disabled(!appFilter)
        }
        .formStyle(.grouped)
    }

    private func binding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { filterApps.split(separator: ",").contains(Substring(id)) },
            set: { on in
                var ids = filterApps.split(separator: ",").map(String.init).filter { $0 != id }
                if on { ids.append(id) }
                filterApps = ids.joined(separator: ",")
            })
    }
}
