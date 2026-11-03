import SwiftUI

struct SettingsView: View {
    @AppStorage(K.displayMode) private var displayMode = "all"
    @AppStorage(K.displays) private var displays = ""
    @AppStorage(K.shape) private var shape = "rounded"
    @AppStorage(K.fontSize) private var fontSize = 15.0
    @AppStorage(K.opacity) private var opacity = 0.9
    @AppStorage(K.glass) private var glass = false
    @AppStorage(K.hAlign) private var hAlign = "right"
    @AppStorage(K.vAlign) private var vAlign = "bottom"
    @AppStorage(K.marginX) private var marginX = 12.0
    @AppStorage(K.marginY) private var marginY = 12.0

    private let languages = enabledLanguages()
    private let screens = NSScreen.screens
    private let maxMargin = (NSScreen.screens.map { max($0.visibleFrame.width, $0.visibleFrame.height) }.max() ?? 800) / 2

    var body: some View {
        Form {
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
                    ForEach(languages, id: \.self) { lang in
                        LanguageRow(lang: lang, shape: shape, fontSize: fontSize, opacity: opacity, glass: glass)
                    }
                }
            }
            Section("뱃지 스타일") {
                Picker("모양", selection: $shape) {
                    Text("둥근 사각형").tag("rounded")
                    Text("캡슐").tag("capsule")
                    Text("원").tag("circle")
                }
                .pickerStyle(.segmented)
                if #available(macOS 26, *) {
                    Toggle("유리 효과 (Liquid Glass)", isOn: $glass)
                }
                NumberSlider(title: "글자 크기", value: $fontSize, range: 10...48)
                NumberSlider(title: "불투명도 (%)", value: Binding(get: { opacity * 100 }, set: { opacity = $0 / 100 }),
                             range: 20...100)
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
        .formStyle(.grouped)
        .frame(width: 560)
        .frame(minHeight: 400, idealHeight: 720)
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
            Slider(value: $value, in: range, step: 1) { Text(title) }
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
    let shape: String
    let fontSize: Double
    let opacity: Double
    let glass: Bool
    @AppStorage private var label: String
    @AppStorage private var bg: String
    @AppStorage private var fg: String
    @AppStorage private var hidden: Bool

    init(lang: String, shape: String, fontSize: Double, opacity: Double, glass: Bool) {
        self.lang = lang
        self.glass = glass
        self.shape = shape
        self.fontSize = fontSize
        self.opacity = opacity
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
            BadgeView(label: label, bg: Color(hex: bg), fg: Color(hex: fg), shape: shape,
                      fontSize: min(fontSize, 20), opacity: hidden ? 0.2 : opacity, glass: glass)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
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
