import AppKit
import SwiftUI
import VistaCore

@main
struct RenderPreviews {
    @MainActor static func main() {
        let output = CommandLine.arguments[1]
        try! FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
        let model = AppModel()
        model.expanded = true
        for (name, scheme) in [("light", ColorScheme.light), ("dark", ColorScheme.dark)] {
            for state in ["focus", "break", "idle"] {
                model.settings = state == "settings"
                model.expanded = state != "idle"
                model.clock.reset(now: Date())
                if state == "break" { model.clock.markDue(now: Date()) }
                let view = VistaView(model: model)
                    .environment(\.colorScheme, scheme)
                    .frame(width: model.expanded ? 332 : 48, height: model.expanded ? (model.settings ? 250 : 338) : 48)
                let renderer = ImageRenderer(content: view)
                renderer.scale = 2
                if let image = renderer.nsImage, let tiff = image.tiffRepresentation,
                   let data = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                    try! data.write(to: URL(fileURLWithPath: "\(output)/\(name)-\(state).png"))
                }
            }
        }
    }
}
