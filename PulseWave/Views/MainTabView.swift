import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case 0: DashboardView()
                case 1: VisualizerView()
                case 2: PlaylistsView()
                case 3: StatsView()
                case 4: SettingsView()
                default: DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var appState: AppState

    let tabs: [(icon: String, label: String)] = [
        ("house.fill",          "Home"),
        ("waveform.path.ecg",   "Visualizer"),
        ("music.note.list",     "Playlists"),
        ("chart.bar.fill",      "Stats"),
        ("gearshape.fill",      "Settings"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == index {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appState.activeTheme.primaryColor.opacity(0.15))
                                    .frame(width: 44, height: 32)
                            }
                            Image(systemName: tabs[index].icon)
                                .font(.system(size: 18, weight: selectedTab == index ? .semibold : .regular))
                                .foregroundColor(selectedTab == index ? appState.activeTheme.primaryColor : .textMuted)
                                .shadow(
                                    color: selectedTab == index ? appState.activeTheme.primaryColor.opacity(0.7) : .clear,
                                    radius: 8
                                )
                                .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                        }
                        Text(tabs[index].label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == index ? appState.activeTheme.primaryColor : .textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            ZStack {
                Color.bgDeep
                LinearGradient(
                    colors: [Color.clear, appState.activeTheme.primaryColor.opacity(0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(appState.activeTheme.primaryColor.opacity(0.2)),
                alignment: .top
            )
        )
    }
}
