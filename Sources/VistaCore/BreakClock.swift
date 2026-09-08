import Foundation

/// Wall-clock deadlines keep the timer accurate when UI updates are delayed.
public struct BreakClock {
    public enum Phase: Equatable { case focus, due, resting, completed, paused }
    public private(set) var phase: Phase = .focus
    public private(set) var deadline: Date
    public var interval: TimeInterval
    public let duration: TimeInterval = 20
    public private(set) var completions = 0
    public init(now: Date = Date(), interval: TimeInterval = 1200) {
        self.interval = interval
        deadline = now.addingTimeInterval(interval)
    }
    public func remaining(at now: Date) -> Int {
        max(0, Int(ceil(deadline.timeIntervalSince(now))))
    }
    public mutating func tick(now: Date) {
        guard now >= deadline else { return }
        switch phase {
        case .focus: phase = .due
        case .resting:
            phase = .completed
            completions += 1
            deadline = now.addingTimeInterval(4)
        case .completed, .paused: reset(now: now)
        case .due: break
        }
    }
    public mutating func start(now: Date) {
        phase = .resting
        deadline = now.addingTimeInterval(duration)
    }
    public mutating func snooze(now: Date) {
        phase = .focus
        deadline = now.addingTimeInterval(300)
    }
    public mutating func pause(now: Date) {
        phase = .paused
        deadline = now.addingTimeInterval(3600)
    }
    public mutating func reset(now: Date) {
        phase = .focus
        deadline = now.addingTimeInterval(interval)
    }
    public mutating func markDue(now: Date) {
        phase = .due
        deadline = now
    }
}
