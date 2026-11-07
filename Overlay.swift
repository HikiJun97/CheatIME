import SwiftUI

struct BadgeView: View {
    var label: String
    var region: String?
    var content = BadgeContent.text
    var bg: Color
    var fg: Color
    var shape: BadgeShape
    var fontSize: Double
    var badgeSize: Double
    var dotSize: Double
    var badgeWidth = 0.0
    var cornerRadius = 22.0
    var opacity: Double
    var glass: Bool
    var border = BorderStyle.none
    var borderWidth = 0.0
    var borderColor = Color.clear
    var inset: Double = 0

    var body: some View {
        let isDot = shape == .dot
        let h = isDot ? dotSize : badgeSize
        let shapeWidth: CGFloat? = shape == .circle || isDot ? h : shape == .custom && badgeWidth > 0 ? badgeWidth : nil
        let flag = content == .flag
            ? region.flatMap { flagImage($0, square: (shapeWidth ?? .infinity) < h * 1.17) } : nil
        let fixedWidth = flag == nil ? shapeWidth : shapeWidth ?? (h * 4 / 3).rounded()
        let padding = switch shape {
        case _ where flag != nil: 0.0
        case .circle, .dot: 0.0
        case .capsule: (h * 0.39).rounded()
        case .custom: min((h * (0.2 + 0.38 * radius)).rounded(), max(0, (((fixedWidth ?? .infinity) - h) / 2).rounded(.down)))
        default: (h * 0.28).rounded()
        }
        let dash: [CGFloat] = switch border {
        case .dashed: [borderWidth * 3, borderWidth * 2]
        case .dotted: [0, borderWidth * 2]
        default: []
        }
        let ink = inkBounds()
        let text = Text(isDot || flag != nil ? "" : label)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(fg)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .alignmentGuide(.inkCenter) { $0[.firstTextBaseline] - ink.midY * min(1, $0.width / ink.width) }
            .frame(height: h, alignment: Alignment(horizontal: .center, vertical: .inkCenter))
            .visualEffect { content, proxy in
                content.offset(x: proxy.size.width / 2 - ink.midX * min(1, proxy.size.width / ink.width))
            }
            .padding(.horizontal, padding)
            .frame(width: fixedWidth)
            .frame(minWidth: fixedWidth == nil ? h : nil)
        Group {
            if glass, flag == nil, #available(macOS 26, *) {
                text.glassEffect(.regular.tint(bg), in: outline())
            } else {
                text.background {
                        if border != .solid {
                            fill(flag)
                        } else {
                            fill(flag, inset: borderWidth / 2).padding(borderWidth / 2)
                        }
                    }
                    .overlay {
                        if border != BorderStyle.none {
                            outline(inset: borderWidth / 2)
                                .stroke(borderColor, style: StrokeStyle(lineWidth: borderWidth, lineCap: .round,
                                                                        lineJoin: .round, dash: dash))
                                .padding(borderWidth / 2)
                        }
                    }
            }
        }
        .opacity(opacity)
        .padding(inset)
        .fixedSize()
    }

    @ViewBuilder
    private func fill(_ flag: NSImage?, inset: Double = 0) -> some View {
        if let flag {
            Color.clear
                .overlay { Image(nsImage: flag).resizable().interpolation(.high).scaledToFill() }
                .clipShape(outline(inset: inset))
        } else {
            outline(inset: inset).fill(bg)
        }
    }

    private var radius: Double { min(max(cornerRadius, 0), 50) / 100 }

    private func inkBounds() -> (midX: CGFloat, midY: CGFloat, width: CGFloat) {
        guard !label.isEmpty, shape != .dot else { return (0.5, 0, 1) }
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: label, attributes: [.font: font]))
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        return (bounds.midX, bounds.midY, max(width, 1))
    }

    private func outline(inset: Double = 0) -> AnyShape {
        switch shape {
        case .circle, .dot: AnyShape(Circle())
        case .capsule: AnyShape(Capsule(style: .circular))
        case .custom:
            AnyShape(RoundedRectangle(cornerRadius: max(0, badgeSize * radius - inset),
                                      style: radius >= 0.5 ? .circular : .continuous))
        default: AnyShape(RoundedRectangle(cornerRadius: max(0, badgeSize * 0.22 - inset)))
        }
    }
}

private enum InkCenter: AlignmentID {
    static func defaultValue(in d: ViewDimensions) -> CGFloat { d[VerticalAlignment.center] }
}

extension VerticalAlignment {
    static let inkCenter = VerticalAlignment(InkCenter.self)
}

extension BadgeView {
    init(source: InputSourceInfo, scope: String) {
        let d = UserDefaults.standard
        let look = badgeLook(source)
        func value<V>(_ p: Pref<V>) -> V { d[K.style(scope, p)] }
        let badgeSize = value(K.badgeSize)
        let glass = value(K.glass)
        self.init(label: look.label,
                  region: modeRegion(source),
                  content: value(K.content),
                  bg: Color(hex: look.bg),
                  fg: Color(hex: look.fg),
                  shape: value(K.shape),
                  fontSize: value(K.fontSize),
                  badgeSize: badgeSize,
                  dotSize: value(K.dotSize),
                  badgeWidth: value(K.badgeWidth),
                  cornerRadius: value(K.cornerRadius),
                  opacity: value(K.opacity),
                  glass: glass,
                  border: value(K.border),
                  borderWidth: value(K.borderWidth),
                  borderColor: Color(hex: value(K.borderColor)),
                  inset: glass ? max(8, badgeSize * 0.28) : 0)
    }
}

final class BadgeHost: NSHostingView<BadgeView> {
    var onDrop: () -> Void = {}
    private var start = NSPoint.zero
    private var origin = NSPoint.zero
    private var dragging = false
    private var snaps = false

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { return rightMouseDown(with: event) }
        start = NSEvent.mouseLocation
        origin = window?.frame.origin ?? .zero
        dragging = false
        snaps = UserDefaults.standard[K.snapToEdges]
    }

    override func mouseDragged(with event: NSEvent) {
        let p = NSEvent.mouseLocation
        let dx = p.x - start.x, dy = p.y - start.y
        if !dragging && hypot(dx, dy) < 3 { return }
        dragging = true
        guard let window else { return }
        let o = NSPoint(x: origin.x + dx, y: origin.y + dy)
        window.setFrameOrigin(snaps ? snapped(o, size: window.frame.size) : o)
    }

    func badgeFrame(origin: NSPoint, size: NSSize) -> (frame: NSRect, screen: NSScreen?) {
        let f = NSRect(origin: origin, size: size).insetBy(dx: rootView.inset, dy: rootView.inset)
        let center = NSPoint(x: f.midX, y: f.midY)
        return (f, NSScreen.screens.first { $0.frame.contains(center) })
    }

    private func snapped(_ o: NSPoint, size: NSSize) -> NSPoint {
        let (f, screen) = badgeFrame(origin: o, size: size)
        guard let v = screen?.visibleFrame else { return o }
        return NSPoint(x: o.x + Self.pull(f.minX, f.maxX, toward: v.minX, v.maxX),
                       y: o.y + Self.pull(f.minY, f.maxY, toward: v.minY, v.maxY))
    }

    private static func pull(_ low: CGFloat, _ high: CGFloat, toward edgeLow: CGFloat, _ edgeHigh: CGFloat) -> CGFloat {
        let snapDistance: CGFloat = 12
        if abs(low - edgeLow) < snapDistance { return edgeLow - low }
        if abs(edgeHigh - high) < snapDistance { return edgeHigh - high }
        return 0
    }

    override func mouseUp(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { return }
        if dragging { onDrop() }
    }

    override func rightMouseDown(with event: NSEvent) {
        if let menu { NSMenu.popUpContextMenu(menu, with: event, for: self) }
    }
}

final class Overlay {
    var contextMenu: NSMenu?
    private var fixedPanels: [NSPanel] = []
    private lazy var pointerPanel = makePanel(follow: true)
    private lazy var caretPanel = makePanel(follow: true)
    private var pointerSize: NSSize?
    private var caretSize: NSSize?
    private var caretFallback = true
    private var fixedFollowsMouse = false
    private var lastMouseScreen: NSScreen?
    private var caretQueryRunning = false
    private var caretTimer: Timer?
    private var caretGeneration = 0
    private var caretFlash: (id: Int, seconds: Double)?
    private var flashing: Set<Mode> = []
    private var flashIDs: [Mode: Int] = [:]

    func update() {
        let d = UserDefaults.standard
        let source = currentInputSource()
        let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        let appAllowed = !d[K.appFilter] || front == Bundle.main.bundleIdentifier
            || d[K.filterApps].split(separator: ",").contains(Substring(front))
        let visible = d[K.visible] && !badgeLook(source).hidden && appAllowed
        func shows(_ mode: Mode) -> Bool {
            visible && d[K.show(mode)] && (flashing.contains(mode) || !d[K.style(styleScope(mode), K.flashOnly)])
        }

        let showFixed = shows(.fixed)
        fixedFollowsMouse = showFixed && d[K.displayMode] == .mouse
        let screens = showFixed ? targetScreens() : []
        let fixed = BadgeView(source: source, scope: styleScope(.fixed))
        while fixedPanels.count < screens.count { fixedPanels.append(makePanel(follow: false)) }
        for (i, panel) in fixedPanels.enumerated() {
            guard i < screens.count else { panel.orderOut(nil); continue }
            let size = place(fixed, in: panel)
            put(panel, at: frame(for: size, on: screens[i]).origin, size: size)
            panel.orderFrontRegardless()
        }

        pointerSize = shows(.pointer) ? place(BadgeView(source: source, scope: styleScope(.pointer)), in: pointerPanel) : nil
        if let size = pointerSize {
            put(pointerPanel, at: pointerOrigin(for: size), size: size)
            pointerPanel.orderFrontRegardless()
        } else {
            pointerPanel.orderOut(nil)
        }

        caretFallback = d[K.caretFallback]
        caretGeneration += 1
        caretSize = shows(.caret) ? place(BadgeView(source: source, scope: styleScope(.caret)), in: caretPanel) : nil
        if caretSize == nil {
            caretPanel.orderOut(nil)
            caretTimer?.invalidate()
            caretTimer = nil
        } else {
            if caretTimer == nil {
                caretTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
                    MainActor.assumeIsolated { self?.caretTick() }
                }
            }
            caretTick()
        }
    }

    func flash() {
        let d = UserDefaults.standard
        let modes = Mode.allCases.filter { d[K.style(styleScope($0), K.flashOnly)] }
        for mode in modes {
            let id = flashIDs[mode, default: 0] + 1
            flashIDs[mode] = id
            flashing.insert(mode)
            let seconds = d[K.style(styleScope(mode), K.flashDuration)] / 1000
            if mode == .caret && !caretPanel.isVisible {
                caretFlash = (id, seconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds + 1) { [weak self] in self?.fadeOut(mode, id) }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in self?.fadeOut(mode, id) }
            }
        }
        update()
        modes.flatMap(panels).forEach { $0.alphaValue = 1 }
    }

    private func fadeOut(_ mode: Mode, _ id: Int) {
        guard flashIDs[mode] == id else { return }
        let shown = panels(mode).filter(\.isVisible)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            shown.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.flashIDs[mode] == id else { return }
                self.flashing.remove(mode)
                self.update()
                shown.forEach { $0.alphaValue = 1 }
            }
        }
    }

    private func panels(_ mode: Mode) -> [NSPanel] {
        switch mode {
        case .fixed: fixedPanels
        case .pointer: [pointerPanel]
        case .caret: [caretPanel]
        }
    }

    func mouseMoved() {
        if let size = pointerSize { put(pointerPanel, at: pointerOrigin(for: size), size: size) }
        if fixedFollowsMouse { followMouse() }
    }

    func caretTick() {
        guard caretSize != nil, !caretQueryRunning else { return }
        caretQueryRunning = true
        let generation = caretGeneration
        DispatchQueue.global(qos: .userInteractive).async {
            let bounds = focusedCaretBounds()
            Task { @MainActor in self.showCaret(at: bounds, generation: generation) }
        }
    }

    private func showCaret(at bounds: CGRect?, generation: Int) {
        caretQueryRunning = false
        guard generation == caretGeneration else {
            caretTick()
            return
        }
        guard let size = caretSize else { return }
        if let bounds, let caret = caretRect(from: bounds) {
            put(caretPanel, at: origin(.caret, around: caret, size: size), size: size)
        } else if pointerSize != nil || !caretFallback {
            caretPanel.orderOut(nil)
            return
        } else {
            put(caretPanel, at: pointerOrigin(for: size), size: size)
        }
        if !caretPanel.isVisible {
            caretPanel.orderFrontRegardless()
            if let flash = caretFlash {
                caretFlash = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + flash.seconds) { [weak self] in self?.fadeOut(.caret, flash.id) }
            }
        }
    }

    private func place(_ badge: BadgeView, in panel: NSPanel) -> NSSize {
        let host = panel.contentView as! BadgeHost
        host.rootView = badge
        let fit = host.fittingSize
        return NSSize(width: fit.width - 2 * badge.inset, height: fit.height - 2 * badge.inset)
    }

    private func put(_ panel: NSPanel, at origin: NSPoint, size: NSSize) {
        let inset = (panel.contentView as! BadgeHost).rootView.inset
        let rect = NSRect(origin: origin, size: size).insetBy(dx: -inset, dy: -inset)
        if panel.frame != rect { panel.setFrame(rect, display: true) }
    }

    private func pointerOrigin(for size: NSSize) -> NSPoint {
        origin(.pointer, around: NSRect(origin: NSEvent.mouseLocation, size: .zero), size: size)
    }

    private func origin(_ mode: Mode, around anchor: NSRect, size: NSSize) -> NSPoint {
        let placement = Placement(mode: mode)
        var p = placement.origin(around: anchor, size: size)
        if placement.flip, let v = screen(containing: anchor.origin)?.visibleFrame {
            var opposite = placement
            opposite.h = -placement.h
            opposite.v = -placement.v
            let q = opposite.origin(around: anchor, size: size)
            let outX = { (x: CGFloat) in x < v.minX || x + size.width > v.maxX }
            let outY = { (y: CGFloat) in y < v.minY || y + size.height > v.maxY }
            if outX(p.x) && !outX(q.x) { p.x = q.x }
            if outY(p.y) && !outY(q.y) { p.y = q.y }
        }
        return clamped(p, size: size, near: anchor.origin)
    }

    private func screen(containing p: NSPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(p, $0.frame, false) } ?? NSScreen.screens.first
    }

    private func clamped(_ p: NSPoint, size: NSSize, near anchor: NSPoint) -> NSPoint {
        guard let screen = screen(containing: anchor) else { return p }
        let v = screen.visibleFrame
        return NSPoint(x: min(max(p.x, v.minX), v.maxX - size.width), y: min(max(p.y, v.minY), v.maxY - size.height))
    }

    private func followMouse() {
        guard NSEvent.pressedMouseButtons == 0 else { return }
        let screen = screenUnderMouse()
        if screen != lastMouseScreen {
            lastMouseScreen = screen
            update()
        }
    }

    private func screenUnderMouse() -> NSScreen? {
        screen(containing: NSEvent.mouseLocation)
    }

    private func targetScreens() -> [NSScreen] {
        let d = UserDefaults.standard
        switch d[K.displayMode] {
        case .mouse:
            return screenUnderMouse().map { [$0] } ?? []
        case .selected:
            let ids = d[K.displays].split(separator: ",").map(String.init)
            let chosen = NSScreen.screens.filter { ids.contains($0.uuid) }
            return chosen.isEmpty ? Array(NSScreen.screens.prefix(1)) : chosen
        case .all:
            return NSScreen.screens
        }
    }

    private func frame(for size: NSSize, on screen: NSScreen) -> NSRect {
        let d = UserDefaults.standard
        let f = screen.visibleFrame
        let mx = d[K.marginX], my = d[K.marginY]
        let x: CGFloat = switch d[K.hAlign] {
        case .left: f.minX + mx
        case .center: f.midX - size.width / 2
        case .right: f.maxX - size.width - mx
        }
        let y: CGFloat = switch d[K.vAlign] {
        case .top: f.maxY - size.height - my
        case .middle: f.midY - size.height / 2
        case .bottom: f.minY + my
        }
        let origin = NSPoint(x: min(max(x, f.minX), f.maxX - size.width), y: min(max(y, f.minY), f.maxY - size.height))
        return NSRect(origin: origin, size: size)
    }

    private func savePosition(of panel: NSPanel) {
        let (f, screen) = (panel.contentView as! BadgeHost).badgeFrame(origin: panel.frame.origin, size: panel.frame.size)
        guard let v = (screen ?? panel.screen)?.visibleFrame else { return }
        let left = f.midX < v.midX, bottom = f.midY < v.midY
        let d = UserDefaults.standard
        d[K.hAlign] = left ? .left : .right
        d[K.marginX] = max(0, left ? f.minX - v.minX : v.maxX - f.maxX)
        d[K.vAlign] = bottom ? .bottom : .top
        d[K.marginY] = max(0, bottom ? f.minY - v.minY : v.maxY - f.maxY)
    }

    private func makePanel(follow: Bool) -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = follow
        let host = BadgeHost(rootView: BadgeView(source: .none, scope: "default"))
        host.menu = contextMenu
        host.onDrop = { [weak self, weak panel] in
            if let self, let panel { self.savePosition(of: panel) }
        }
        panel.contentView = host
        return panel
    }
}
