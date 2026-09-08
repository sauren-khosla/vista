import AppKit
import SwiftUI
import VistaCore

final class CornerPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    var panel: CornerPanel!
    var statusItem: NSStatusItem!
    private var savedPosition: WidgetPosition? = UserDefaults.standard.data(forKey: "widgetPosition")
        .flatMap { try? JSONDecoder().decode(WidgetPosition.self, from: $0) }
    private func screenID(_ screen: NSScreen) -> UInt32 {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
    var screen: NSScreen? {
        NSScreen.screens.first(where: { screenID($0) == savedPosition?.screenID }) ?? NSScreen.screens.first
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        // A single agent instance prevents overlapping widgets and duplicate reminders.
        if NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "local.vista.app").count > 1 {
            NSApp.terminate(nil); return
        }
        NSApp.setActivationPolicy(.regular)
        panel = CornerPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        let hosting = NSHostingView(rootView: VistaView(model: model))
        hosting.sizingOptions = []
        panel.contentView = hosting
        model.onResize = { [weak self] in self?.position(animated: true) }
        model.onMove = { [weak self] in self?.rememberPosition() }
        position(animated: false)
        panel.orderFrontRegardless()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "circle.dotted.circle", accessibilityDescription: "Vista eye breaks")
        let menu = NSMenu()
        addItem(menu, "Show Vista", #selector(show), "")
        addItem(menu, "Take a break now", #selector(start), "")
        addItem(menu, "Pause for one hour", #selector(pause), "")
        addItem(menu, "Resume reminders", #selector(resume), "")
        menu.addItem(.separator())
        addItem(menu, "Settings…", #selector(settings), ",")
        addItem(menu, "Quit Vista", #selector(quit), "q")
        statusItem.menu = menu
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = menu.copy() as? NSMenu
        appMenu.addItem(appMenuItem)
        NSApp.mainMenu = appMenu
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(wake), name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(wake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(wake), name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(suspend), name: name, object: nil)
        }
        if CommandLine.arguments.contains("--preview") { model.setExpanded(true) }
        if CommandLine.arguments.contains("--due") { model.clock.markDue(now: Date()); model.setExpanded(true) }
    }
    func addItem(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self; menu.addItem(item)
    }
    func position(animated: Bool) {
        guard let screen else { return }
        let size = model.expanded ? NSSize(width: 332, height: model.settings ? 250 : 338) : NSSize(width: 48, height: 48)
        let visible = screen.visibleFrame
        let placement = savedPosition ?? WidgetPosition(
            screenID: screenID(screen),
            center: CGPoint(x: visible.maxX - 42, y: visible.maxY - 36),
            visibleFrame: visible)
        let frame = placement.frame(size: size, visibleFrame: visible)
        if animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.38
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else { panel.setFrame(frame, display: true) }
    }
    func rememberPosition() {
        let center = CGPoint(x: panel.frame.midX, y: panel.frame.midY)
        guard let target = NSScreen.screens.first(where: { $0.frame.contains(center) }) ?? panel.screen ?? screen else { return }
        savedPosition = WidgetPosition(screenID: screenID(target), center: center, visibleFrame: target.visibleFrame)
        if let data = try? JSONEncoder().encode(savedPosition) {
            UserDefaults.standard.set(data, forKey: "widgetPosition")
        }
        position(animated: false)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        show()
        return true
    }
    @objc func show() { model.setExpanded(true); panel.orderFrontRegardless() }
    @objc func start() { model.start() }
    @objc func pause() { model.pause() }
    @objc func resume() { model.resume() }
    @objc func settings() { model.settings = true; show() }
    @objc func quit() { NSApp.terminate(nil) }
    @objc func screenChanged() { position(animated: false) }
    @objc func suspend() { model.suspend() }
    @objc func wake() { model.wake(); position(animated: false) }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    withExtendedLifetime(delegate) { app.run() }
}
