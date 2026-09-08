import AppKit
let root = CommandLine.arguments[1]
let folder = root + "/Vista.iconset"
try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
for size in [16,32,128,256,512] {
    for scale in [1,2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let context = NSGraphicsContext.current!.cgContext
        context.scaleBy(x: CGFloat(pixels)/1024, y: CGFloat(pixels)/1024)
        let inset = NSRect(x: 44, y: 44, width: 936, height: 936)
        let shape = NSBezierPath(roundedRect: inset, xRadius: 220, yRadius: 220)
        NSGradient(starting: NSColor(white: 0.23, alpha: 1), ending: NSColor(white: 0.06, alpha: 1))!.draw(in: shape, angle: -70)
        let ink = NSColor(white: 0.94, alpha: 1)
        ink.withAlphaComponent(0.25).setStroke()
        let ring = NSBezierPath(ovalIn: NSRect(x: 188, y: 188, width: 648, height: 648)); ring.lineWidth = 3; ring.stroke()
        ink.withAlphaComponent(0.08).setFill()
        NSBezierPath(ovalIn: NSRect(x: 336, y: 336, width: 352, height: 352)).fill()
        ink.setFill()
        NSBezierPath(ovalIn: NSRect(x: 449, y: 449, width: 126, height: 126)).fill()
        NSGraphicsContext.restoreGraphicsState()
        let data = bitmap.representation(using: .png, properties: [:])!
        let name = "icon_\(size)x\(size)" + (scale == 2 ? "@2x" : "") + ".png"
        try data.write(to: URL(fileURLWithPath: folder + "/" + name))
    }
}
