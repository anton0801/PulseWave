import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showMoodSelector: Bool = false
    @State private var showSmartMix: Bool = false
    @State private var showVisualizer: Bool = false
    @State private var showFocusMode: Bool = false
    @State private var appear: Bool = false
    @State private var energyDrag: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.bgGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Header
                        headerSection
                            .padding(.horizontal, 18)

                        // Energy Meter
                        energyMeterCard
                            .padding(.horizontal, 18)

                        // Mood Selector Quick
                        moodQuickSelector
                            .padding(.horizontal, 18)

                        // Quick Actions Grid
                        quickActionsGrid
                            .padding(.horizontal, 18)

                        // Today Sessions
                        todaySessionsSection
                            .padding(.horizontal, 18)

                        // Weekly Energy Chart
                        weeklyEnergyCard
                            .padding(.horizontal, 18)

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showMoodSelector) { MoodSelectorView() }
        .sheet(isPresented: $showSmartMix) { SmartMixView() }
        .sheet(isPresented: $showFocusMode) { FocusModeView() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appear = true }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good \(timeOfDay)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textMuted)
                Text("Pulse Wave")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.textPrimary, Color(hex: "#CBD5F5")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(appState.activeTheme.primaryColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .shadow(color: appState.activeTheme.primaryColor.opacity(0.3), radius: 10)
                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(appState.activeTheme.primaryColor)
            }
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : -10)
        .animation(.easeOut(duration: 0.4), value: appear)
    }

    // MARK: - Energy Meter
    private var energyMeterCard: some View {
        NeonCard(glowColor: appState.currentMood.color) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Energy Level")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textMuted)
                        .textCase(.uppercase)
                        .tracking(1)
                    Spacer()
                    Text("\(Int(appState.currentEnergyLevel * 100))%")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(appState.currentMood.color)
                        .shadow(color: appState.currentMood.color.opacity(0.5), radius: 8)
                }

                // Energy slider
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.bgSurface)
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(appState.currentMood.gradient)
                            .frame(width: geo.size.width * appState.currentEnergyLevel, height: 16)
                            .shadow(color: appState.currentMood.color.opacity(0.6), radius: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appState.currentEnergyLevel)

                        // Handle
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: appState.currentMood.color.opacity(0.5), radius: 6)
                            .offset(x: max(0, geo.size.width * appState.currentEnergyLevel - 12))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appState.currentEnergyLevel)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newValue = max(0, min(1, value.location.x / geo.size.width))
                                appState.currentEnergyLevel = newValue
                            }
                            .onEnded { _ in
                                appState.updateCurrentEnergy(appState.currentEnergyLevel)
                            }
                    )
                }
                .frame(height: 24)

                // Energy labels
                HStack {
                    Text("Low")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textMuted)
                    Spacer()
                    Text("Peak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textMuted)
                }
            }
            .padding(18)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: appear)
    }

    // MARK: - Mood Quick Selector
    private var moodQuickSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Mood")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                Button("Change") { showMoodSelector = true }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(appState.activeTheme.primaryColor)
            }

            HStack(spacing: 10) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            appState.currentMood = mood
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(appState.currentMood == mood
                                          ? mood.color.opacity(0.2)
                                          : Color.bgSurface)
                                    .frame(width: 44, height: 44)
                                    .shadow(
                                        color: appState.currentMood == mood ? mood.color.opacity(0.4) : .clear,
                                        radius: 8
                                    )
                                Image(systemName: mood.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(appState.currentMood == mood ? mood.color : .textMuted)
                            }
                            Text(mood.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(appState.currentMood == mood ? mood.color : .textMuted)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appear)
    }

    // MARK: - Quick Actions Grid
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickActionCard(
                icon: "sparkles",
                title: "Start Mix",
                subtitle: "Generate now",
                color: .neonPurple
            ) { showSmartMix = true }

            QuickActionCard(
                icon: "timer",
                title: "Focus Timer",
                subtitle: "Concentrate",
                color: .neonCyan
            ) { showFocusMode = true }

            NavigationLink(destination: RelaxModeView()) {
                QuickActionContent(
                    icon: "moon.zzz.fill",
                    title: "Relax",
                    subtitle: "Wind down",
                    color: Color(hex: "#6366F1")
                )
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: EnergyModeView()) {
                QuickActionContent(
                    icon: "bolt.fill",
                    title: "Energy",
                    subtitle: "Power up",
                    color: .neonOrange
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.15), value: appear)
    }

    // MARK: - Today Sessions
    private var todaySessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today Sessions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                Text("\(appState.todaySessions().count) sessions")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textMuted)
            }

            if appState.todaySessions().isEmpty {
                NeonCard(glowColor: .neonPurple) {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.textMuted)
                        Text("No sessions today. Start your first mix!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textMuted)
                    }
                    .padding(18)
                }
            } else {
                ForEach(appState.todaySessions().prefix(3)) { session in
                    SessionRowCard(session: session)
                }
            }
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appear)
    }

    // MARK: - Weekly Energy Chart
    private var weeklyEnergyCard: some View {
        NeonCard(glowColor: appState.activeTheme.primaryColor) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Energy This Week")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)

                EnergyMiniChart(entries: appState.weekEnergyData())
                    .frame(height: 80)
            }
            .padding(18)
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.25), value: appear)
    }

    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Morning" }
        if hour < 17 { return "Afternoon" }
        return "Evening"
    }
}

struct PulseWaveConsentView: View {
    let viewModel: PulseWaveViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("waves")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    vertView
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var vertView: some View {
        VStack(spacing: 12) {
            Spacer()
            titleText
                .multilineTextAlignment(.center)
            subtitleText
                .multilineTextAlignment(.center)
            actionButtons
        }
        .padding(.bottom, 24)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 23, weight: .black, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            ac
            sk
        }
        .padding(.horizontal, 12)
    }
    
    private var ac: some View {
        Button {
            viewModel.acceptConsent()
        } label: {
            Image("wavesb")
                .resizable()
                .frame(width: 300, height: 55)
        }
    }
    
    private var sk: some View {
        Button {
            viewModel.skipConsent()
        } label: {
            Text("Skip")
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
                .opacity(0.5)
        }
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 13, weight: .heavy, design: .monospaced))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
}


// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            QuickActionContent(icon: icon, title: title, subtitle: subtitle, color: color)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionContent: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 6)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textMuted)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Session Row Card
struct SessionRowCard: View {
    let session: RhythmSession

    var body: some View {
        NeonCard(glowColor: session.mood.color) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(session.mood.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: session.mood.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(session.mood.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text("\(session.mood.rawValue) · \(session.durationText) · \(session.genre.rawValue)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if session.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.neonGreen)
                            .font(.system(size: 16))
                    }
                    Text("+\(Int((session.energyAfter - session.energyBefore) * 100))%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(session.energyAfter > session.energyBefore ? .neonGreen : .neonOrange)
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Mini Energy Chart
struct EnergyMiniChart: View {
    let entries: [EnergyEntry]

    var body: some View {
        GeometryReader { geo in
            if entries.isEmpty {
                Text("No data yet")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                let sorted = entries.sorted { $0.date < $1.date }
                let maxH = geo.size.height
                let spacing = geo.size.width / CGFloat(max(sorted.count - 1, 1))

                ZStack {
                    // Area fill
                    Path { path in
                        guard !sorted.isEmpty else { return }
                        let first = sorted[0]
                        path.move(to: CGPoint(x: 0, y: maxH))
                        path.addLine(to: CGPoint(x: 0, y: maxH * (1 - first.level)))
                        for (i, entry) in sorted.enumerated() {
                            path.addLine(to: CGPoint(x: CGFloat(i) * spacing, y: maxH * (1 - entry.level)))
                        }
                        path.addLine(to: CGPoint(x: CGFloat(sorted.count - 1) * spacing, y: maxH))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.neonPurple.opacity(0.3), Color.neonPurple.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        guard !sorted.isEmpty else { return }
                        path.move(to: CGPoint(x: 0, y: maxH * (1 - sorted[0].level)))
                        for (i, entry) in sorted.enumerated() {
                            path.addLine(to: CGPoint(x: CGFloat(i) * spacing, y: maxH * (1 - entry.level)))
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.neonCyan, .neonPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .shadow(color: .neonPurple.opacity(0.5), radius: 4)

                    // Dots
                    ForEach(Array(sorted.enumerated()), id: \.offset) { i, entry in
                        Circle()
                            .fill(entry.mood.color)
                            .frame(width: 6, height: 6)
                            .shadow(color: entry.mood.color.opacity(0.8), radius: 4)
                            .position(x: CGFloat(i) * spacing, y: maxH * (1 - entry.level))
                    }
                }
            }
        }
    }
}
