import SwiftUI

struct VisualizerView: View {
    @EnvironmentObject var appState: AppState
    @State private var isPlaying: Bool = false
    @State private var barHeights: [CGFloat] = Array(repeating: 20, count: 24)
    @State private var wavePhase: CGFloat = 0
    @State private var wavePhase2: CGFloat = 0
    @State private var glowPulse: Bool = false
    @State private var appear: Bool = false
    @State private var showThemeSaved: Bool = false
    @State private var showThemeStudio: Bool = false
    @State private var rotationAngle: Double = 0
    @State private var rhythmPulse: Bool = false
    @State private var bpmDisplay: Int = 120

    let colorCycles: [[Color]] = [
        [.neonPurple, .neonPink, .neonCyan, .neonOrange],
        [.neonCyan, .neonPurple, .neonGreen, .neonPink],
        [.neonOrange, .neonPink, .neonPurple, .neonCyan],
    ]
    @State private var colorCycleIndex: Int = 0

    var currentColors: [Color] { colorCycles[colorCycleIndex] }

    var body: some View {
        ZStack {
            // Deep background
            Color.bgPrimary.ignoresSafeArea()

            // Ambient glow orbs
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(currentColors[i].opacity(0.08))
                    .frame(width: CGFloat([250, 180, 200][i]))
                    .offset(
                        x: CGFloat([-100, 120, 0][i]),
                        y: CGFloat([-200, 100, 250][i]) + (glowPulse ? CGFloat([20, -15, 10][i]) : 0)
                    )
                    .blur(radius: 60)
                    .animation(
                        Animation.easeInOut(duration: Double([3.0, 2.5, 3.5][i]))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.5),
                        value: glowPulse
                    )
            }

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Visualizer")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text(isPlaying ? "Neon flow active" : "Press play to start")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textMuted)
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showThemeStudio = true
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.bgSurface)
                                .frame(width: 44, height: 44)
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 18))
                                .foregroundColor(appState.activeTheme.primaryColor)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: appear)

                Spacer()

                // Central Wave
                ZStack {
                    // Wave layers
                    WaveShape(phase: wavePhase, amplitude: 25, frequency: 2.5)
                        .stroke(
                            LinearGradient(colors: [currentColors[0], currentColors[1]], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .shadow(color: currentColors[0].opacity(0.7), radius: 8)
                        .padding(.horizontal, 20)

                    WaveShape(phase: wavePhase2, amplitude: 15, frequency: 3.5)
                        .stroke(
                            LinearGradient(colors: [currentColors[2], currentColors[3]], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .shadow(color: currentColors[2].opacity(0.5), radius: 6)
                        .opacity(0.7)
                        .padding(.horizontal, 20)
                }
                .frame(height: 80)

                Spacer().frame(height: 24)

                // Main Neon Bars
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(0..<24, id: \.self) { i in
                        let colorIndex = i % currentColors.count
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [currentColors[colorIndex], currentColors[(colorIndex + 1) % currentColors.count]],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: barWidth, height: isPlaying ? max(6, barHeights[i]) : 6)
                            .shadow(color: currentColors[colorIndex].opacity(0.8), radius: 6)
                            .animation(
                                isPlaying
                                    ? Animation.easeInOut(duration: 0.2 + Double(i % 5) * 0.06)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.025)
                                    : .spring(response: 0.3, dampingFraction: 0.7),
                                value: isPlaying ? barHeights[i] : 6
                            )
                    }
                }
                .frame(height: 120)
                .padding(.horizontal, 14)

                Spacer().frame(height: 24)

                // Rhythm Indicator
                rhythmIndicatorView

                Spacer()

                // Controls
                controlsSection

                Spacer().frame(height: 100)
            }

            // Theme saved toast
            if showThemeSaved {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.neonGreen)
                        Text("Theme saved!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.bgCard)
                    .clipShape(Capsule())
                    .shadow(color: .neonGreen.opacity(0.3), radius: 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 110)
                }
            }
        }
        .sheet(isPresented: $showThemeStudio) { ThemeStudioView() }
        .onAppear {
            withAnimation { appear = true; glowPulse = true }
            randomizeBars()
        }
        .onDisappear {
            isPlaying = false
            glowPulse = false
        }
    }

    private var barWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 28
        return (screenWidth - CGFloat(23) * 5) / 24
    }

    // MARK: - Rhythm Indicator
    private var rhythmIndicatorView: some View {
        HStack(spacing: 20) {
            // BPM display
            VStack(spacing: 4) {
                Text("\(bpmDisplay)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(currentColors[0])
                    .shadow(color: currentColors[0].opacity(0.6), radius: 10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: bpmDisplay)
                Text("BPM")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textMuted)
                    .tracking(2)
            }

            // Pulse dots
            HStack(spacing: 8) {
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(i % 2 == 0 ? currentColors[0] : currentColors[1].opacity(0.5))
                        .frame(width: i == 0 ? 14 : 8, height: i == 0 ? 14 : 8)
                        .shadow(color: currentColors[0].opacity(0.7), radius: i == 0 ? 8 : 3)
                        .scaleEffect(rhythmPulse && i == 0 ? 1.3 : 1.0)
                        .animation(
                            isPlaying
                                ? Animation.easeInOut(duration: 60.0 / Double(bpmDisplay))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 60.0 / (Double(bpmDisplay) * 8))
                                : .spring(response: 0.3, dampingFraction: 0.7),
                            value: rhythmPulse
                        )
                }
            }

            // Mode badge
            VStack(spacing: 4) {
                Text(appState.currentMood.rawValue)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(appState.currentMood.color)
                    .shadow(color: appState.currentMood.color.opacity(0.5), radius: 6)
                Text("Mode")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textMuted)
                    .tracking(2)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Controls
    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Main controls
            HStack(spacing: 20) {
                // Change Color
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        colorCycleIndex = (colorCycleIndex + 1) % colorCycles.count
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.bgSurface)
                            .frame(width: 52, height: 52)
                        Image(systemName: "circle.grid.3x3.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(colors: [currentColors[0], currentColors[1]], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Play/Pause
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isPlaying.toggle()
                        rhythmPulse = isPlaying
                    }
                    if isPlaying {
                        randomizeBars()
                        startWaveAnimation()
                        bpmDisplay = Int.random(in: 80...140)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [currentColors[0], currentColors[1]],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: currentColors[0].opacity(0.6), radius: 16)

                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: isPlaying ? 0 : 2)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPlaying ? 1.05 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPlaying)

                // Save Theme
                Button {
                    let theme = NeonTheme(
                        name: "Custom \(appState.savedThemes.count + 1)",
                        primaryHex: currentColors[0].hexString ?? "#8B5CF6",
                        secondaryHex: currentColors[1].hexString ?? "#EC4899",
                        animationSpeed: 1.0
                    )
                    appState.saveCustomTheme(theme)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showThemeSaved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation { showThemeSaved = false }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.bgSurface)
                            .frame(width: 52, height: 52)
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(currentColors[2])
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 32)
    }

    private func randomizeBars() {
        barHeights = (0..<24).map { _ in CGFloat.random(in: 15...100) }
    }

    private func startWaveAnimation() {
        withAnimation(Animation.linear(duration: 2.0 / appState.activeTheme.animationSpeed).repeatForever(autoreverses: false)) {
            wavePhase = .pi * 2
        }
        withAnimation(Animation.linear(duration: 1.5 / appState.activeTheme.animationSpeed).repeatForever(autoreverses: false)) {
            wavePhase2 = .pi * 2
        }
    }
}

// MARK: - Theme Studio
struct ThemeStudioView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var primaryHex: String = "#8B5CF6"
    @State private var secondaryHex: String = "#EC4899"
    @State private var animationSpeed: Double = 1.0
    @State private var themeName: String = ""
    @State private var previewPrimary: Color = .neonPurple
    @State private var previewSecondary: Color = .neonPink
    @State private var showSaved: Bool = false

    var body: some View {
        ZStack {
            LinearGradient.bgGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.textMuted.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 16)

                    Text("Theme Studio")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.textPrimary)

                    // Live preview
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.bgCard)
                            .frame(height: 120)
                        HStack(spacing: 8) {
                            ForEach(0..<12, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [previewPrimary, previewSecondary],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: 14, height: CGFloat.random(in: 20...80))
                                    .shadow(color: previewPrimary.opacity(0.7), radius: 4)
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: primaryHex)
                    }
                    .padding(.horizontal, 18)

                    VStack(spacing: 16) {
                        // Theme Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Theme Name").labelStyle()
                            TextField("My Theme", text: $themeName)
                                .textFieldStyle(NeonTextFieldStyle())
                        }

                        // Primary Color
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary Neon").labelStyle()
                            colorPresetRow(selected: $primaryHex, colors: [
                                "#8B5CF6", "#EC4899", "#22D3EE", "#F97316", "#10B981", "#6366F1"
                            ])
                        }

                        // Secondary Color
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Secondary Neon").labelStyle()
                            colorPresetRow(selected: $secondaryHex, colors: [
                                "#EC4899", "#8B5CF6", "#F97316", "#22D3EE", "#6366F1", "#10B981"
                            ])
                        }

                        // Animation Speed
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Animation Speed").labelStyle()
                                Spacer()
                                Text(speedLabel)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.neonCyan)
                            }
                            Slider(value: $animationSpeed, in: 0.5...2.0, step: 0.1)
                                .accentColor(.neonCyan)
                        }

                        // Preset themes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Saved Themes").labelStyle()
                            ForEach(Array(appState.savedThemes.enumerated()), id: \.offset) { index, theme in
                                Button {
                                    appState.applyTheme(index)
                                } label: {
                                    HStack(spacing: 12) {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(theme.primaryColor)
                                                .frame(width: 20, height: 20)
                                                .shadow(color: theme.primaryColor.opacity(0.6), radius: 4)
                                            Circle()
                                                .fill(theme.secondaryColor)
                                                .frame(width: 20, height: 20)
                                                .shadow(color: theme.secondaryColor.opacity(0.6), radius: 4)
                                        }
                                        Text(theme.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.textPrimary)
                                        Spacer()
                                        if appState.selectedThemeIndex == index {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.neonGreen)
                                        }
                                    }
                                    .padding(14)
                                    .background(Color.bgSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    Button("Save Theme") {
                        let name = themeName.isEmpty ? "Custom Theme" : themeName
                        let theme = NeonTheme(
                            name: name,
                            primaryHex: primaryHex,
                            secondaryHex: secondaryHex,
                            animationSpeed: animationSpeed
                        )
                        appState.saveCustomTheme(theme)
                        showSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .buttonStyle(NeonButtonStyle(color: previewPrimary))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                }
            }
            .onChange(of: primaryHex) { previewPrimary = Color(hex: $0) }
            .onChange(of: secondaryHex) { previewSecondary = Color(hex: $0) }
        }
        .onAppear {
            primaryHex = appState.activeTheme.primaryHex
            secondaryHex = appState.activeTheme.secondaryHex
            animationSpeed = appState.activeTheme.animationSpeed
            previewPrimary = Color(hex: primaryHex)
            previewSecondary = Color(hex: secondaryHex)
        }
    }

    private var speedLabel: String {
        if animationSpeed < 0.9 { return "Slow" }
        if animationSpeed < 1.4 { return "Normal" }
        return "Fast"
    }

    private func colorPresetRow(selected: Binding<String>, colors: [String]) -> some View {
        HStack(spacing: 10) {
            ForEach(colors, id: \.self) { hex in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected.wrappedValue = hex
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 36, height: 36)
                            .shadow(color: Color(hex: hex).opacity(0.6), radius: 6)
                        if selected.wrappedValue == hex {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                                .frame(width: 36, height: 36)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Helpers
extension View {
    func labelStyle() -> some View {
        self
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.textMuted)
            .textCase(.uppercase)
            .tracking(1)
    }
}

struct NeonTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.textPrimary)
            .padding(14)
            .background(Color.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.neonPurple.opacity(0.3), lineWidth: 1)
            )
    }
}

extension Color {
    var hexString: String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
