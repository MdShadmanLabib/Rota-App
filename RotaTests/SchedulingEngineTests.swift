import XCTest
@testable import Rota

final class SchedulingEngineTests: XCTestCase {
    private let org = UUID()

    private func shift(start: Date, hours: Double, user: UUID?, breakMinutes: Int = 0) -> Shift {
        Shift(
            id: UUID(), organizationId: org, title: "Shift", role: "Floor", location: nil,
            startAt: start, endAt: start.addingTimeInterval(hours * 3600), breakMinutes: breakMinutes,
            assignedUserId: user, status: .published, notes: nil, colorHex: nil,
            createdBy: nil, createdAt: .now
        )
    }

    func testClashDetectionFindsOverlapForSameUser() {
        let user = UUID()
        let base = Date()
        let a = shift(start: base, hours: 4, user: user)
        let b = shift(start: base.addingTimeInterval(2 * 3600), hours: 4, user: user)
        XCTAssertEqual(SchedulingEngine.clashes(in: [a, b]).count, 1)
    }

    func testNoClashForDifferentUsers() {
        let base = Date()
        let a = shift(start: base, hours: 4, user: UUID())
        let b = shift(start: base, hours: 4, user: UUID())
        XCTAssertTrue(SchedulingEngine.clashes(in: [a, b]).isEmpty)
    }

    func testWeeklyHoursExcludesBreaks() {
        let user = UUID()
        let s = shift(start: Date(), hours: 8, user: user, breakMinutes: 60)
        let totals = SchedulingEngine.weeklyHours(for: [s])
        XCTAssertEqual(totals[user] ?? 0, 7, accuracy: 0.001)
    }

    func testOvertimeWarningsTriggerAboveThreshold() {
        let user = UUID()
        let day = Date()
        let shifts = (0..<5).map { shift(start: day.addingTimeInterval(Double($0) * 86_400), hours: 9, user: user) }
        let warnings = SchedulingEngine.overtimeWarnings(shifts: shifts, threshold: 40)
        XCTAssertNotNil(warnings[user])
        XCTAssertGreaterThan(warnings[user] ?? 0, 40)
    }

    func testWouldClashDetectsConflict() {
        let user = UUID()
        let base = Date()
        let existing = shift(start: base, hours: 4, user: user)
        let candidate = shift(start: base.addingTimeInterval(3600), hours: 4, user: nil)
        XCTAssertTrue(SchedulingEngine.wouldClash(assigning: candidate, to: user, existing: [existing]))
    }

    func testAutoAssignBalancesLoad() {
        let a = UserProfile(id: UUID(), fullName: "A", email: "a@x.com", phone: nil, avatarURL: nil,
                            jobTitle: nil, role: .employee, organizationId: org, hourlyRate: nil, createdAt: .now)
        let b = UserProfile(id: UUID(), fullName: "B", email: "b@x.com", phone: nil, avatarURL: nil,
                            jobTitle: nil, role: .employee, organizationId: org, hourlyRate: nil, createdAt: .now)
        let day = Date()
        let open1 = shift(start: day, hours: 4, user: nil)
        let open2 = shift(start: day.addingTimeInterval(5 * 3600), hours: 4, user: nil)
        let suggestions = SchedulingEngine.autoAssign(openShifts: [open1, open2], team: [a, b], existing: [])
        XCTAssertEqual(suggestions.count, 2)
        XCTAssertEqual(Set(suggestions.values).count, 2, "Load should be balanced across both employees")
    }
}
