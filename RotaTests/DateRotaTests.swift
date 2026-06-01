import XCTest
@testable import Rota

final class DateRotaTests: XCTestCase {
    func testStartOfWeekIsMonday() {
        // 2024-06-05 is a Wednesday.
        var comps = DateComponents()
        comps.year = 2024; comps.month = 6; comps.day = 5
        let wednesday = Calendar(identifier: .gregorian).date(from: comps)!
        let monday = wednesday.startOfWeek
        let weekday = Calendar(identifier: .gregorian).component(.weekday, from: monday)
        XCTAssertEqual(weekday, 2, "startOfWeek should be Monday (weekday == 2)")
    }

    func testWeekDaysReturnsSevenDays() {
        XCTAssertEqual(Date().weekDays.count, 7)
    }

    func testClockStringFormatsDuration() {
        let interval: TimeInterval = 3661 // 1h 1m 1s
        XCTAssertEqual(interval.clockString, "01:01:01")
    }

    func testHoursMinutesFormatting() {
        XCTAssertEqual(TimeInterval(8 * 3600 + 30 * 60).hoursMinutes, "8h 30m")
        XCTAssertEqual(TimeInterval(3600).hoursMinutes, "1h")
        XCTAssertEqual(TimeInterval(45 * 60).hoursMinutes, "45m")
    }

    func testRoundToPlaces() {
        XCTAssertEqual(7.456.rounded(toPlaces: 1), 7.5, accuracy: 0.0001)
    }
}
