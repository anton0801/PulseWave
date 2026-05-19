import SwiftUI

// MARK: - Onboarding Container
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingPage1(currentPage: $currentPage).tag(0)
                OnboardingPage2(currentPage: $currentPage).tag(1)
                OnboardingPage3(currentPage: $currentPage, onFinish: finishOnboarding).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        finishOnboarding()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textMuted)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                }
                .padding(.top, 16)

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.neonPurple : Color.textMuted.opacity(0.4))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }

    private func finishOnboarding() {
        withAnimation { appState.hasCompletedOnboarding = true }
    }
}

// MARK: - Page 1: Choose Your Sound Mood (Tap to burst)
struct OnboardingPage1: View {
    @Binding var currentPage: Int
    @State private var isBursting: Bool = false
    @State private var particles: [OnboardingParticle] = []
    @State private var moodScale: CGFloat = 1.0
    @State private var appear: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Interactive zone: tap to burst particles
            ZStack {
                // Background glow ring
                Circle()
                    .stroke(Color.neonPurple.opacity(0.2), lineWidth: 1)
                    .frame(width: 200, height: 200)
                    .scaleEffect(isBursting ? 1.4 : 1.0)
                    .opacity(isBursting ? 0 : 1)
                    .animation(.easeOut(duration: 0.5), value: isBursting)

                // Mood icons ring
                ZStack {
                    ForEach(Array(Mood.allCases.enumerated()), id: \.offset) { index, mood in
                        let angle = Double(index) / Double(Mood.allCases.count) * .pi * 2
                        let radius: CGFloat = 80
                        Image(systemName: mood.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(mood.color)
                            .shadow(color: mood.color.opacity(0.6), radius: 8)
                            .offset(
                                x: cos(angle) * radius,
                                y: sin(angle) * radius
                            )
                            .scaleEffect(isBursting ? 1.4 : (appear ? 1.0 : 0.3))
                            .opacity(isBursting ? 0 : (appear ? 1 : 0))
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.6)
                                    .delay(Double(index) * 0.06),
                                value: appear
                            )
                            .animation(.easeOut(duration: 0.4), value: isBursting)
                    }

                    // Center icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.neonPurple, .neonPink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: .neonPurple.opacity(0.6), radius: 20)

                        Image(systemName: "music.note.list")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(moodScale)
                    .onTapGesture { triggerBurst() }
                }

                // Burst particles
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: particle.offsetX, y: particle.offsetY)
                        .opacity(particle.opacity)
                        .blur(radius: 1)
                }
            }
            .frame(height: 260)

            Text("Tap to explore moods")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textMuted)
                .padding(.top, 12)

            Spacer().frame(height: 40)

            VStack(spacing: 16) {
                Text("Choose your sound mood")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appear)

                Text("Select how you feel and get a matching music setup.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 15)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: appear)
            }

            Spacer()

            Button("Next") { currentPage = 1 }
                .buttonStyle(NeonButtonStyle(color: .neonPurple))
                .padding(.horizontal, 32)
                .padding(.bottom, 80)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: appear)
        }
        .onAppear { appear = true }
        .onDisappear { appear = false; particles = []; isBursting = false }
    }

    private func triggerBurst() {
        let colors: [Color] = [.neonPurple, .neonPink, .neonCyan, .neonOrange, .neonGreen]
        particles = (0..<20).map { i in
            OnboardingParticle(
                color: colors[i % colors.count],
                size: CGFloat.random(in: 4...12),
                offsetX: CGFloat.random(in: -120...120),
                offsetY: CGFloat.random(in: -120...120),
                opacity: 1.0
            )
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            isBursting = true
            moodScale = 1.3
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            particles = particles.map { p in
                var updated = p
                updated.opacity = 0
                return updated
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isBursting = false
                moodScale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                particles = []
            }
        }
    }
}

struct OnboardingParticle: Identifiable {
    var id = UUID()
    var color: Color
    var size: CGFloat
    var offsetX: CGFloat
    var offsetY: CGFloat
    var opacity: Double
}

// MARK: - Page 2: Control Your Rhythm (Drag gesture)
struct OnboardingPage2: View {
    @Binding var currentPage: Int
    @State private var dragOffset: CGSize = .zero
    @State private var sliderValue: Double = 0.5
    @State private var appear: Bool = false
    @State private var modeIndex: Int = 1

    let modes = ["Relax", "Focus", "Energy"]
    let modeColors: [Color] = [.neonCyan, .neonPurple, .neonOrange]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Interactive: drag the rhythm dial
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.bgSurface, lineWidth: 20)
                    .frame(width: 200, height: 200)

                // Progress arc
                Circle()
                    .trim(from: 0, to: sliderValue)
                    .stroke(
                        modeColors[modeIndex],
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: modeColors[modeIndex].opacity(0.6), radius: 10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: sliderValue)

                // Center content
                VStack(spacing: 4) {
                    Text(modes[modeIndex])
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(modeColors[modeIndex])
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: modeIndex)

                    Text("\(Int(sliderValue * 100))%")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.textPrimary)
                }

                // Drag handle
                Circle()
                    .fill(modeColors[modeIndex])
                    .frame(width: 24, height: 24)
                    .shadow(color: modeColors[modeIndex], radius: 8)
                    .offset(
                        x: 100 * cos((sliderValue * .pi * 2) - .pi / 2),
                        y: 100 * sin((sliderValue * .pi * 2) - .pi / 2)
                    )
            }
            .frame(height: 240)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let center = CGPoint(x: 0, y: 0)
                        let loc = value.location
                        let angle = atan2(loc.y - center.y, loc.x - center.x) + .pi / 2
                        var normalized = (angle < 0 ? angle + .pi * 2 : angle) / (.pi * 2)
                        normalized = max(0.01, min(0.99, normalized))
                        sliderValue = normalized
                        modeIndex = normalized < 0.33 ? 0 : normalized < 0.66 ? 1 : 2
                    }
            )

            Text("Drag to set intensity")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textMuted)
                .padding(.top, 12)

            Spacer().frame(height: 40)

            VStack(spacing: 16) {
                Text("Control your rhythm")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)

                Text("Use focus, energy and relax modes during the day.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appear)
            }

            Spacer()

            HStack(spacing: 16) {
                Button("Back") { currentPage = 0 }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Next") { currentPage = 2 }
                    .buttonStyle(NeonButtonStyle(color: .neonPurple))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 80)
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: appear)
        }
        .onAppear { appear = true }
        .onDisappear { appear = false }
    }
}

// MARK: - Page 3: Watch the Neon Flow (Scroll-driven)
struct OnboardingPage3: View {
    @Binding var currentPage: Int
    var onFinish: () -> Void

    @State private var appear: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var wavePhase: CGFloat = 0
    @State private var barPhase: Bool = false
    @State private var barHeights: [CGFloat] = Array(repeating: 30, count: 12)

    let barColors: [Color] = [.neonPurple, .neonPink, .neonCyan, .neonOrange, .neonGreen, .neonPurple,
                               .neonCyan, .neonPink, .neonOrange, .neonPurple, .neonCyan, .neonPink]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Interactive: scroll-driven visualizer
            ZStack {
                // Background glow
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.neonPurple.opacity(0.2), lineWidth: 1)
                    )

                VStack(spacing: 16) {
                    // Neon bars
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(0..<12, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [barColors[i], barColors[(i + 3) % 12]],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 16, height: barPhase ? barHeights[i] : 8)
                                .shadow(color: barColors[i].opacity(0.7), radius: 6)
                                .animation(
                                    Animation.easeInOut(duration: 0.4 + Double(i) * 0.05)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.04),
                                    value: barPhase
                                )
                        }
                    }
                    .frame(height: 80)

                    // Sine wave
                    WaveShape(phase: wavePhase, amplitude: 15, frequency: 3)
                        .stroke(
                            LinearGradient(
                                colors: [.neonCyan, .neonPurple, .neonPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(height: 40)
                        .shadow(color: .neonCyan.opacity(0.5), radius: 6)

                    Text("Neon Visualizer")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textMuted)
                        .tracking(2)
                        .textCase(.uppercase)
                }
                .padding(20)
            }
            .frame(height: 200)
            .padding(.horizontal, 32)

            Text("Scroll to animate")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textMuted)
                .padding(.top, 12)

            Spacer().frame(height: 40)

            VStack(spacing: 16) {
                Text("Watch the neon flow")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)

                Text("Color lines react to your audio and session progress.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appear)
            }

            Spacer()

            HStack(spacing: 16) {
                Button("Back") { currentPage = 1 }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Get Started") { onFinish() }
                    .buttonStyle(NeonButtonStyle(color: .neonPurple))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 80)
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: appear)
        }
        .onAppear {
            appear = true
            barHeights = (0..<12).map { _ in CGFloat.random(in: 25...80) }
            withAnimation { barPhase = true }
            startWaveAnimation()
        }
        .onDisappear {
            appear = false
            barPhase = false
        }
    }

    private func startWaveAnimation() {
        withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            wavePhase = .pi * 2
        }
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let y = midY + amplitude * sin(frequency * .pi * 2 * relativeX + phase)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}
