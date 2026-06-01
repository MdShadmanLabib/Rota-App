import SwiftUI

/// Circular avatar with deterministic color + initials fallback.
struct Avatar: View {
    let name: String
    var size: CGFloat = 40
    var imageURL: URL? = nil

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let chars = parts.compactMap { $0.first }
        return String(chars).uppercased()
    }

    private var color: Color {
        let hash = abs(name.hashValue)
        return Theme.Colors.palette[hash % Theme.Colors.palette.count]
    }

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.18))
            if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialsView
                }
                .clipShape(Circle())
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(Theme.Colors.surface, lineWidth: 1.5))
    }

    private var initialsView: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
            .foregroundColor(color)
    }
}
