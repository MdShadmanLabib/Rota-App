import UIKit

/// Renders a weekly rota into a shareable PDF document.
enum PDFExporter {

    static func exportWeeklyRota(
        organizationName: String,
        weekStart: Date,
        shifts: [Shift],
        nameFor: (UUID?) -> String
    ) -> URL? {
        let pageWidth: CGFloat = 612   // US Letter @ 72dpi
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 36
        let bounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Rota-\(weekStart.formatted("yyyy-MM-dd")).pdf")

        let days = weekStart.weekDays
        let byDay: [[Shift]] = days.map { day in
            shifts.filter { $0.startAt.isSameDay(as: day) }.sorted { $0.startAt < $1.startAt }
        }

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                var y: CGFloat = margin

                draw("\(organizationName) — Weekly Rota", at: CGPoint(x: margin, y: y),
                     font: .systemFont(ofSize: 20, weight: .bold))
                y += 26
                draw("Week of \(weekStart.formatted("d MMM yyyy"))", at: CGPoint(x: margin, y: y),
                     font: .systemFont(ofSize: 12, weight: .regular), color: .darkGray)
                y += 28

                for (i, day) in days.enumerated() {
                    if y > pageHeight - margin - 60 {
                        ctx.beginPage(); y = margin
                    }
                    draw(day.formatted("EEEE d MMM"), at: CGPoint(x: margin, y: y),
                         font: .systemFont(ofSize: 14, weight: .semibold))
                    y += 20

                    if byDay[i].isEmpty {
                        draw("— No shifts", at: CGPoint(x: margin + 12, y: y),
                             font: .systemFont(ofSize: 11), color: .gray)
                        y += 18
                    } else {
                        for shift in byDay[i] {
                            let line = "\(shift.timeRangeLabel)  •  \(shift.title)  •  \(nameFor(shift.assignedUserId))"
                            draw(line, at: CGPoint(x: margin + 12, y: y),
                                 font: .systemFont(ofSize: 11), color: .black)
                            y += 16
                        }
                    }
                    y += 10
                }
            }
            return url
        } catch {
            return nil
        }
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = .black) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        text.draw(at: point, withAttributes: attrs)
    }
}
