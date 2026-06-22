import SwiftUI
import WebKit

struct ScopeView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false

    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                ScopeRig(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: .scopeReload)) { _ in reload() }
    }

    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: VitalsKey.pushURL)
        let stored = UserDefaults.standard.string(forKey: VitalsKey.feedURL) ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: VitalsKey.pushURL) }
    }

    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: VitalsKey.pushURL), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: VitalsKey.pushURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

struct ScopeRig: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> ScopeProbe { ScopeProbe() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func buildWebView(coordinator: ScopeProbe) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

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
            appState.audio.stop()
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
                        appState.audio.play(soundType: .binaural)
                    } else {
                        appState.audio.stop()
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

final class ScopeProbe: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = Vitals.cookieMonitor

    func loadURL(_ url: URL, in webView: WKWebView) {
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }

    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }

    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
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

extension View {
    func labelStyle() -> some View {
        self
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.textMuted)
            .textCase(.uppercase)
            .tracking(1)
    }
}

extension ScopeProbe: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension ScopeProbe: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
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

extension ScopeProbe: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}
