import SwiftUI
import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

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

final class HTTPBuoyLocator: BuoyLocator {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    private let waitMarkers: [Double] = [84.0, 168.0, 336.0]
    
    func locate(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: BeaconConstants.backendLighthouse) else {
            throw WaveFault.payloadShattered(stage: "endpoint URL")
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(BeaconConstants.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: BeaconKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastFault: Error?
        var attempts = 0
        
        for (idx, wait) in waitMarkers.enumerated() {
            attempts += 1
            do {
                return try await singleShot(request)
            } catch let fault as WaveFault {
                if case .buoyDenied = fault {
                    throw fault
                }
                if case .currentBacklogged(let retryAfter) = fault {
                    try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                    continue
                }
                lastFault = fault
                if idx < waitMarkers.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
            } catch {
                lastFault = error
                if idx < waitMarkers.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
            }
        }
        
        if let lastFault = lastFault {
            throw lastFault
        }
        throw WaveFault.wireSnapped(attempts: attempts)
    }
    
    private func singleShot(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw WaveFault.wireSnapped(attempts: 0)
        }
        
        if http.statusCode == 404 {
            throw WaveFault.buoyDenied(httpCode: 404)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WaveFault.payloadShattered(stage: "JSON parse")
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw WaveFault.payloadShattered(stage: "missing 'ok'")
        }
        
        if !ok {
            throw WaveFault.buoyDenied(httpCode: 200)
        }
        
        guard let url = json["url"] as? String else {
            throw WaveFault.payloadShattered(stage: "missing 'url'")
        }
        
        return url
    }
}


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
