import AppKit

enum HogIcon {
    static let connected = make(alpha: 1.0)
    static let idle = make(alpha: 0.45)

    private static func make(alpha: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: 22, height: 16), flipped: false) { _ in
            NSColor.black.withAlphaComponent(alpha).setFill()
            NSColor.black.withAlphaComponent(alpha).setStroke()

            NSBezierPath(ovalIn: NSRect(x: 3, y: 4, width: 13, height: 9)).fill()
            NSBezierPath(ovalIn: NSRect(x: 13, y: 5, width: 7, height: 7)).fill()
            NSBezierPath(roundedRect: NSRect(x: 18.5, y: 4.5, width: 3, height: 3.5), xRadius: 1, yRadius: 1).fill()

            let ear = NSBezierPath()
            ear.move(to: NSPoint(x: 14.5, y: 11))
            ear.line(to: NSPoint(x: 15.5, y: 14.5))
            ear.line(to: NSPoint(x: 17.5, y: 11.5))
            ear.close()
            ear.fill()

            NSBezierPath(roundedRect: NSRect(x: 5, y: 1, width: 2.2, height: 4.5), xRadius: 0.8, yRadius: 0.8).fill()
            NSBezierPath(roundedRect: NSRect(x: 12, y: 1, width: 2.2, height: 4.5), xRadius: 0.8, yRadius: 0.8).fill()

            let tail = NSBezierPath()
            tail.lineWidth = 1.2
            tail.lineCapStyle = .round
            tail.move(to: NSPoint(x: 3.5, y: 9.5))
            tail.curve(to: NSPoint(x: 1.2, y: 11.5), controlPoint1: NSPoint(x: 2, y: 9), controlPoint2: NSPoint(x: 0.8, y: 10.2))
            tail.curve(to: NSPoint(x: 2.6, y: 12.6), controlPoint1: NSPoint(x: 1.5, y: 12.6), controlPoint2: NSPoint(x: 2.4, y: 13))
            tail.stroke()

            NSGraphicsContext.current?.compositingOperation = .clear
            NSBezierPath(ovalIn: NSRect(x: 16.6, y: 9, width: 1.4, height: 1.4)).fill()
            NSBezierPath(ovalIn: NSRect(x: 19.6, y: 5.5, width: 0.8, height: 1.4)).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
