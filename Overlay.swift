import SwiftUI

struct BadgeView: View {
    var label: String
    var bg: Color
    var fg: Color
    var shape: String
    var fontSize: Double
    var opacity: Double
    var glass: Bool
    var inset: Double = 0

    var body: some View {
        let h = fontSize * 1.8
        let outline = switch shape {
        case "circle": AnyShape(Circle())
        case "capsule": AnyShape(Capsule())
        default: AnyShape(RoundedRectangle(cornerRadius: fontSize * 0.4))
        }
        let padding = switch shape {
        case "circle": 0.0
        case "capsule": fontSize * 0.7
        default: fontSize * 0.5
        }
        let text = Text(label)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(fg)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, padding)
            .frame(width: shape == "circle" ? h : nil)
            .frame(minWidth: h)
            .frame(height: h)
        Group {
            if glass, #available(macOS 26, *) {
                text.glassEffect(.regular.tint(bg), in: outline)
            } else {
                text.background(bg, in: outline)
            }
        }
        .opacity(opacity)
        .padding(inset)
        .fixedSize()
    }
}

extension BadgeView {
    init(lang: String) {
        let d = UserDefaults.standard
        let l = langDefaults(lang)
        let fontSize = d.double(forKey: K.fontSize)
        let glass = d.bool(forKey: K.glass)
        self.init(label: d.string(forKey: K.label(lang)) ?? l.label,
                  bg: Color(hex: d.string(forKey: K.bg(lang)) ?? l.bg),
                  fg: Color(hex: d.string(forKey: K.fg(lang)) ?? l.fg),
                  shape: d.string(forKey: K.shape) ?? "",
                  fontSize: fontSize,
                  opacity: d.double(forKey: K.opacity),
                  glass: glass,
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
    private var panels: [NSPanel] = []
    private var lastMouseScreen: NSScreen?
    private var inset = 0.0

    func update() {
        let d = UserDefaults.standard
        let lang = currentLanguage()
        let visible = d.bool(forKey: K.visible) && !d.bool(forKey: K.hidden(lang))
        let screens = visible ? targetScreens() : []
        let badge = BadgeView(lang: lang)
        inset = badge.inset

        while panels.count < screens.count { panels.append(makePanel()) }
        for (i, panel) in panels.enumerated() {
            guard i < screens.count else { panel.orderOut(nil); continue }
            let host = panel.contentView as! BadgeHost
            host.rootView = badge
            let size = NSSize(width: host.fittingSize.width - 2 * inset, height: host.fittingSize.height - 2 * inset)
            panel.setFrame(frame(for: size, on: screens[i]).insetBy(dx: -inset, dy: -inset), display: true)
            panel.orderFrontRegardless()
        }
    }

    func followMouse() {
        guard UserDefaults.standard.string(forKey: K.displayMode) == "mouse",
              NSEvent.pressedMouseButtons == 0 else { return }
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

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        let host = BadgeHost(rootView: BadgeView(lang: ""))
        host.menu = contextMenu
        host.onClick = { UserDefaults.standard.set(false, forKey: K.visible) }
        host.onDrop = { [weak self, weak panel] in
            if let self, let panel { self.savePosition(of: panel) }
        }
        panel.contentView = host
        return panel
    }
}
