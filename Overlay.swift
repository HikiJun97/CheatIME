import SwiftUI

struct BadgeView: View {
    var label: String
    var bg: Color
    var fg: Color
    var shape: String
    var fontSize: Double
    var dotSize: Double
    var opacity: Double
    var glass: Bool
    var border = "none"
    var borderWidth = 0.0
    var borderColor = Color.clear
    var inset: Double = 0

    var body: some View {
        let isDot = shape == "dot"
        let h = isDot ? dotSize : fontSize * 1.8
        let padding = switch shape {
        case "circle", "dot": 0.0
        case "capsule": fontSize * 0.7
        default: fontSize * 0.5
        }
        let dash: [CGFloat] = switch border {
        case "dashed": [borderWidth * 3, borderWidth * 2]
        case "dotted": [0, borderWidth * 2]
        default: []
        }
        let text = Text(isDot ? "" : label)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(fg)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, padding)
            .frame(width: shape == "circle" || isDot ? h : nil)
            .frame(minWidth: h)
            .frame(height: h)
        Group {
            if glass, #available(macOS 26, *) {
                text.glassEffect(.regular.tint(bg), in: outline())
            } else {
                text.background(bg, in: outline())
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

    private func outline(inset: Double = 0) -> AnyShape {
        switch shape {
        case "circle", "dot": AnyShape(Circle())
        case "capsule": AnyShape(Capsule(style: .circular))
        default: AnyShape(RoundedRectangle(cornerRadius: max(0, fontSize * 0.4 - inset)))
        }
    }
}

extension BadgeView {
    init(lang: String, mode: String) {
        let d = UserDefaults.standard
        let l = langDefaults(lang)
        func key(_ name: String) -> String { K.style(mode, name) }
        let fontSize = d.double(forKey: key(K.fontSize))
        let glass = d.bool(forKey: key(K.glass))
        self.init(label: d.string(forKey: K.label(lang)) ?? l.label,
                  bg: Color(hex: d.string(forKey: K.bg(lang)) ?? l.bg),
                  fg: Color(hex: d.string(forKey: K.fg(lang)) ?? l.fg),
                  shape: d.string(forKey: key(K.shape)) ?? "",
                  fontSize: fontSize,
                  dotSize: d.double(forKey: key(K.dotSize)),
                  opacity: d.double(forKey: key(K.opacity)),
                  glass: glass,
                  border: d.string(forKey: key(K.border)) ?? "none",
                  borderWidth: d.double(forKey: key(K.borderWidth)),
                  borderColor: Color(hex: d.string(forKey: key(K.borderColor)) ?? "#FFFFFF"),
                  inset: glass ? max(8, fontSize * 0.5) : 0)
    }
}

final class BadgeHost: NSHostingView<BadgeView> {
    var onClick: () -> Void = {}
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
        dragging ? onDrop() : onClick()
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
    private var flashing = false
    private var flashID = 0

    func update() {
        let d = UserDefaults.standard
        let lang = currentLanguage()
        let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        let appAllowed = !d.bool(forKey: K.appFilter) || front == Bundle.main.bundleIdentifier
            || (d.string(forKey: K.filterApps) ?? "").split(separator: ",").contains(Substring(front))
        let visible = d.bool(forKey: K.visible) && !d.bool(forKey: K.hidden(lang)) && appAllowed
            && (flashing || !d.bool(forKey: K.flashOnly))

        let showFixed = visible && d.bool(forKey: K.showFixed)
        fixedFollowsMouse = showFixed && d.string(forKey: K.displayMode) == "mouse"
        let screens = showFixed ? targetScreens() : []
        let fixed = BadgeView(lang: lang, mode: "fixed")
        while fixedPanels.count < screens.count { fixedPanels.append(makePanel(follow: false)) }
        for (i, panel) in fixedPanels.enumerated() {
            guard i < screens.count else { panel.orderOut(nil); continue }
            let size = place(fixed, in: panel)
            put(panel, at: frame(for: size, on: screens[i]).origin, size: size)
            panel.orderFrontRegardless()
        }

        pointerSize = visible && d.bool(forKey: K.showPointer) ? place(BadgeView(lang: lang, mode: "pointer"), in: pointerPanel) : nil
        if let size = pointerSize {
            put(pointerPanel, at: pointerOrigin(for: size), size: size)
            pointerPanel.orderFrontRegardless()
        } else {
            pointerPanel.orderOut(nil)
        }

        caretFallback = d.bool(forKey: K.caretFallback)
        caretSize = visible && d.bool(forKey: K.showCaret) ? place(BadgeView(lang: lang, mode: "caret"), in: caretPanel) : nil
        if caretSize == nil { caretPanel.orderOut(nil) } else { caretTick() }
    }

    func flash() {
        let d = UserDefaults.standard
        guard d.bool(forKey: K.flashOnly) else { return update() }
        flashID += 1
        let id = flashID
        flashing = true
        update()
        allPanels.forEach { $0.alphaValue = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + d.double(forKey: K.flashDuration) / 1000) { [weak self] in
            self?.fadeOut(id)
        }
    }

    private func fadeOut(_ id: Int) {
        guard id == flashID else { return }
        let shown = allPanels.filter(\.isVisible)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            shown.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, id == self.flashID else { return }
                self.flashing = false
                self.update()
                shown.forEach { $0.alphaValue = 1 }
            }
        }
    }

    private var allPanels: [NSPanel] { fixedPanels + [pointerPanel, caretPanel] }

    func mouseMoved() {
        if let size = pointerSize { put(pointerPanel, at: pointerOrigin(for: size), size: size) }
        if fixedFollowsMouse { followMouse() }
    }

    func caretTick() {
        guard let size = caretSize else { return }
        if let caret = caretRect() {
            let p = NSPoint(x: caret.maxX + 6, y: caret.midY - size.height / 2)
            put(caretPanel, at: clamped(p, size: size, near: caret.origin), size: size)
        } else if pointerSize != nil || !caretFallback {
            caretPanel.orderOut(nil)
            return
        } else {
            put(caretPanel, at: pointerOrigin(for: size), size: size)
        }
        if !caretPanel.isVisible { caretPanel.orderFrontRegardless() }
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
        let mouse = NSEvent.mouseLocation
        return clamped(NSPoint(x: mouse.x + 16, y: mouse.y - 16 - size.height), size: size, near: mouse)
    }

    private func clamped(_ p: NSPoint, size: NSSize, near anchor: NSPoint) -> NSPoint {
        let screen = NSScreen.screens.first { NSMouseInRect(anchor, $0.frame, false) } ?? NSScreen.screens[0]
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

    private func screenUnderMouse() -> NSScreen {
        let p = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(p, $0.frame, false) } ?? NSScreen.screens[0]
    }

    private func targetScreens() -> [NSScreen] {
        let d = UserDefaults.standard
        switch d.string(forKey: K.displayMode) {
        case "mouse":
            return [screenUnderMouse()]
        case "selected":
            let ids = (d.string(forKey: K.displays) ?? "").split(separator: ",").map(String.init)
            let chosen = NSScreen.screens.filter { ids.contains($0.uuid) }
            return chosen.isEmpty ? [NSScreen.screens[0]] : chosen
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
        return NSRect(origin: NSPoint(x: x, y: y), size: size)
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
        let host = BadgeHost(rootView: BadgeView(lang: "", mode: "fixed"))
        host.menu = contextMenu
        host.onClick = { UserDefaults.standard.set(false, forKey: K.visible) }
        host.onDrop = { [weak self, weak panel] in
            if let self, let panel { self.savePosition(of: panel) }
        }
        panel.contentView = host
        return panel
    }
}
