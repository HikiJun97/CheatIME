import Combine
import SwiftUI

struct SettingsView: View {
    @AppStorage(K.settingsTab) private var tab = "badge"

    private let panes: [(id: String, title: LocalizedStringKey)] = [
        ("badge", "뱃지"), ("apps", "앱"), ("rules", "자동 전환"), ("general", "일반"),
    ]

    var body: some View {
        let current = panes.contains { $0.id == tab } ? tab : "badge"
        Group {
            switch current {
            case "apps": AppsTab()
            case "rules": RulesTab()
            case "general": GeneralTab()
            default: BadgeTab()
            }
        }
        .frame(width: 620, height: 620)
        .navigationTitle(Text(panes.first { $0.id == current }?.title ?? "뱃지"))
        .toolbar(removing: .title)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("설정", selection: Binding(get: { current }, set: { tab = $0 })) {
                    ForEach(panes, id: \.id) { Text($0.title).tag($0.id) }
                }
                .paneSwitcherStyle()
                .labelsHidden()
            }
        }
    }
}

extension View {
    @ViewBuilder
    func paneSwitcherStyle() -> some View {
        if #available(macOS 27, *) {
            pickerStyle(.tabs)
        } else {
            pickerStyle(.segmented)
        }
    }
}

struct BadgeTab: View {
    @AppStorage(K.styleTarget) private var target = "default"

    var body: some View {
        SubTabs(selection: $target, tabs: [
            ("default", "기본값"), ("fixed", "고정 위치"), ("pointer", "마우스 포인터 옆"), ("caret", "텍스트 커서 옆"),
        ]) { id in
            Form {
                if K.modes.contains(id) {
                    PositionSections(mode: id)
                } else {
                    DefaultSections()
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
}

final class PaneTabView: NSTabView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let size = self.frame.size
            self.setFrameSize(NSSize(width: size.width + 1, height: size.height))
            self.setFrameSize(size)
        }
    }
}

struct SubTabs<Content: View>: NSViewRepresentable {
    @Binding var selection: String
    let tabs: [(id: String, title: String)]
    let content: (String) -> Content

    func makeNSView(context: Context) -> PaneTabView {
        let view = PaneTabView()
        view.delegate = context.coordinator
        for tab in tabs {
            let item = NSTabViewItem(identifier: tab.id)
            item.label = NSLocalizedString(tab.title, comment: "")
            item.view = NSView()
            view.addTabViewItem(item)
        }
        updateNSView(view, context: context)
        return view
    }

    func updateNSView(_ view: PaneTabView, context: Context) {
        context.coordinator.parent = self
        let index = tabs.firstIndex { $0.id == selection } ?? 0
        load(view.tabViewItem(at: index))
        if view.selectedTabViewItem.map(view.indexOfTabViewItem) != index {
            view.selectTabViewItem(at: index)
        }
    }

    func load(_ item: NSTabViewItem) {
        guard let container = item.view, container.subviews.isEmpty, let id = item.identifier as? String else { return }
        let host = NSHostingView(rootView: content(id))
        host.frame = container.bounds
        host.autoresizingMask = [.width, .height]
        container.addSubview(host)
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, NSTabViewDelegate {
        var parent: SubTabs

        init(parent: SubTabs) { self.parent = parent }

        func tabView(_ tabView: NSTabView, willSelect item: NSTabViewItem?) {
            if let item { parent.load(item) }
        }

        func tabView(_ tabView: NSTabView, didSelect item: NSTabViewItem?) {
            if let id = item?.identifier as? String, parent.selection != id { parent.selection = id }
        }
    }
}

struct DefaultSections: View {
    @AppStorage(K.sound) private var sound = false
    @AppStorage(K.soundName) private var soundName = "Tink"

    private let sounds = systemSounds()

    var body: some View {
        StyleSections(scope: "default")
        TimingSection(scope: "default")
        Section("소리") {
            Toggle("입력기가 바뀔 때 소리 내기", isOn: $sound)
            Picker("소리", selection: $soundName) {
                ForEach(sounds, id: \.self) { Text($0).tag($0) }
            }
            .disabled(!sound)
            .onChange(of: soundName) { NSSound(named: soundName)?.play() }
        }
    }
}

struct PositionSections: View {
    let mode: String
    @AppStorage private var show: Bool
    @AppStorage private var useDefault: Bool

    init(mode: String) {
        self.mode = mode
        _show = AppStorage(wrappedValue: mode == "fixed", K.show(mode))
        _useDefault = AppStorage(wrappedValue: true, K.useDefault(mode))
    }

    var body: some View {
        Section {
            Toggle("표시", isOn: $show)
                .onChange(of: show) {
                    if mode == "caret" && show { _ = accessibilityTrusted(prompt: true) }
                }
            Toggle("기본값 따르기", isOn: $useDefault)
                .onChange(of: useDefault) {
                    if !useDefault { copyDefaultStyle(to: mode) }
                }
            Text("끄면 이 위치의 스타일과 표시 시점을 따로 정합니다.")
                .foregroundStyle(.secondary)
        }
        if mode == "caret" {
            CaretSection()
        }
        if !useDefault {
            StyleSections(scope: mode)
            TimingSection(scope: mode)
        }
        if mode == "fixed" {
            FixedSections()
        }
    }
}

struct StyleSections: View {
    let scope: String
    @AppStorage private var shape: String
    @AppStorage private var fontSize: Double
    @AppStorage private var dotSize: Double
    @AppStorage private var opacity: Double
    @AppStorage private var glass: Bool
    @AppStorage private var border: String
    @AppStorage private var borderWidth: Double
    @AppStorage private var borderColor: String

    @AppStorage(K.badgeLanguages) private var order = ""
    @StateObject private var drag = LanguageDrag()
    private var languages: [String] { order.split(separator: ",").map(String.init) }

    init(scope: String) {
        self.scope = scope
        func key(_ name: String) -> String { K.style(scope, name) }
        _shape = AppStorage(wrappedValue: "rounded", key(K.shape))
        _fontSize = AppStorage(wrappedValue: 15.0, key(K.fontSize))
        _dotSize = AppStorage(wrappedValue: 12.0, key(K.dotSize))
        _opacity = AppStorage(wrappedValue: 0.9, key(K.opacity))
        _glass = AppStorage(wrappedValue: false, key(K.glass))
        _border = AppStorage(wrappedValue: "none", key(K.border))
        _borderWidth = AppStorage(wrappedValue: 2.0, key(K.borderWidth))
        _borderColor = AppStorage(wrappedValue: "#FFFFFF", key(K.borderColor))
    }

    var body: some View {
        if scope == "default" {
            Section("언어별 표시") {
                VStack(spacing: 0) {
                    LanguageColumns(
                        name: Text("언어"), label: Text("표시 글자"), bg: Text("배경"), fg: Text("글자"),
                        hidden: Text("숨기기"), preview: Text("미리보기"), menu: Color.clear
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
                    Divider()
                    ForEach(Array(languages.enumerated()), id: \.element) { index, lang in
                        LanguageRow(lang: lang, index: index, style: preview(""), order: $order, drag: drag)
                    }
                }
                Button("입력 소스 새로고침") { InputSources.shared.reload() }
            }
        }
        Section("뱃지 스타일") {
            if scope != "default" {
                HStack {
                    Text("미리보기")
                    Spacer()
                    ForEach(languages, id: \.self) { preview($0) }
                }
            }
            Picker("모양", selection: $shape) {
                Text("둥근 사각형").tag("rounded")
                Text("캡슐").tag("capsule")
                Text("원").tag("circle")
                Text("점").tag("dot")
            }
            .pickerStyle(.segmented)
            if #available(macOS 26, *) {
                Toggle("유리 효과 (Liquid Glass)", isOn: $glass)
            }
            if shape == "dot" {
                NumberSlider(title: "점 크기", value: $dotSize, range: 4...40)
            } else {
                NumberSlider(title: "글자 크기", value: $fontSize, range: 10...48)
            }
            NumberSlider(title: "불투명도 (%)", value: Binding(get: { opacity * 100 }, set: { opacity = $0 / 100 }),
                         range: 20...100)
            if !glass {
                Picker("테두리", selection: $border) {
                    Text("없음").tag("none")
                    Text("실선").tag("solid")
                    Text("파선").tag("dashed")
                    Text("점선").tag("dotted")
                }
                .pickerStyle(.segmented)
                if border != "none" {
                    NumberSlider(title: "테두리 두께", value: $borderWidth, range: 1...8)
                    ColorPicker("테두리 색", selection: Binding(get: { Color(hex: borderColor) },
                                                             set: { borderColor = $0.hex }),
                                supportsOpacity: false)
                }
            }
        }
    }

    private func preview(_ lang: String) -> BadgeView {
        var badge = BadgeView(lang: lang, scope: scope)
        badge.shape = shape
        badge.fontSize = min(fontSize, 20)
        badge.dotSize = min(dotSize, 20)
        badge.opacity = opacity
        badge.glass = glass
        badge.border = border
        badge.borderWidth = borderWidth
        badge.borderColor = Color(hex: borderColor)
        badge.inset = 0
        return badge
    }
}

struct TimingSection: View {
    @AppStorage private var flashOnly: Bool
    @AppStorage private var flashDuration: Double

    init(scope: String) {
        _flashOnly = AppStorage(wrappedValue: false, K.style(scope, K.flashOnly))
        _flashDuration = AppStorage(wrappedValue: 1200.0, K.style(scope, K.flashDuration))
    }

    var body: some View {
        Section("표시 시점") {
            Toggle("입력기가 바뀔 때만 잠깐 표시", isOn: $flashOnly)
            NumberSlider(title: "표시 시간 (ms)", value: $flashDuration, range: 300...5000)
                .disabled(!flashOnly)
        }
    }
}

struct CaretSection: View {
    @AppStorage(K.caretFallback) private var caretFallback = true
    @AppStorage(K.showPointer) private var showPointer = false

    var body: some View {
        Section("텍스트 커서") {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                if AXIsProcessTrusted() {
                    Label("텍스트 커서 위치를 읽을 권한이 허용되어 있습니다.", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                } else {
                    HStack {
                        Label("텍스트 커서 위치를 읽으려면 권한이 필요합니다.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Spacer()
                        Button("권한 설정 열기", action: openAccessibilitySettings)
                    }
                }
            }
            Toggle("텍스트 커서를 찾지 못하면 마우스 포인터 옆에 표시", isOn: $caretFallback)
                .disabled(showPointer)
            Text("마우스 포인터 옆에 상시로 띄울 때보다 움직임이 덜 부드럽습니다.")
                .foregroundStyle(.secondary)
        }
    }
}

final class ScreenList: ObservableObject {
    @Published private(set) var screens = NSScreen.screens
    private var subscription: AnyCancellable?

    init() {
        subscription = NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.screens = NSScreen.screens }
            }
    }

    var maxMarginX: Double { (screens.map(\.visibleFrame.width).max() ?? 800) / 2 }
    var maxMarginY: Double { (screens.map(\.visibleFrame.height).max() ?? 600) / 2 }
}

struct FixedSections: View {
    @AppStorage(K.displayMode) private var displayMode = "all"
    @AppStorage(K.displays) private var displays = ""
    @AppStorage(K.hAlign) private var hAlign = "right"
    @AppStorage(K.vAlign) private var vAlign = "bottom"
    @AppStorage(K.marginX) private var marginX = 12.0
    @AppStorage(K.marginY) private var marginY = 12.0

    @StateObject private var screenList = ScreenList()

    var body: some View {
        Section("디스플레이") {
            Picker("표시할 곳", selection: $displayMode) {
                Text("모든 디스플레이").tag("all")
                Text("마우스가 있는 디스플레이").tag("mouse")
                Text("직접 선택").tag("selected")
            }
            if displayMode == "selected" {
                ForEach(screenList.screens, id: \.uuid) { screen in
                    Toggle(screen.localizedName, isOn: chosen(screen.uuid))
                }
            }
        }
        Section("위치") {
            Picker("가로", selection: $hAlign) {
                Text("왼쪽").tag("left")
                Text("가운데").tag("center")
                Text("오른쪽").tag("right")
            }
            .pickerStyle(.segmented)
            Picker("세로", selection: $vAlign) {
                Text("위").tag("top")
                Text("가운데").tag("middle")
                Text("아래").tag("bottom")
            }
            .pickerStyle(.segmented)
            NumberSlider(title: "가로 여백", value: $marginX, range: 0...screenList.maxMarginX)
            NumberSlider(title: "세로 여백", value: $marginY, range: 0...screenList.maxMarginY)
        }
    }

    private func chosen(_ uuid: String) -> Binding<Bool> {
        Binding(
            get: { displays.split(separator: ",").contains(Substring(uuid)) },
            set: { on in
                var ids = displays.split(separator: ",").map(String.init).filter { $0 != uuid }
                if on { ids.append(uuid) }
                displays = ids.joined(separator: ",")
            })
    }
}

struct NumberSlider: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack {
            Slider(value: Binding(get: { value }, set: { value = $0.rounded() }), in: range) { Text(title) }
            TextField(title, value: Binding(get: { value.rounded() },
                                            set: { value = min(max($0, range.lowerBound), range.upperBound) }),
                      format: .number.grouping(.never).precision(.fractionLength(0)))
                .labelsHidden()
                .roundedInputBorder()
                .multilineTextAlignment(.trailing)
                .frame(width: 56)
        }
    }
}

final class LanguageDrag: ObservableObject {
    @Published var dragging: String?
    @Published var insertion: Int?
}

func movedLanguages(_ langs: [String], _ lang: String, to insertion: Int) -> [String] {
    guard let from = langs.firstIndex(of: lang) else { return langs }
    var result = langs
    result.remove(at: from)
    result.insert(lang, at: min(from < insertion ? insertion - 1 : insertion, result.count))
    return result
}

struct LanguageColumns<Name: View, Label: View, Bg: View, Fg: View, Hidden: View, Preview: View, Menu: View>: View {
    let name: Name
    let label: Label
    let bg: Bg
    let fg: Fg
    let hidden: Hidden
    let preview: Preview
    let menu: Menu

    var body: some View {
        HStack(spacing: 16) {
            name.frame(maxWidth: .infinity, alignment: .leading)
            label.frame(width: 56, alignment: .leading)
            bg.frame(width: 44)
            fg.frame(width: 44)
            hidden.frame(width: 44)
            preview.frame(width: 60, alignment: .trailing)
            menu.frame(width: 20)
        }
    }
}

struct LanguageDropDelegate: DropDelegate {
    static let rowHeight: CGFloat = 40
    let index: Int
    let drag: LanguageDrag
    @Binding var order: String

    func validateDrop(info: DropInfo) -> Bool { drag.dragging != nil }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        let insertion = info.location.y < Self.rowHeight / 2 ? index : index + 1
        if drag.insertion != insertion { drag.insertion = insertion }
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        if drag.insertion == index || drag.insertion == index + 1 { drag.insertion = nil }
    }

    func performDrop(info: DropInfo) -> Bool {
        defer { drag.dragging = nil; drag.insertion = nil }
        guard let lang = drag.dragging, let insertion = drag.insertion else { return false }
        let langs = order.split(separator: ",").map(String.init)
        order = movedLanguages(langs, lang, to: insertion).joined(separator: ",")
        return true
    }
}

struct LanguageRow: View {
    let lang: String
    let index: Int
    let style: BadgeView
    @Binding var order: String
    @ObservedObject var drag: LanguageDrag
    @AppStorage private var label: String
    @AppStorage private var bg: String
    @AppStorage private var fg: String
    @AppStorage private var hidden: Bool

    init(lang: String, index: Int, style: BadgeView, order: Binding<String>, drag: LanguageDrag) {
        self.lang = lang
        self.index = index
        self.style = style
        _order = order
        self.drag = drag
        let d = langDefaults(lang)
        _label = AppStorage(wrappedValue: d.label, K.label(lang))
        _bg = AppStorage(wrappedValue: d.bg, K.bg(lang))
        _fg = AppStorage(wrappedValue: d.fg, K.fg(lang))
        _hidden = AppStorage(wrappedValue: false, K.hidden(lang))
    }

    var body: some View {
        LanguageColumns(
            name: handle,
            label: TextField("표시 글자", text: $label).labelsHidden().roundedInputBorder(),
            bg: ColorPicker("배경", selection: color($bg), supportsOpacity: false).labelsHidden(),
            fg: ColorPicker("글자", selection: color($fg), supportsOpacity: false).labelsHidden(),
            hidden: Toggle("숨기기", isOn: $hidden).labelsHidden(),
            preview: preview,
            menu: menu
        )
        .frame(height: LanguageDropDelegate.rowHeight)
        .contentShape(Rectangle())
        .overlay(alignment: .top) { indicator(at: index) }
        .overlay(alignment: .bottom) { indicator(at: index + 1).opacity(list.last == lang ? 1 : 0) }
        .onDrop(of: [Self.dragType], delegate: LanguageDropDelegate(index: index, drag: drag, order: $order))
    }

    private static let dragType = "io.github.hikijun97.cheatime.language"

    private var handle: some View {
        HStack(spacing: 6) {
            Image(systemName: "line.3.horizontal").foregroundStyle(.tertiary)
            Text(Locale.current.localizedString(forLanguageCode: lang) ?? lang).lineLimit(1)
        }
        .contentShape(Rectangle())
        .onDrag {
            drag.dragging = lang
            let provider = NSItemProvider()
            provider.registerDataRepresentation(forTypeIdentifier: Self.dragType, visibility: .ownProcess) { done in
                done(Data(), nil)
                return nil
            }
            return provider
        }
    }

    private var menu: some View {
        Menu {
            Button("위로 이동") { move(by: -1) }.disabled(list.first == lang)
            Button("아래로 이동") { move(by: 1) }.disabled(list.last == lang)
            Divider()
            Button("목록에서 제거") { order = list.filter { $0 != lang }.joined(separator: ",") }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    @ViewBuilder
    private func indicator(at insertion: Int) -> some View {
        if drag.insertion == insertion, let dragging = drag.dragging,
           movedLanguages(list, dragging, to: insertion) != list {
            Capsule()
                .fill(Color.accentColor)
                .frame(height: 3)
                .offset(y: insertion == index ? -1.5 : 1.5)
                .allowsHitTesting(false)
        }
    }

    private var list: [String] { order.split(separator: ",").map(String.init) }

    private func move(by offset: Int) {
        var langs = list
        guard let i = langs.firstIndex(of: lang), langs.indices.contains(i + offset) else { return }
        langs.swapAt(i, i + offset)
        order = langs.joined(separator: ",")
    }

    private var preview: BadgeView {
        var badge = style
        badge.label = label
        badge.bg = Color(hex: bg)
        badge.fg = Color(hex: fg)
        if hidden { badge.opacity = 0.2 }
        return badge
    }

    private func color(_ hex: Binding<String>) -> Binding<Color> {
        Binding(get: { Color(hex: hex.wrappedValue) }, set: { hex.wrappedValue = $0.hex })
    }
}

extension View {
    @ViewBuilder
    func roundedInputBorder() -> some View {
        if #available(macOS 27, *) {
            textFieldStyle(.bordered).textInputBorderShape(.roundedRectangle)
        } else {
            textFieldStyle(.roundedBorder)
        }
    }
}
