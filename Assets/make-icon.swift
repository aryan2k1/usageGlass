import AppKit
let output = CommandLine.arguments[1]
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let bg = NSBezierPath(roundedRect: NSRect(x: 42, y: 42, width: 940, height: 940), xRadius: 210, yRadius: 210)
NSGradient(starting: NSColor(calibratedRed: 0.14, green: 0.23, blue: 0.27, alpha: 1), ending: NSColor(calibratedRed: 0.035, green: 0.07, blue: 0.12, alpha: 1))!.draw(in: bg, angle: -45)
let frame = NSBezierPath(roundedRect: NSRect(x: 150, y: 235, width: 724, height: 554), xRadius: 90, yRadius: 90)
NSColor.white.withAlphaComponent(0.08).setFill(); frame.fill()
NSColor.white.withAlphaComponent(0.22).setStroke(); frame.lineWidth = 3; frame.stroke()
for (y, width, color) in [(570.0, 450.0, NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.78, alpha: 1)), (380.0, 300.0, NSColor(calibratedRed: 1, green: 0.70, blue: 0.40, alpha: 1))] {
 let track = NSBezierPath(roundedRect: NSRect(x: 235, y: y, width: 554, height: 72), xRadius: 36, yRadius: 36)
 NSColor.white.withAlphaComponent(0.1).setFill(); track.fill()
 let fill = NSBezierPath(roundedRect: NSRect(x: 235, y: y, width: width, height: 72), xRadius: 36, yRadius: 36)
 color.setFill(); fill.fill()
}
image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
