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

    @ObservedObject private var inputs = InputSources.shared

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
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow {
                        Text("언어")
                        Text("표시 글자")
                        Text("배경").gridColumnAlignment(.center)
                        Text("글자").gridColumnAlignment(.center)
                        Text("숨기기").gridColumnAlignment(.center)
                        Text("미리보기").frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Divider()
                    ForEach(inputs.languages, id: \.self) { lang in
                        LanguageRow(lang: lang, style: preview(""))
                    }
                }
            }
        }
        Section("뱃지 스타일") {
            if scope != "default" {
                HStack {
                    Text("미리보기")
                    Spacer()
                    ForEach(inputs.languages, id: \.self) { preview($0) }
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
            Text("마우스 포인터 옆이 켜져 있으면 겹치지 않도록 표시하지 않습니다.")
                .foregroundStyle(.secondary)
        }
    }
}

struct FixedSections: View {
    @AppStorage(K.displayMode) private var displayMode = "all"
    @AppStorage(K.displays) private var displays = ""
    @AppStorage(K.hAlign) private var hAlign = "right"
    @AppStorage(K.vAlign) private var vAlign = "bottom"
    @AppStorage(K.marginX) private var marginX = 12.0
    @AppStorage(K.marginY) private var marginY = 12.0

    private let screens = NSScreen.screens
    private let maxMargin = (NSScreen.screens.map { max($0.visibleFrame.width, $0.visibleFrame.height) }.max() ?? 800) / 2

    var body: some View {
        Section("디스플레이") {
            Picker("표시할 곳", selection: $displayMode) {
                Text("모든 디스플레이").tag("all")
                Text("마우스가 있는 디스플레이").tag("mouse")
                Text("직접 선택").tag("selected")
            }
            if displayMode == "selected" {
                ForEach(screens, id: \.uuid) { screen in
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
            NumberSlider(title: "가로 여백", value: $marginX, range: 0...maxMargin)
            NumberSlider(title: "세로 여백", value: $marginY, range: 0...maxMargin)
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

struct LanguageRow: View {
    let lang: String
    let style: BadgeView
    @AppStorage private var label: String
    @AppStorage private var bg: String
    @AppStorage private var fg: String
    @AppStorage private var hidden: Bool

    init(lang: String, style: BadgeView) {
        self.lang = lang
        self.style = style
        let d = langDefaults(lang)
        _label = AppStorage(wrappedValue: d.label, K.label(lang))
        _bg = AppStorage(wrappedValue: d.bg, K.bg(lang))
        _fg = AppStorage(wrappedValue: d.fg, K.fg(lang))
        _hidden = AppStorage(wrappedValue: false, K.hidden(lang))
    }

    var body: some View {
        GridRow {
            Text(Locale.current.localizedString(forLanguageCode: lang) ?? lang)
            TextField("표시 글자", text: $label)
                .labelsHidden()
                .roundedInputBorder()
                .frame(width: 56)
            ColorPicker("배경", selection: color($bg), supportsOpacity: false).labelsHidden()
            ColorPicker("글자", selection: color($fg), supportsOpacity: false).labelsHidden()
            Toggle("숨기기", isOn: $hidden).labelsHidden()
            preview
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
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
