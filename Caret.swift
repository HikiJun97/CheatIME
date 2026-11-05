import AppKit
import ApplicationServices

func accessibilityTrusted(prompt: Bool) -> Bool {
    AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": prompt] as CFDictionary)
}

func openAccessibilitySettings() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
        NSWorkspace.shared.open(url)
    }
}

nonisolated func focusedCaretBounds() -> CGRect? {
    guard AXIsProcessTrusted() else { return nil }
    let system = AXUIElementCreateSystemWide()
    AXUIElementSetMessagingTimeout(system, 0.25)
    var focused: CFTypeRef?
    guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
          let focused, CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }
    let element = focused as! AXUIElement
    var range: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &range) == .success,
          let range else { return nil }
    var bounds: CFTypeRef?
    guard AXUIElementCopyParameterizedAttributeValue(
        element, kAXBoundsForRangeParameterizedAttribute as CFString, range, &bounds) == .success,
          let bounds, CFGetTypeID(bounds) == AXValueGetTypeID() else { return nil }
    var rect = CGRect.zero
    guard AXValueGetValue(bounds as! AXValue, .cgRect, &rect), rect.height > 0 else { return nil }
    return rect
}

func caretRect(from bounds: CGRect) -> NSRect? {
    guard let top = NSScreen.screens.first?.frame.maxY else { return nil }
    return NSRect(x: bounds.minX, y: top - bounds.maxY, width: bounds.width, height: bounds.height)
}
