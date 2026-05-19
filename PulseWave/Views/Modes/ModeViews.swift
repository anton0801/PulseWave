import SwiftUI

// MARK: - Focus Mode
struct FocusModeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDuration: Int = 25
    @State private var selectedSoundType: SoundType = .binaural
    @State private var sessionStarted: Bool = false
    @State private var appear: Bool = false

    let durations = [5, 10, 15, 20, 25, 30, 45, 60]

    var timerProgress: Double {
        let total = Double(selectedDuration * 60)
        let remaining = Double(appState.focusTimerSeconds)
        return sessionStarted ? 1.0 - (remaining / total) : 0.0
    }

    var timeDisplay: String {
        let m = appState.focusTimerSeconds / 60
        let s = appState.focusTimerSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.bgPrimary, Color(hex: "#0A1628"), Color.bgPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(Color.neonCyan.opacity(0.06))
                .frame(width: 400)
                .blur(radius: 80)
                .offset(y: -100)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    HStack {
                        Button {
                            appState.stopFocusTimer()
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Close")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.textMuted)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                        Text("Focus Mode")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Spacer().frame(width: 60)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)

                    // Timer Ring
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(Color.neonCyan.opacity(0.05))
                            .frame(width: 240)
                            .blur(radius: 20)

                        // Background ring
                        Circle()
                            .stroke(Color.bgSurface, lineWidth: 16)
                            .frame(width: 200)

                        // Progress ring
                        Circle()
                            .trim(from: 0, to: timerProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [.neonCyan, .neonPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .frame(width: 200)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: .neonCyan.opacity(0.5), radius: 10)
                            .animation(.linear(duration: 1), value: timerProgress)

                        // Center
                        VStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 20))
                                .foregroundColor(.neonCyan)
                            Text(sessionStarted ? timeDisplay : "\(selectedDuration):00")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.textPrimary)
                                .shadow(color: .neonCyan.opacity(0.3), radius: 8)
                            Text("Focus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textMuted)
                                .tracking(2)
                        }
                    }
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appear)

                    if !sessionStarted {
                        // Duration Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Session Time")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textMuted)
                                .textCase(.uppercase)
                                .tracking(1)
                                .padding(.horizontal, 18)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(durations, id: \.self) { mins in
                                        Button {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                selectedDuration = mins
                                            }
                                        } label: {
                                            VStack(spacing: 2) {
                                                Text("\(mins)")
                                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                                Text("min")
                                                    .font(.system(size: 11, weight: .medium))
                                            }
                                            .foregroundColor(selectedDuration == mins ? .white : .textMuted)
                                            .frame(width: 60, height: 60)
                                            .background(
                                                selectedDuration == mins
                                                    ? Color.neonCyan
                                                    : Color.bgSurface
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .shadow(
                                                color: selectedDuration == mins ? Color.neonCyan.opacity(0.4) : .clear,
                                                radius: 10
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                        }

                        // Sound Type
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sound Type")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textMuted)
                                .textCase(.uppercase)
                                .tracking(1)
                                .padding(.horizontal, 18)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(SoundType.allCases, id: \.self) { type in
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedSoundType = type
                                        }
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(selectedSoundType == type ? .neonCyan : .textMuted)
                                            Text(type.rawValue)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(selectedSoundType == type ? .textPrimary : .textMuted)
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(
                                            selectedSoundType == type
                                                ? Color.neonCyan.opacity(0.15)
                                                : Color.bgSurface
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    selectedSoundType == type ? Color.neonCyan.opacity(0.5) : Color.clear,
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                    }

                    // Control Buttons
                    HStack(spacing: 16) {
                        if sessionStarted {
                            Button("Stop") {
                                appState.stopFocusTimer()
                                withAnimation { sessionStarted = false }
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            Button(appState.isFocusTimerRunning ? "Pause" : "Resume") {
                                appState.pauseFocusTimer()
                            }
                            .buttonStyle(NeonButtonStyle(color: .neonCyan))
                        } else {
                            Button("Start Focus") {
                                appState.startFocusTimer(duration: selectedDuration)
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    sessionStarted = true
                                }
                            }
                            .buttonStyle(NeonButtonStyle(color: .neonCyan))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { withAnimation { appear = true } }
    }
}

// MARK: - Relax Mode
struct RelaxModeView: View {
    @EnvironmentObject var appState: AppState
    @State private var isRelaxing: Bool = false
    @State private var sleepTimerMinutes: Int = 30
    @State private var sleepTimerActive: Bool = false
    @State private var sleepTimerSeconds: Int = 0
    @State private var wavePhase: CGFloat = 0
    @State private var appear: Bool = false
    @State private var breathScale: CGFloat = 1.0
    @State private var sleepTimer: Timer?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#050A1A"), Color(hex: "#0D0A2E"), Color.bgPrimary],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()

            // Stars
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(.white)
                    .frame(width: CGFloat.random(in: 1.5...3.5))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height * 0.6)
                    )
                    .opacity(Double.random(in: 0.3...0.8))
            }

            VStack(spacing: 32) {
                // Title
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#A78BFA"), Color(hex: "#6366F1")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: "#6366F1").opacity(0.6), radius: 20)

                    Text("Relax Mode")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("Breathe. Let go. Drift.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: appear)

                // Breathing orb
                ZStack {
                    Circle()
                        .fill(Color(hex: "#6366F1").opacity(0.08))
                        .frame(width: 200)
                        .blur(radius: 30)
                        .scaleEffect(breathScale * 1.2)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#6366F1").opacity(0.3), Color(hex: "#A78BFA").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#A78BFA").opacity(0.4), lineWidth: 1)
                        )
                        .scaleEffect(breathScale)

                    VStack(spacing: 4) {
                        Image(systemName: isRelaxing ? "wind" : "moon.zzz")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#A78BFA"))
                        Text(isRelaxing ? "Breathe" : "Ready")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                }
                .animation(
                    isRelaxing
                        ? Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)
                        : .spring(response: 0.5, dampingFraction: 0.8),
                    value: breathScale
                )

                // Wave (when active)
                if isRelaxing {
                    WaveShape(phase: wavePhase, amplitude: 10, frequency: 2)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#6366F1"), Color(hex: "#A78BFA"), Color(hex: "#6366F1")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                        )
                        .frame(height: 30)
                        .shadow(color: Color(hex: "#6366F1").opacity(0.5), radius: 4)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                }

                // Sleep Timer
                VStack(spacing: 12) {
                    HStack {
                        Text("Sleep Timer")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textSecondary)
                        Spacer()
                        if sleepTimerActive {
                            Text(sleepTimerDisplay)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#A78BFA"))
                        }
                    }

                    HStack(spacing: 12) {
                        ForEach([15, 30, 45, 60], id: \.self) { mins in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    sleepTimerMinutes = mins
                                }
                            } label: {
                                Text("\(mins)m")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(sleepTimerMinutes == mins ? .white : .textMuted)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        sleepTimerMinutes == mins
                                            ? Color(hex: "#6366F1")
                                            : Color.bgSurface
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 32)

                // Buttons
                VStack(spacing: 12) {
                    Button(isRelaxing ? "Stop Relax" : "Start Relax") {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isRelaxing.toggle()
                            breathScale = isRelaxing ? 1.3 : 1.0
                        }
                        if isRelaxing {
                            startWaveAnimation()
                        }
                    }
                    .buttonStyle(NeonButtonStyle(color: Color(hex: "#6366F1")))

                    if !sleepTimerActive {
                        Button("Set Sleep Timer") {
                            startSleepTimer()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    } else {
                        Button("Cancel Timer") {
                            cancelSleepTimer()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { withAnimation { appear = true } }
        .onDisappear { sleepTimer?.invalidate(); isRelaxing = false }
    }

    private var sleepTimerDisplay: String {
        let m = sleepTimerSeconds / 60
        let s = sleepTimerSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func startWaveAnimation() {
        withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            wavePhase = .pi * 2
        }
    }

    private func startSleepTimer() {
        sleepTimerSeconds = sleepTimerMinutes * 60
        sleepTimerActive = true
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if sleepTimerSeconds > 0 {
                sleepTimerSeconds -= 1
            } else {
                isRelaxing = false
                sleepTimerActive = false
                sleepTimer?.invalidate()
            }
        }
    }

    private func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimerActive = false
        sleepTimerSeconds = 0
    }
}

// MARK: - Energy Mode
struct EnergyModeView: View {
    @EnvironmentObject var appState: AppState
    @State private var isActive: Bool = false
    @State private var energyLevel: Double = 0.3
    @State private var boostProgress: Double = 0
    @State private var barHeights: [CGFloat] = Array(repeating: 10, count: 16)
    @State private var appear: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var sessionSeconds: Int = 0
    @State private var sessionTimer: Timer?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.bgPrimary, Color(hex: "#1A0A00"), Color.bgPrimary],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()

            // Orange glow
            Circle()
                .fill(Color.neonOrange.opacity(0.07))
                .frame(width: 350)
                .blur(radius: 80)
                .offset(y: 50)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Title
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Energy Mode")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.textPrimary)
                            Text(isActive ? "Boosting energy..." : "Ready to power up")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textMuted)
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.neonOrange.opacity(0.15))
                                .frame(width: 50, height: 50)
                                .scaleEffect(pulseScale)
                                .animation(
                                    isActive
                                        ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                                        : .spring(response: 0.4, dampingFraction: 0.7),
                                    value: pulseScale
                                )
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.neonOrange)
                                .shadow(color: .neonOrange.opacity(0.7), radius: 10)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.4), value: appear)

                    // Energy Boost Line Chart
                    NeonCard(glowColor: .neonOrange) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Energy Boost Line")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.textMuted)
                                    .textCase(.uppercase)
                                    .tracking(1)
                                Spacer()
                                Text("\(Int(boostProgress * 100))%")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(.neonOrange)
                                    .shadow(color: .neonOrange.opacity(0.5), radius: 6)
                            }

                            // Boost progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.bgSurface)
                                        .frame(height: 12)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [.neonOrange, .neonPink],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * boostProgress, height: 12)
                                        .shadow(color: .neonOrange.opacity(0.6), radius: 6)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: boostProgress)
                                }
                            }
                            .frame(height: 12)

                            // Session time
                            if isActive {
                                Text("Session: \(sessionTimeDisplay)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(18)
                    }
                    .padding(.horizontal, 18)

                    // Energy Bars Visualizer
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(0..<16, id: \.self) { i in
                            let colors: [Color] = [.neonOrange, .neonPink, .neonOrange, .neonPink]
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [colors[i % 4], colors[(i + 1) % 4].opacity(0.7)],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 14, height: isActive ? barHeights[i] : 10)
                                .shadow(color: Color.neonOrange.opacity(0.6), radius: 4)
                                .animation(
                                    isActive
                                        ? Animation.easeInOut(duration: 0.15 + Double(i % 4) * 0.05)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.03)
                                        : .spring(response: 0.4, dampingFraction: 0.7),
                                    value: isActive ? barHeights[i] : 10
                                )
                        }
                    }
                    .frame(height: 80)
                    .padding(.horizontal, 18)

                    // Intensity stats
                    HStack(spacing: 0) {
                        energyStatBlock(value: "\(Int(appState.currentEnergyLevel * 100))%", label: "Current")
                        Divider().background(Color.bgSurface).frame(height: 40)
                        energyStatBlock(value: "\(Int(boostProgress * 100))%", label: "Boosted")
                        Divider().background(Color.bgSurface).frame(height: 40)
                        energyStatBlock(value: sessionTimeDisplay, label: "Duration")
                    }
                    .padding(.horizontal, 18)

                    // Button
                    Button(isActive ? "Stop Energy Mode" : "Start Energy Mode") {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isActive.toggle()
                            pulseScale = isActive ? 1.2 : 1.0
                        }
                        if isActive {
                            randomizeBars()
                            startSession()
                        } else {
                            stopSession()
                        }
                    }
                    .buttonStyle(NeonButtonStyle(color: .neonOrange))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { withAnimation { appear = true } }
        .onDisappear { stopSession() }
    }

    private func energyStatBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.neonOrange)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.bgCard)
    }

    private var sessionTimeDisplay: String {
        let m = sessionSeconds / 60
        let s = sessionSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func randomizeBars() {
        barHeights = (0..<16).map { _ in CGFloat.random(in: 20...70) }
    }

    private func startSession() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            sessionSeconds += 1
            let newBoost = min(1.0, boostProgress + 0.005)
            boostProgress = newBoost
            if sessionSeconds % 5 == 0 { randomizeBars() }
        }
    }

    private func stopSession() {
        sessionTimer?.invalidate()
        isActive = false
        pulseScale = 1.0
    }
}
