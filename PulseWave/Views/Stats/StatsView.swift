import SwiftUI

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPeriod: Int = 7
    @State private var appear: Bool = false

    let periods = [7, 14, 30]

    var summary: StatsSummary {
        appState.getStatsSummary(days: selectedPeriod)
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.bgGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Analytics")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                Text("Your energy journey")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.4), value: appear)

                        // Period picker
                        HStack(spacing: 0) {
                            ForEach(periods, id: \.self) { period in
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedPeriod = period
                                    }
                                } label: {
                                    Text("\(period)d")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(selectedPeriod == period ? .white : .textMuted)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedPeriod == period
                                                ? appState.activeTheme.primaryColor
                                                : Color.clear
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(4)
                        .background(Color.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 18)

                        // Key metrics
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(
                                icon: "headphones",
                                value: "\(summary.minutesListened)",
                                unit: "min",
                                label: "Total Listened",
                                color: .neonPurple
                            )
                            StatCard(
                                icon: "brain.head.profile",
                                value: "\(summary.focusSessions)",
                                unit: "sessions",
                                label: "Focus Sessions",
                                color: .neonCyan
                            )
                            StatCard(
                                icon: "bolt.fill",
                                value: "\(Int(summary.avgEnergyLevel * 100))%",
                                unit: "",
                                label: "Avg Energy",
                                color: .neonOrange
                            )
                            StatCard(
                                icon: "flame.fill",
                                value: "\(summary.streakDays)",
                                unit: "days",
                                label: "Current Streak",
                                color: .neonPink
                            )
                        }
                        .padding(.horizontal, 18)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: appear)

                        // Energy line chart
                        NeonCard(glowColor: appState.activeTheme.primaryColor) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Energy Over Time")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.textMuted)
                                    .textCase(.uppercase)
                                    .tracking(1)

                                EnergyMiniChart(entries: appState.weekEnergyData())
                                    .frame(height: 100)

                                // Day labels
                                HStack {
                                    ForEach(dayLabels(), id: \.self) { label in
                                        Text(label)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.textMuted)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            .padding(18)
                        }
                        .padding(.horizontal, 18)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: appear)

                        // Mood usage
                        NeonCard(glowColor: .neonPink) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Mood Usage")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.textMuted)
                                    .textCase(.uppercase)
                                    .tracking(1)

                                VStack(spacing: 10) {
                                    ForEach(Mood.allCases, id: \.self) { mood in
                                        let count = summary.moodUsage[mood] ?? 0
                                        let maxCount = summary.moodUsage.values.max() ?? 1
                                        MoodUsageBar(
                                            mood: mood,
                                            count: count,
                                            maxCount: maxCount
                                        )
                                    }
                                }
                            }
                            .padding(18)
                        }
                        .padding(.horizontal, 18)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: appear)

                        // Top mood badge
                        NeonCard(glowColor: summary.topMood.color) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(summary.topMood.color.opacity(0.15))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: summary.topMood.icon)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(summary.topMood.color)
                                        .shadow(color: summary.topMood.color.opacity(0.6), radius: 8)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Favorite Mood")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.textMuted)
                                        .textCase(.uppercase)
                                        .tracking(1)
                                    Text(summary.topMood.rawValue)
                                        .font(.system(size: 22, weight: .black, design: .rounded))
                                        .foregroundColor(summary.topMood.color)
                                    Text("Most used in the last \(selectedPeriod) days")
                                        .font(.system(size: 12))
                                        .foregroundColor(.textMuted)
                                }
                                Spacer()
                            }
                            .padding(18)
                        }
                        .padding(.horizontal, 18)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.25), value: appear)

                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear { withAnimation { appear = true } }
    }

    private func dayLabels() -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).map { offset -> String in
            let date = Calendar.current.date(byAdding: .day, value: -(6 - offset), to: Date())!
            return formatter.string(from: date)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        NeonCard(glowColor: color) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(color)
                            .shadow(color: color.opacity(0.5), radius: 4)
                    }
                    Spacer()
                }
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.textPrimary)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textMuted)
                    }
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textMuted)
            }
            .padding(16)
        }
    }
}

// MARK: - Mood Usage Bar
struct MoodUsageBar: View {
    let mood: Mood
    let count: Int
    let maxCount: Int

    var progress: Double {
        maxCount == 0 ? 0 : Double(count) / Double(maxCount)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mood.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(mood.color)
                .frame(width: 20)

            Text(mood.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textSecondary)
                .frame(width: 55, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.bgSurface)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(mood.gradient)
                        .frame(width: geo.size.width * progress, height: 8)
                        .shadow(color: mood.color.opacity(0.4), radius: 4)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)

            Text("\(count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.textSecondary)
                .frame(width: 24, alignment: .trailing)
        }
    }
}
