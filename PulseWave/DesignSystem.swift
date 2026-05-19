import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let bgPrimary    = Color(hex: "#070B1F")
    static let bgDeep       = Color(hex: "#111827")
    static let bgPurple     = Color(hex: "#1E1B4B")
    static let bgCard       = Color(hex: "#0F1629")
    static let bgSurface    = Color(hex: "#1E293B")

    // Neon Accents
    static let neonPurple   = Color(hex: "#8B5CF6")
    static let neonPink     = Color(hex: "#EC4899")
    static let neonCyan     = Color(hex: "#22D3EE")
    static let neonOrange   = Color(hex: "#F97316")
    static let neonGreen    = Color(hex: "#10B981")

    // Text
    static let textPrimary  = Color(hex: "#F8FAFC")
    static let textSecondary = Color(hex: "#CBD5F5")
    static let textMuted    = Color(hex: "#64748B")

    // Glow colors (low opacity versions)
    static let glowPurple   = Color(hex: "#8B5CF6").opacity(0.4)
    static let glowPink     = Color(hex: "#EC4899").opacity(0.35)
    static let glowCyan     = Color(hex: "#22D3EE").opacity(0.35)
    static let glowOrange   = Color(hex: "#F97316").opacity(0.3)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let bgGradient = LinearGradient(
        colors: [Color.bgPrimary, Color.bgPurple, Color.bgDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let neonPurplePink = LinearGradient(
        colors: [Color.neonPurple, Color.neonPink],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let neonCyanPurple = LinearGradient(
        colors: [Color.neonCyan, Color.neonPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let neonOrangeGradient = LinearGradient(
        colors: [Color.neonOrange, Color.neonPink],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Mood Model
enum Mood: String, CaseIterable, Codable {
    case focus   = "Focus"
    case chill   = "Chill"
    case energy  = "Energy"
    case night   = "Night"
    case happy   = "Happy"

    var icon: String {
        switch self {
        case .focus:  return "brain.head.profile"
        case .chill:  return "snowflake"
        case .energy: return "bolt.fill"
        case .night:  return "moon.stars.fill"
        case .happy:  return "sun.max.fill"
        }
    }

    var color: Color {
        switch self {
        case .focus:  return .neonCyan
        case .chill:  return .neonPurple
        case .energy: return .neonOrange
        case .night:  return Color(hex: "#6366F1")
        case .happy:  return .neonPink
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .focus:  return LinearGradient(colors: [.neonCyan, Color(hex: "#0EA5E9")], startPoint: .leading, endPoint: .trailing)
        case .chill:  return LinearGradient(colors: [.neonPurple, Color(hex: "#6366F1")], startPoint: .leading, endPoint: .trailing)
        case .energy: return LinearGradient(colors: [.neonOrange, .neonPink], startPoint: .leading, endPoint: .trailing)
        case .night:  return LinearGradient(colors: [Color(hex: "#6366F1"), Color(hex: "#1E1B4B")], startPoint: .leading, endPoint: .trailing)
        case .happy:  return LinearGradient(colors: [.neonPink, Color(hex: "#FB923C")], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Custom Button Styles
struct NeonButtonStyle: ButtonStyle {
    var color: Color = .neonPurple
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.neonPurple.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Neon Card
struct NeonCard<Content: View>: View {
    var glowColor: Color = .neonPurple
    let content: Content

    init(glowColor: Color = .neonPurple, @ViewBuilder content: () -> Content) {
        self.glowColor = glowColor
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [glowColor.opacity(0.5), glowColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: glowColor.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}
