import SwiftUI

@main
struct PulseWaveApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash: Bool = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView(isVisible: $showSplash)
                    .transition(.opacity)
                    .zIndex(1)
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
                    .zIndex(0)
            } else {
                MainTabView()
                    .transition(.opacity)
                    .zIndex(0)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
        .preferredColorScheme(.dark)
    }
}
