import AppKit
import SwiftUI
import ServiceManagement
import VistaCore

@MainActor
final class AppModel: ObservableObject {
    @Published var clock: BreakClock
    @Published var now = Date()
    @Published var expanded = false
    @Published var settings = false
    @Published var todayCount: Int
    @Published var launchError: String?
    @Published var loginEnabled = SMAppService.mainApp.status == .enabled
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: "sound") }
    }
    var onResize: (() -> Void)?
    var onMove: (() -> Void)?
    private let defaults: UserDefaults
    private var timer: Timer?
    private var suspended = false
    private var day: String
    private static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }
    init(now: Date = Date(), defaults: UserDefaults = .standard, startTimer: Bool = true) {
        self.defaults = defaults
        self.now = now
        soundEnabled = defaults.object(forKey: "sound") as? Bool ?? true
        let minutes = defaults.integer(forKey: "interval")
        clock = BreakClock(now: now, interval: TimeInterval([20,30,45].contains(minutes) ? minutes * 60 : 1200))
        day = Self.dayKey(now)
        todayCount = defaults.string(forKey: "day") == day ? defaults.integer(forKey: "count") : 0
        guard startTimer else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    var remaining: Int { clock.remaining(at: now) }
    var timeLabel: String { String(format: "%02d:%02d", remaining / 60, remaining % 60) }
    var progress: Double {
        if clock.phase == .resting { return 1 - Double(remaining) / clock.duration }
        if clock.phase == .due || clock.phase == .completed { return 1 }
        if clock.phase == .paused { return 0 }
        return min(1, max(0, 1 - Double(remaining) / clock.interval))
    }
    func setExpanded(_ value: Bool) {
        if value { suspended = false }
        withAnimation(NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? nil : .spring(response: 0.44, dampingFraction: 0.86)) {
            expanded = value
            if !value { settings = false }
        }
        onResize?()
    }
    func tick(at date: Date = Date()) {
        let previous = now
        now = date
        guard !suspended else { return }
        if now.timeIntervalSince(previous) > 30, clock.phase != .paused {
            clock.reset(now: now); setExpanded(false)
        }
        if Self.dayKey(now) != day {
            day = Self.dayKey(now); todayCount = 0; saveCount()
        }
        // No keyboard/mouse idle heuristic: reading or watching the screen still
        // needs reminders. Only explicit macOS sleep/session events suspend us.
        let old = clock.phase
        clock.tick(now: now)
        if old != clock.phase {
            switch clock.phase {
            case .due: settings = false; setExpanded(true)
            case .completed:
                todayCount += 1; saveCount()
                if soundEnabled {
                    let sound = NSSound(named: "Glass")
                    sound?.volume = 0.22
                    sound?.play()
                }
            case .focus: setExpanded(false)
            default: break
            }
        }
    }
    func saveCount() {
        defaults.set(day, forKey: "day")
        defaults.set(todayCount, forKey: "count")
    }
    func start() { suspended = false; now = Date(); clock.start(now: now); settings = false; setExpanded(true) }
    func snooze() { now = Date(); clock.snooze(now: now); setExpanded(false) }
    func pause() { now = Date(); clock.pause(now: now); setExpanded(false) }
    func resume() { suspended = false; now = Date(); clock.reset(now: now); setExpanded(false) }
    func suspend() {
        suspended = true
        now = Date()
        if clock.phase != .paused { clock.reset(now: now) }
        setExpanded(false)
    }
    func wake() {
        suspended = false
        now = Date()
        if clock.phase != .paused { clock.reset(now: now); setExpanded(false) }
    }
    func setInterval(_ minutes: Int) {
        defaults.set(minutes, forKey: "interval")
        clock.interval = TimeInterval(minutes * 60)
        if clock.phase == .focus { clock.reset(now: Date()) }
    }
    func setLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            loginEnabled = SMAppService.mainApp.status == .enabled
            launchError = SMAppService.mainApp.status == .requiresApproval ? "Allow Vista in System Settings → General → Login Items." : nil
        } catch {
            loginEnabled = SMAppService.mainApp.status == .enabled
            launchError = "Move Vista to Applications, reopen it, then try again."
        }
    }
}
