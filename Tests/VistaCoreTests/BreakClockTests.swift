import XCTest
@testable import VistaCore

final class BreakClockTests: XCTestCase {
    let epoch = Date(timeIntervalSince1970: 1000)
    func testReminderWaitsForAcknowledgement() {
        var clock = BreakClock(now: epoch)
        clock.tick(now: epoch.addingTimeInterval(1200))
        XCTAssertEqual(clock.phase, .due)
        clock.tick(now: epoch.addingTimeInterval(1800))
        XCTAssertEqual(clock.phase, .due)
        XCTAssertEqual(clock.completions, 0)
    }
    func testFullBreakAndAutomaticReturn() {
        var clock = BreakClock(now: epoch)
        clock.start(now: epoch)
        clock.tick(now: epoch.addingTimeInterval(19))
        XCTAssertEqual(clock.phase, .resting)
        clock.tick(now: epoch.addingTimeInterval(20))
        XCTAssertEqual(clock.phase, .completed)
        XCTAssertEqual(clock.completions, 1)
        clock.tick(now: epoch.addingTimeInterval(24))
        XCTAssertEqual(clock.phase, .focus)
        XCTAssertEqual(clock.remaining(at: epoch.addingTimeInterval(24)), 1200)
    }
    func testSnoozeAndPauseDeadlines() {
        var clock = BreakClock(now: epoch)
        clock.snooze(now: epoch)
        XCTAssertEqual(clock.remaining(at: epoch), 300)
        clock.pause(now: epoch)
        clock.tick(now: epoch.addingTimeInterval(3599))
        XCTAssertEqual(clock.phase, .paused)
        clock.tick(now: epoch.addingTimeInterval(3600))
        XCTAssertEqual(clock.phase, .focus)
    }
    func testInterruptedBreakDoesNotCount() {
        var clock = BreakClock(now: epoch)
        clock.start(now: epoch)
        clock.reset(now: epoch.addingTimeInterval(10))
        XCTAssertEqual(clock.completions, 0)
        XCTAssertEqual(clock.phase, .focus)
    }
    func testLateTickAndFractionalSeconds() {
        var clock = BreakClock(now: epoch)
        XCTAssertEqual(clock.remaining(at: epoch.addingTimeInterval(0.2)), 1200)
        clock.tick(now: epoch.addingTimeInterval(5000))
        XCTAssertEqual(clock.remaining(at: epoch.addingTimeInterval(5000)), 0)
        XCTAssertEqual(clock.phase, .due)
    }
}
