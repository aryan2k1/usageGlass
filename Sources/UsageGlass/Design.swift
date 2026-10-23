import SwiftUI

/// Shared design language: green below 80%, amber from 80%, red from 90%.
enum UsagePalette {
    static let green = (r: 0.20, g: 0.78, b: 0.45)
    static let amber = (r: 1.00, g: 0.69, b: 0.12)
    static let red   = (r: 0.96, g: 0.26, b: 0.24)

    /// Colour for a usage percentage (0...100). The whole bar takes one colour:
    /// green below 80%, amber from 80%, red from 90%.
    static func color(_ percent: Double) -> Color {
        let p = min(max(percent, 0), 100)
        return p >= 90 ? rgb(red) : p >= 80 ? rgb(amber) : rgb(green)
    }
    private static func rgb(_ c: (r: Double, g: Double, b: Double)) -> Color { Color(red: c.r, green: c.g, blue: c.b) }
    /// Subtle same-hue sheen so the single colour still feels like glass.
    static func fill(for percent: Double) -> LinearGradient {
        let base = color(percent)
        return LinearGradient(colors: [base.opacity(0.85), base], startPoint: .leading, endPoint: .trailing)
    }
}

/// Horizontal capsule bar, one colour for the whole fill.
struct GradientBar: View {
    let value: Double?
    var height: CGFloat = 6
    private var safe: Double? { value.flatMap { $0.isFinite ? min(max($0, 0), 100) : nil } }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.09))
                if let safe, safe > 0 {
                    Capsule().fill(UsagePalette.fill(for: safe))
                        .frame(width: max(geo.size.width * safe / 100, height))
                        .shadow(color: UsagePalette.color(safe).opacity(0.35), radius: 3)
                }
            }
        }.frame(height: height).accessibilityHidden(true)
    }
}

/// Stylised marks for the two providers (drawn here, not official logo files).
struct ProviderMark: View {
    let provider: ProviderID
    var size: CGFloat = 18
    var body: some View {
        switch provider {
        case .claude:
            ClaudeSpark().fill(provider.tint).frame(width: size, height: size)
        case .codex:
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.28).fill(provider.tint)
                Image(systemName: "chevron.right").font(.system(size: size * 0.38, weight: .black)).foregroundStyle(.white).offset(x: -size * 0.14, y: -size * 0.02)
                Capsule().fill(.white).frame(width: size * 0.26, height: size * 0.09).offset(x: size * 0.16, y: size * 0.14)
            }.frame(width: size, height: size)
        }
    }
}

private struct ClaudeSpark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let rays = 12
        for i in 0..<rays {
            let angle = Double(i) / Double(rays) * 2 * .pi
            let long = i % 2 == 0
            let length = r * (long ? 1.0 : 0.72)
            let half = r * 0.085
            let dir = CGPoint(x: cos(angle), y: sin(angle))
            let normal = CGPoint(x: -dir.y, y: dir.x)
            path.move(to: CGPoint(x: c.x + normal.x * half, y: c.y + normal.y * half))
            path.addLine(to: CGPoint(x: c.x + dir.x * length, y: c.y + dir.y * length))
            path.addLine(to: CGPoint(x: c.x - normal.x * half, y: c.y - normal.y * half))
            path.closeSubpath()
        }
        return path
    }
}
