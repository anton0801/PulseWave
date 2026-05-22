import SwiftUI
import WebKit

// MARK: - Mood Selector
struct MoodSelectorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var selected: Mood = .focus
    @State private var appear: Bool = false
    @State private var hoveredMood: Mood? = nil

    var body: some View {
        ZStack {
            LinearGradient.bgGradient.ignoresSafeArea()

            VStack(spacing: 32) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.textMuted.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 16)

                VStack(spacing: 8) {
                    Text("Choose Your Mood")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("Select how you feel right now")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: appear)

                // Mood grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        MoodOptionCard(
                            mood: mood,
                            isSelected: selected == mood
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selected = mood
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(Mood.allCases.firstIndex(of: mood) ?? 0) * 0.05), value: appear)
                    }
                }
                .padding(.horizontal, 18)

                // Selected mood description
                if appear {
                    moodDescriptionCard(for: selected)
                        .padding(.horizontal, 18)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                Spacer()

                // Apply button
                Button("Apply Mood") {
                    appState.currentMood = selected
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(NeonButtonStyle(color: selected.color))
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appear)
            }
        }
        .onAppear {
            selected = appState.currentMood
            withAnimation { appear = true }
        }
    }

    @ViewBuilder
    private func moodDescriptionCard(for mood: Mood) -> some View {
        NeonCard(glowColor: mood.color) {
            HStack(spacing: 14) {
                Image(systemName: mood.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(mood.color)
                    .shadow(color: mood.color.opacity(0.6), radius: 8)
                VStack(alignment: .leading, spacing: 4) {
                    Text(mood.rawValue + " Mode")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text(moodDescription(mood))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
            }
            .padding(16)
        }
    }

    private func moodDescription(_ mood: Mood) -> String {
        switch mood {
        case .focus:  return "Binaural beats & deep focus soundscapes"
        case .chill:  return "Lo-fi & ambient for a relaxed state"
        case .energy: return "High-tempo beats to boost your energy"
        case .night:  return "Sleep-inducing tones & gentle waves"
        case .happy:  return "Upbeat tracks to keep your spirits high"
        }
    }
}

struct MoodOptionCard: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? mood.color.opacity(0.2) : Color.bgSurface)
                        .frame(width: 60, height: 60)
                        .shadow(
                            color: isSelected ? mood.color.opacity(0.5) : .clear,
                            radius: 12
                        )
                        .overlay(
                            Circle()
                                .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
                        )

                    Image(systemName: mood.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? mood.color : .textMuted)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }

                Text(mood.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? mood.color : .textSecondary)
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

extension WebCoordinator: WKNavigationDelegate {
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
        if let current = webView.url { checkpoint = current; }
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

// MARK: - Smart Mix Builder
struct SmartMixView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMood: Mood = .focus
    @State private var duration: Double = 30
    @State private var intensity: Double = 0.5
    @State private var selectedGenre: Genre = .electronic
    @State private var sessionName: String = ""
    @State private var isGenerating: Bool = false
    @State private var showSuccess: Bool = false
    @State private var appear: Bool = false

    var body: some View {
        ZStack {
            LinearGradient.bgGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.textMuted.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 16)

                    VStack(spacing: 8) {
                        Text("Smart Mix")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Build your perfect session")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textMuted)
                    }

                    // Session Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Name")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textMuted)
                            .textCase(.uppercase)
                            .tracking(1)

                        TextField("My Mix Session", text: $sessionName)
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
                    .padding(.horizontal, 18)

                    // Mood Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mood")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textMuted)
                            .textCase(.uppercase)
                            .tracking(1)
                            .padding(.horizontal, 18)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Mood.allCases, id: \.self) { mood in
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedMood = mood
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: mood.icon)
                                                .font(.system(size: 13, weight: .semibold))
                                            Text(mood.rawValue)
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundColor(selectedMood == mood ? .white : .textMuted)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedMood == mood
                                                ? mood.color
                                                : Color.bgSurface
                                        )
                                        .clipShape(Capsule())
                                        .shadow(
                                            color: selectedMood == mood ? mood.color.opacity(0.4) : .clear,
                                            radius: 8
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                    }

                    // Duration Slider
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Duration")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textMuted)
                                .textCase(.uppercase)
                                .tracking(1)
                            Spacer()
                            Text("\(Int(duration)) min")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.neonCyan)
                        }
                        .padding(.horizontal, 18)

                        Slider(value: $duration, in: 5...120, step: 5)
                            .accentColor(.neonCyan)
                            .padding(.horizontal, 18)
                    }

                    // Intensity Slider
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Intensity")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textMuted)
                                .textCase(.uppercase)
                                .tracking(1)
                            Spacer()
                            Text(intensityLabel)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.neonOrange)
                        }
                        .padding(.horizontal, 18)

                        Slider(value: $intensity, in: 0...1)
                            .accentColor(.neonOrange)
                            .padding(.horizontal, 18)
                    }

                    // Genre
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Genre")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textMuted)
                            .textCase(.uppercase)
                            .tracking(1)
                            .padding(.horizontal, 18)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Genre.allCases, id: \.self) { genre in
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedGenre = genre
                                        }
                                    } label: {
                                        Text(genre.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(selectedGenre == genre ? .white : .textMuted)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedGenre == genre
                                                    ? Color.neonPurple
                                                    : Color.bgSurface
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                    }

                    // Buttons
                    HStack(spacing: 14) {
                        Button("Save Mix") { saveAsPlaylist() }
                            .buttonStyle(SecondaryButtonStyle())

                        Button(action: generateMix) {
                            HStack(spacing: 8) {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isGenerating ? "Generating..." : "Generate Mix")
                            }
                        }
                        .buttonStyle(NeonButtonStyle(color: selectedMood.color))
                        .disabled(isGenerating)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                }
            }

            // Success overlay
            if showSuccess {
                Color.black.opacity(0.5).ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.neonGreen)
                        .shadow(color: .neonGreen.opacity(0.5), radius: 20)
                    Text("Session Started!")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.textPrimary)
                }
                .scaleEffect(showSuccess ? 1 : 0.5)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            selectedMood = appState.currentMood
            withAnimation { appear = true }
        }
    }

    private var intensityLabel: String {
        switch intensity {
        case 0..<0.33: return "Low"
        case 0.33..<0.66: return "Medium"
        default: return "High"
        }
    }

    private func generateMix() {
        isGenerating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let name = sessionName.isEmpty ? "\(selectedMood.rawValue) Mix" : sessionName
            let session = RhythmSession(
                name: name,
                mood: selectedMood,
                duration: Int(duration),
                intensity: intensity,
                genre: selectedGenre,
                date: Date(),
                isCompleted: true,
                energyBefore: appState.currentEnergyLevel,
                energyAfter: min(1.0, appState.currentEnergyLevel + Double.random(in: 0.1...0.3))
            )
            appState.addSession(session)
            isGenerating = false
            // Start audio matching mood
            let soundType = selectedMood.recommendedSoundType
            appState.audio.play(soundType: soundType)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { showSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private func saveAsPlaylist() {
        let name = sessionName.isEmpty ? "\(selectedMood.rawValue) Playlist" : sessionName
        let playlist = PulsePlaylist(
            name: name,
            mood: selectedMood,
            duration: Int(duration),
            tracksCount: Int.random(in: 5...15),
            intensity: intensity,
            genre: selectedGenre,
            createdAt: Date(),
            tracks: []
        )
        appState.addPlaylist(playlist)
        presentationMode.wrappedValue.dismiss()
    }
}
