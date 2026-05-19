import SwiftUI

struct SplashView: View {
    @Binding var isVisible: Bool

    // Phase flags
    @State private var bgPhase: Bool = false
    @State private var wavePhase: Bool = false
    @State private var titlePhase: Bool = false
    @State private var exitPhase: Bool = false

    // Wave animation
    @State private var waveOffset1: CGFloat = 0
    @State private var waveOffset2: CGFloat = 0
    @State private var waveOffset3: CGFloat = 0
    @State private var barHeights: [CGFloat] = Array(repeating: 20, count: 18)
    @State private var glowPulse: Bool = false
    @State private var particleOffset: CGFloat = 0

    let barCount = 18

    var body: some View {
        ZStack {
            // Layer 1: Animated Background
            LinearGradient(
                colors: bgPhase
                    ? [Color(hex: "#070B1F"), Color(hex: "#1E1B4B"), Color(hex: "#0D0A2E")]
                    : [Color(hex: "#0D0A2E"), Color(hex: "#070B1F"), Color(hex: "#1E1B4B")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(
                Animation.linear(duration: 3.0).repeatForever(autoreverses: true),
                value: bgPhase
            )

            // Floating orbs
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(
                        [Color.neonPurple, Color.neonPink, Color.neonCyan, Color.neonOrange][i]
                            .opacity(0.12)
                    )
                    .frame(width: CGFloat([180, 120, 150, 100][i]))
                    .offset(
                        x: CGFloat([-80, 100, -50, 120][i]),
                        y: CGFloat([-150, 80, 200, -100][i]) + (glowPulse ? CGFloat([20, -15, 10, -20][i]) : 0)
                    )
                    .blur(radius: 40)
                    .animation(
                        Animation.easeInOut(duration: Double([2.5, 3.0, 2.0, 3.5][i]))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.3),
                        value: glowPulse
                    )
            }

            VStack(spacing: 0) {
                Spacer()

                // Layer 2: Audio Bars Visualizer
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<barCount, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(barGradient(index: i))
                            .frame(width: 12, height: wavePhase ? barHeights[i] : 4)
                            .shadow(
                                color: barColor(index: i).opacity(0.7),
                                radius: 6, x: 0, y: 0
                            )
                            .animation(
                                Animation.easeInOut(duration: 0.3 + Double(i % 5) * 0.08)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.04),
                                value: wavePhase
                            )
                    }
                }
                .opacity(wavePhase ? 1 : 0)
                .animation(.easeIn(duration: 0.6), value: wavePhase)

                Spacer().frame(height: 40)

                // Layer 3: Logo + Title
                VStack(spacing: 12) {
                    // Icon ring
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.neonPurple, .neonPink, .neonCyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: .neonPurple.opacity(0.6), radius: 15)

                        Image(systemName: "waveform.path.ecg.rectangle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.neonCyan, .neonPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(titlePhase ? 1.0 : 0.3)
                    .opacity(titlePhase ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.1), value: titlePhase)

                    Text("Pulse Wave")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "#CBD5F5")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .neonPurple.opacity(0.5), radius: 12)
                        .scaleEffect(titlePhase ? 1.0 : 0.6)
                        .opacity(titlePhase ? 1.0 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2), value: titlePhase)

                    Text("Control your daily pulse")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .tracking(1.5)
                        .opacity(titlePhase ? 1.0 : 0)
                        .offset(y: titlePhase ? 0 : 10)
                        .animation(.easeOut(duration: 0.5).delay(0.35), value: titlePhase)
                }

                Spacer()
            }

            // Exit overlay
            Color.bgPrimary
                .ignoresSafeArea()
                .opacity(exitPhase ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: exitPhase)
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }

    private func barGradient(index: Int) -> LinearGradient {
        let colors: [[Color]] = [
            [.neonPurple, Color(hex: "#A78BFA")],
            [.neonPink, Color(hex: "#F472B6")],
            [.neonCyan, Color(hex: "#67E8F9")],
            [.neonOrange, Color(hex: "#FBA94C")],
        ]
        return LinearGradient(
            colors: colors[index % colors.count],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private func barColor(index: Int) -> Color {
        let colors: [Color] = [.neonPurple, .neonPink, .neonCyan, .neonOrange]
        return colors[index % colors.count]
    }

    private func startAnimations() {
        // Phase 1: Background
        withAnimation { bgPhase = true }
        withAnimation { glowPulse = true }

        // Phase 2: Bars (0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard isVisible else { return }
            randomizeBarHeights()
            withAnimation { wavePhase = true }
        }

        // Phase 3: Title (1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard isVisible else { return }
            withAnimation { titlePhase = true }
        }

        // Phase 4: Exit (2.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            guard isVisible else { return }
            withAnimation { exitPhase = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isVisible = false
            }
        }
    }

    private func stopAnimations() {
        bgPhase = false
        wavePhase = false
        titlePhase = false
        glowPulse = false
        exitPhase = false
        barHeights = Array(repeating: 20, count: barCount)
    }

    private func randomizeBarHeights() {
        barHeights = (0..<barCount).map { _ in CGFloat.random(in: 20...90) }
    }
}
