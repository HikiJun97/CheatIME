import SwiftUI

struct BadgeView: View {
    var label: String
    var bg: Color
    var fg: Color
    var shape: String
    var fontSize: Double
    var badgeSize: Double
    var dotSize: Double
    var badgeWidth = 0.0
    var cornerRadius = 22.0
    var opacity: Double
    var glass: Bool
    var border = "none"
    var borderWidth = 0.0
    var borderColor = Color.clear
    var inset: Double = 0

    var body: some View {
        let isDot = shape == "dot"
        let h = isDot ? dotSize : badgeSize
        let fixedWidth: CGFloat? = shape == "circle" || isDot ? h : shape == "custom" && badgeWidth > 0 ? badgeWidth : nil
        let padding = switch shape {
        case "circle", "dot": 0.0
        case "capsule": (h * 0.39).rounded()
        case "custom": min((h * (0.2 + 0.38 * radius)).rounded(), max(0, (((fixedWidth ?? .infinity) - h) / 2).rounded(.down)))
        default: (h * 0.28).rounded()
        }
        let dash: [CGFloat] = switch border {
        case "dashed": [borderWidth * 3, borderWidth * 2]
        case "dotted": [0, borderWidth * 2]
        default: []
        }
        let ink = inkBounds()
        let text = Text(isDot ? "" : label)
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
            if glass, #available(macOS 26, *) {
                text.glassEffect(.regular.tint(bg), in: outline())
            } else {
                text.background {
                        if border == "none" {
                            outline().fill(bg)
                        } else {
                            outline(inset: borderWidth / 2).fill(bg).padding(borderWidth / 2)
                        }
                    }
                    .overlay {
                        if border != "none" {
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

    private var radius: Double { min(max(cornerRadius, 0), 50) / 100 }

    private func inkBounds() -> (midX: CGFloat, midY: CGFloat, width: CGFloat) {
        guard !label.isEmpty, shape != "dot" else { return (0.5, 0, 1) }
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: label, attributes: [.font: font]))
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        return (bounds.midX, bounds.midY, max(width, 1))
    }

    private func outline(inset: Double = 0) -> AnyShape {
        switch shape {
        case "circle", "dot": AnyShape(Circle())
        case "capsule": AnyShape(Capsule(style: .circular))
        case "custom":
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
        func key(_ name: String) -> String { K.style(scope, name) }
        let badgeSize = d.double(forKey: key(K.badgeSize))
        let glass = d.bool(forKey: key(K.glass))
        self.init(label: look.label,
                  bg: Color(hex: look.bg),
                  fg: Color(hex: look.fg),
                  shape: d.string(forKey: key(K.shape)) ?? "",
                  fontSize: d.double(forKey: key(K.fontSize)),
                  badgeSize: badgeSize,
                  dotSize: d.double(forKey: key(K.dotSize)),
                  badgeWidth: d.double(forKey: key(K.badgeWidth)),
                  cornerRadius: d.double(forKey: key(K.cornerRadius)),
                  opacity: d.double(forKey: key(K.opacity)),
                  glass: glass,
                  border: d.string(forKey: key(K.border)) ?? "none",
                  borderWidth: d.double(forKey: key(K.borderWidth)),
                  borderColor: Color(hex: d.string(forKey: key(K.borderColor)) ?? "#FFFFFF"),
                  inset: glass ? max(8, badgeSize * 0.28) : 0)
    }
}

final class BadgeHost: NSHostingView<BadgeView> {
    var onDrop: () -> Void = {}
    private var start = NSPoint.zero
    private var origin = NSPoint.zero
    private var dragging = false

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { return rightMouseDown(with: event) }
        start = NSEvent.mouseLocation
        origin = window?.frame.origin ?? .zero
        dragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        let p = NSEvent.mouseLocation
        let dx = p.x - start.x, dy = p.y - start.y
        if !dragging && hypot(dx, dy) < 3 { return }
        dragging = true
        window?.setFrameOrigin(NSPoint(x: origin.x + dx, y: origin.y + dy))
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
    private var flashing: Set<String> = []
    private var flashIDs: [String: Int] = [:]

    func update() {
        let d = UserDefaults.standard
        let source = currentInputSource()
        let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        let appAllowed = !d.bool(forKey: K.appFilter) || front == Bundle.main.bundleIdentifier
            || (d.string(forKey: K.filterApps) ?? "").split(separator: ",").contains(Substring(front))
        let visible = d.bool(forKey: K.visible) && !badgeLook(source).hidden && appAllowed
        func shows(_ mode: String) -> Bool {
            visible && d.bool(forKey: K.show(mode))
                && (flashing.contains(mode) || !d.bool(forKey: K.style(styleScope(mode), K.flashOnly)))
        }

        let showFixed = shows("fixed")
        fixedFollowsMouse = showFixed && d.string(forKey: K.displayMode) == "mouse"
        let screens = showFixed ? targetScreens() : []
        let fixed = BadgeView(source: source, scope: styleScope("fixed"))
        while fixedPanels.count < screens.count { fixedPanels.append(makePanel(follow: false)) }
        for (i, panel) in fixedPanels.enumerated() {
            guard i < screens.count else { panel.orderOut(nil); continue }
            let size = place(fixed, in: panel)
            put(panel, at: frame(for: size, on: screens[i]).origin, size: size)
            panel.orderFrontRegardless()
        }

        pointerSize = shows("pointer") ? place(BadgeView(source: source, scope: styleScope("pointer")), in: pointerPanel) : nil
        if let size = pointerSize {
            put(pointerPanel, at: pointerOrigin(for: size), size: size)
            pointerPanel.orderFrontRegardless()
        } else {
            pointerPanel.orderOut(nil)
        }

        caretFallback = d.bool(forKey: K.caretFallback)
        caretGeneration += 1
        caretSize = shows("caret") ? place(BadgeView(source: source, scope: styleScope("caret")), in: caretPanel) : nil
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
        let modes = K.modes.filter { d.bool(forKey: K.style(styleScope($0), K.flashOnly)) }
        for mode in modes {
            let id = flashIDs[mode, default: 0] + 1
            flashIDs[mode] = id
            flashing.insert(mode)
            let seconds = d.double(forKey: K.style(styleScope(mode), K.flashDuration)) / 1000
            if mode == "caret" && !caretPanel.isVisible {
                caretFlash = (id, seconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds + 1) { [weak self] in self?.fadeOut(mode, id) }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in self?.fadeOut(mode, id) }
            }
        }
        update()
        modes.flatMap(panels).forEach { $0.alphaValue = 1 }
    }

    private func fadeOut(_ mode: String, _ id: Int) {
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

    private func panels(_ mode: String) -> [NSPanel] {
        switch mode {
        case "fixed": fixedPanels
        case "pointer": [pointerPanel]
        default: [caretPanel]
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
            put(caretPanel, at: origin("caret", around: caret, size: size), size: size)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + flash.seconds) { [weak self] in self?.fadeOut("caret", flash.id) }
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
        origin("pointer", around: NSRect(origin: NSEvent.mouseLocation, size: .zero), size: size)
    }

    private func origin(_ mode: String, around anchor: NSRect, size: NSSize) -> NSPoint {
        var placement = Placement(mode: mode)
        var p = placement.origin(around: anchor, size: size)
        if placement.flip, let v = screen(containing: anchor.origin)?.visibleFrame {
            if p.x < v.minX || p.x + size.width > v.maxX { placement.h = -placement.h }
            if p.y < v.minY || p.y + size.height > v.maxY { placement.v = -placement.v }
            p = placement.origin(around: anchor, size: size)
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
        let p = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(p, $0.frame, false) } ?? NSScreen.screens.first
    }

    private func targetScreens() -> [NSScreen] {
        let d = UserDefaults.standard
        switch d.string(forKey: K.displayMode) {
        case "mouse":
            return screenUnderMouse().map { [$0] } ?? []
        case "selected":
            let ids = (d.string(forKey: K.displays) ?? "").split(separator: ",").map(String.init)
            let chosen = NSScreen.screens.filter { ids.contains($0.uuid) }
            return chosen.isEmpty ? Array(NSScreen.screens.prefix(1)) : chosen
        default:
            return NSScreen.screens
        }
    }

    private func frame(for size: NSSize, on screen: NSScreen) -> NSRect {
        let d = UserDefaults.standard
        let f = screen.visibleFrame
        let mx = d.double(forKey: K.marginX), my = d.double(forKey: K.marginY)
        let x: CGFloat = switch d.string(forKey: K.hAlign) {
        case "left": f.minX + mx
        case "center": f.midX - size.width / 2
        default: f.maxX - size.width - mx
        }
        let y: CGFloat = switch d.string(forKey: K.vAlign) {
        case "top": f.maxY - size.height - my
        case "middle": f.midY - size.height / 2
        default: f.minY + my
        }
        let origin = NSPoint(x: min(max(x, f.minX), f.maxX - size.width), y: min(max(y, f.minY), f.maxY - size.height))
        return NSRect(origin: origin, size: size)
    }

    private func savePosition(of panel: NSPanel) {
        let inset = (panel.contentView as! BadgeHost).rootView.inset
        let f = panel.frame.insetBy(dx: inset, dy: inset)
        let center = NSPoint(x: f.midX, y: f.midY)
        guard let v = (NSScreen.screens.first { $0.frame.contains(center) } ?? panel.screen)?.visibleFrame
        else { return }
        let left = f.midX < v.midX, bottom = f.midY < v.midY
        let d = UserDefaults.standard
        d.set(left ? "left" : "right", forKey: K.hAlign)
        d.set(max(0, left ? f.minX - v.minX : v.maxX - f.maxX), forKey: K.marginX)
        d.set(bottom ? "bottom" : "top", forKey: K.vAlign)
        d.set(max(0, bottom ? f.minY - v.minY : v.maxY - f.maxY), forKey: K.marginY)
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
