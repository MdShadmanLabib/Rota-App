import Foundation

/// Deterministic, realistic sample dataset that powers MOCK mode so the app
/// is fully explorable in the Simulator without any backend configuration.
struct SampleData {
    var organization: Organization
    var profiles: [UserProfile]
    var shifts: [Shift]
    var templates: [ShiftTemplate]
    var leaveRequests: [LeaveRequest]
    var swapRequests: [SwapRequest]
    var timeEntries: [TimeEntry]
    var availability: [Availability]
    var announcements: [Announcement]

    /// Demo credentials shown on the sign-in screen.
    static let employerEmail = "owner@rota.app"
    static let employeeEmail = "alex@rota.app"
    static let demoPassword = "password"

    static let orgId = UUID(uuidString: "00000000-0000-0000-0000-0000000000A0")!
    static let ownerId = UUID(uuidString: "00000000-0000-0000-0000-0000000000B0")!

    static func build() -> SampleData {
        let org = Organization(
            id: orgId,
            name: "Brew & Co.",
            inviteCode: "BREW42",
            timezone: TimeZone.current.identifier,
            weeklyOvertimeThreshold: 40,
            workplaceLatitude: 51.5074,
            workplaceLongitude: -0.1278,
            clockInRadiusMeters: 150,
            createdAt: .now.adding(days: -120)
        )

        let owner = UserProfile(id: ownerId, fullName: "Jordan Avery", email: employerEmail, phone: "+44 7700 900111", avatarURL: nil, jobTitle: "Store Manager", role: .owner, organizationId: orgId, hourlyRate: 24, createdAt: .now.adding(days: -120))

        let staffSeed: [(String, String, String, Double)] = [
            ("Alex Morgan", employeeEmail, "Barista", 12.5),
            ("Sam Patel", "sam@rota.app", "Barista", 12.5),
            ("Riley Chen", "riley@rota.app", "Floor", 11.8),
            ("Casey Lopez", "casey@rota.app", "Floor", 11.8),
            ("Jamie Khan", "jamie@rota.app", "Kitchen", 13.2),
            ("Taylor Reed", "taylor@rota.app", "Shift Lead", 15.0)
        ]

        var profiles: [UserProfile] = [owner]
        for (i, s) in staffSeed.enumerated() {
            profiles.append(UserProfile(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000C\(i)")!,
                fullName: s.0, email: s.1, phone: nil, avatarURL: nil, jobTitle: s.2,
                role: i == staffSeed.count - 1 ? .manager : .employee,
                organizationId: orgId, hourlyRate: s.3, createdAt: .now.adding(days: -90)
            ))
        }
        let staff = Array(profiles.dropFirst())

        // Templates
        let templates: [ShiftTemplate] = [
            ShiftTemplate(id: UUID(), organizationId: orgId, name: "Opening", role: "Barista", startTime: "07:00", endTime: "15:00", breakMinutes: 30, colorHex: "#6366F1"),
            ShiftTemplate(id: UUID(), organizationId: orgId, name: "Mid", role: "Floor", startTime: "11:00", endTime: "19:00", breakMinutes: 30, colorHex: "#10B981"),
            ShiftTemplate(id: UUID(), organizationId: orgId, name: "Closing", role: "Shift Lead", startTime: "15:00", endTime: "23:00", breakMinutes: 30, colorHex: "#F59E0B")
        ]

        // Shifts across last week + this week + next week
        var shifts: [Shift] = []
        let weekStart = Date().startOfWeek
        let roles = ["Barista", "Floor", "Kitchen", "Shift Lead"]
        let palette = ["#6366F1", "#10B981", "#EC4899", "#F59E0B"]
        for weekOffset in -1...1 {
            let base = weekStart.adding(weeks: weekOffset)
            for day in 0..<7 {
                let dayDate = base.adding(days: day)
                let shiftsPerDay = (day == 5 || day == 6) ? 4 : 3
                for slot in 0..<shiftsPerDay {
                    let roleIndex = slot % roles.count
                    let startHour = 7 + slot * 4
                    let start = Calendar.current.date(bySettingHour: startHour, minute: 0, second: 0, of: dayDate) ?? dayDate
                    let end = start.addingTimeInterval(8 * 3600)
                    let assignee = staff[(day + slot + weekOffset + 8) % staff.count]
                    let isPast = end < .now
                    shifts.append(Shift(
                        id: UUID(), organizationId: orgId,
                        title: roles[roleIndex], role: roles[roleIndex],
                        location: "Main Floor",
                        startAt: start, endAt: end, breakMinutes: 30,
                        assignedUserId: slot == 3 ? nil : assignee.id,
                        status: isPast ? .completed : .published,
                        notes: slot == 0 ? "Open the till and prep the espresso machine." : nil,
                        colorHex: palette[roleIndex],
                        createdBy: ownerId, createdAt: .now.adding(days: -14)
                    ))
                }
            }
        }

        // Leave requests
        let leaveRequests: [LeaveRequest] = [
            LeaveRequest(id: UUID(), organizationId: orgId, userId: staff[0].id, type: .holiday, startDate: .now.adding(days: 9), endDate: .now.adding(days: 13), reason: "Family trip", status: .pending, reviewedBy: nil, createdAt: .now.adding(days: -2)),
            LeaveRequest(id: UUID(), organizationId: orgId, userId: staff[2].id, type: .sick, startDate: .now.adding(days: -3), endDate: .now.adding(days: -3), reason: "Flu", status: .approved, reviewedBy: ownerId, createdAt: .now.adding(days: -4)),
            LeaveRequest(id: UUID(), organizationId: orgId, userId: staff[1].id, type: .unpaid, startDate: .now.adding(days: 20), endDate: .now.adding(days: 21), reason: nil, status: .pending, reviewedBy: nil, createdAt: .now.adding(days: -1))
        ]

        // Swap requests
        let swapShift = shifts.first(where: { $0.assignedUserId == staff[1].id && $0.startAt > .now }) ?? shifts[0]
        let swapRequests: [SwapRequest] = [
            SwapRequest(id: UUID(), organizationId: orgId, shiftId: swapShift.id, requestedBy: staff[1].id, targetUserId: nil, message: "Can anyone cover? Dentist appointment.", status: .pending, createdAt: .now.adding(days: -1))
        ]

        // Time entries (completed past shifts -> worked hours)
        var timeEntries: [TimeEntry] = []
        for shift in shifts where shift.status == .completed && shift.assignedUserId != nil {
            let inAt = shift.startAt.addingTimeInterval(Double.random(in: -300...600))
            let outAt = shift.endAt.addingTimeInterval(Double.random(in: -600...900))
            timeEntries.append(TimeEntry(
                id: UUID(), organizationId: orgId, userId: shift.assignedUserId!, shiftId: shift.id,
                clockInAt: inAt, clockOutAt: outAt,
                clockInLat: 51.5074, clockInLng: -0.1278, method: "geo",
                createdAt: inAt
            ))
        }

        // Availability for the demo employee (Alex): available Mon–Fri 9–6
        var availability: [Availability] = []
        for weekday in 1...7 {
            let weekend = weekday >= 6
            availability.append(Availability(
                id: UUID(), organizationId: orgId, userId: staff[0].id,
                weekday: weekday, isAvailable: !weekend,
                startTime: weekend ? nil : "09:00", endTime: weekend ? nil : "18:00"
            ))
        }

        let announcements: [Announcement] = [
            Announcement(id: UUID(), organizationId: orgId, authorId: ownerId, authorName: owner.fullName, title: "New espresso blend launching Monday", body: "We're rolling out the new house blend next week. Tasting session Sunday 4pm — all welcome!", isPinned: true, createdAt: .now.adding(days: -1)),
            Announcement(id: UUID(), organizationId: orgId, authorId: ownerId, authorName: owner.fullName, title: "Holiday rota reminder", body: "Please submit December holiday requests by the 25th so we can plan coverage.", isPinned: false, createdAt: .now.adding(days: -5))
        ]

        return SampleData(
            organization: org, profiles: profiles, shifts: shifts, templates: templates,
            leaveRequests: leaveRequests, swapRequests: swapRequests, timeEntries: timeEntries,
            availability: availability, announcements: announcements
        )
    }
}
