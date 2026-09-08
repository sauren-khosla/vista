import XCTest
@testable import Vista

final class AppModelTests: XCTestCase {
    @MainActor
    func testFocusCountsDownWhileThereIsNoKeyboardOrMouseInput() {
        let suite = "VistaTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let start = Date(timeIntervalSince1970: 1000)
        let model = AppModel(now: start, defaults: defaults, startTimer: false)
        // Run the actual app coordinator beyond the old two-minute idle cutoff.
        for second in 1...180 { model.tick(at: start.addingTimeInterval(Double(second))) }
        XCTAssertEqual(model.remaining, 1020)
        XCTAssertEqual(model.clock.phase, .focus)
        for second in 181...1200 { model.tick(at: start.addingTimeInterval(Double(second))) }
        XCTAssertEqual(model.clock.phase, .due)
        XCTAssertTrue(model.expanded)
    }

    @MainActor
    func testCoordinatorCompletesBreakAndCollapses() {
        let suite = "VistaTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(false, forKey: "sound")
        let start = Date(timeIntervalSince1970: 1000)
        let model = AppModel(now: start, defaults: defaults, startTimer: false)
        model.clock.start(now: start)
        model.expanded = true
        model.tick(at: start.addingTimeInterval(20))
        XCTAssertEqual(model.clock.phase, .completed)
        XCTAssertEqual(model.todayCount, 1)
        model.tick(at: start.addingTimeInterval(24))
        XCTAssertEqual(model.clock.phase, .focus)
        XCTAssertEqual(model.remaining, 1200)
        XCTAssertFalse(model.expanded)
    }

    @MainActor
    func testSleepStopsRemindersAndWakeRestartsCountdown() {
        let suite = "VistaTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = AppModel(defaults: defaults, startTimer: false)
        model.suspend()
        model.tick(at: Date().addingTimeInterval(1500))
        XCTAssertEqual(model.clock.phase, .focus)
        XCTAssertFalse(model.expanded)
        model.wake()
        let resumed = model.now
        model.tick(at: resumed.addingTimeInterval(10))
        XCTAssertEqual(model.remaining, 1190)
    }
}
