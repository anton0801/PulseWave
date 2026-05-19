import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var appear: Bool = false
    @State private var showNotificationAlert: Bool = false
    @State private var notificationAlertMessage: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.bgGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Settings")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                Text("Customize Pulse Wave")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeOut(duration: 0.4), value: appear)

                        // Profile summary
                        profileSummaryCard
                            .padding(.horizontal, 18)

                        // Sound Quality
                        settingsSection(title: "Audio") {
                            VStack(spacing: 0) {
                                SettingsPickerRow(
                                    icon: "headphones",
                                    iconColor: .neonCyan,
                                    title: "Sound Quality",
                                    options: ["Low", "Medium", "High"],
                                    selected: $appState.soundQuality
                                )
                            }
                        }
                        .padding(.horizontal, 18)

                        // Visualizer
                        settingsSection(title: "Visualizer") {
                            SettingsToggleRow(
                                icon: "waveform.path.ecg",
                                iconColor: .neonPurple,
                                title: "Visualizer Effects",
                                subtitle: "Glow, shadows, particles",
                                isOn: $appState.visualizerEffects
                            )
                        }
                        .padding(.horizontal, 18)

                        // Theme
                        settingsSection(title: "Appearance") {
                            VStack(spacing: 0) {
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(appState.activeTheme.primaryColor.opacity(0.15))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "paintpalette.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(appState.activeTheme.primaryColor)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Active Theme")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.textPrimary)
                                        Text(appState.activeTheme.name)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.textMuted)
                                    }
                                    .padding(.leading, 10)
                                    Spacer()

                                    HStack(spacing: 4) {
                                        Circle().fill(appState.activeTheme.primaryColor).frame(width: 14, height: 14)
                                        Circle().fill(appState.activeTheme.secondaryColor).frame(width: 14, height: 14)
                                    }
                                }
                                .padding(14)

                                Divider().background(Color.bgSurface)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Array(appState.savedThemes.enumerated()), id: \.offset) { index, theme in
                                            Button {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                    appState.applyTheme(index)
                                                }
                                            } label: {
                                                VStack(spacing: 6) {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(
                                                                LinearGradient(
                                                                    colors: [theme.primaryColor, theme.secondaryColor],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                )
                                                            )
                                                            .frame(width: 50, height: 50)
                                                            .shadow(
                                                                color: theme.primaryColor.opacity(appState.selectedThemeIndex == index ? 0.5 : 0),
                                                                radius: 8
                                                            )
                                                        if appState.selectedThemeIndex == index {
                                                            Image(systemName: "checkmark")
                                                                .font(.system(size: 14, weight: .bold))
                                                                .foregroundColor(.white)
                                                        }
                                                    }
                                                    Text(theme.name)
                                                        .font(.system(size: 9, weight: .semibold))
                                                        .foregroundColor(appState.selectedThemeIndex == index ? theme.primaryColor : .textMuted)
                                                        .lineLimit(1)
                                                        .frame(width: 50)
                                                }
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(
                                                            appState.selectedThemeIndex == index ? theme.primaryColor : Color.clear,
                                                            lineWidth: 2
                                                        )
                                                        .padding(.bottom, 20)
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        // Notifications
                        settingsSection(title: "Notifications") {
                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    icon: "bell.fill",
                                    iconColor: .neonOrange,
                                    title: "Enable Notifications",
                                    subtitle: "Reminders and check-ins",
                                    isOn: Binding(
                                        get: { appState.notificationsEnabled },
                                        set: { newValue in
                                            if newValue {
                                                requestNotificationPermission()
                                            } else {
                                                appState.notificationsEnabled = false
                                                cancelAllNotifications()
                                            }
                                        }
                                    )
                                )

                                if appState.notificationsEnabled {
                                    Divider().background(Color.bgSurface)

                                    SettingsToggleRow(
                                        icon: "brain.head.profile",
                                        iconColor: .neonCyan,
                                        title: "Focus Reminder",
                                        subtitle: "Daily focus session prompt",
                                        isOn: Binding(
                                            get: { appState.focusReminderEnabled },
                                            set: { newValue in
                                                appState.focusReminderEnabled = newValue
                                                scheduleNotification(
                                                    id: "focus_reminder",
                                                    title: "Time to Focus 🎯",
                                                    body: "Start a focus session and boost your productivity.",
                                                    hour: appState.focusReminderHour,
                                                    enabled: newValue
                                                )
                                            }
                                        )
                                    )

                                    if appState.focusReminderEnabled {
                                        HStack {
                                            Text("Focus time:")
                                                .font(.system(size: 13))
                                                .foregroundColor(.textMuted)
                                                .padding(.leading, 56)
                                            Picker("", selection: $appState.focusReminderHour) {
                                                ForEach(6...22, id: \.self) { h in
                                                    Text("\(h):00").tag(h)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .foregroundColor(.neonCyan)
                                            .onChange(of: appState.focusReminderHour) { hour in
                                                scheduleNotification(
                                                    id: "focus_reminder",
                                                    title: "Time to Focus 🎯",
                                                    body: "Start a focus session and boost your productivity.",
                                                    hour: hour,
                                                    enabled: appState.focusReminderEnabled
                                                )
                                            }
                                            Spacer()
                                        }
                                        .padding(.bottom, 8)
                                    }

                                    Divider().background(Color.bgSurface)

                                    SettingsToggleRow(
                                        icon: "moon.zzz.fill",
                                        iconColor: Color(hex: "#6366F1"),
                                        title: "Relax Reminder",
                                        subtitle: "Evening wind-down prompt",
                                        isOn: Binding(
                                            get: { appState.relaxReminderEnabled },
                                            set: { newValue in
                                                appState.relaxReminderEnabled = newValue
                                                scheduleNotification(
                                                    id: "relax_reminder",
                                                    title: "Time to Relax 🌙",
                                                    body: "Start a relax session and wind down for the evening.",
                                                    hour: appState.relaxReminderHour,
                                                    enabled: newValue
                                                )
                                            }
                                        )
                                    )

                                    Divider().background(Color.bgSurface)

                                    SettingsToggleRow(
                                        icon: "bolt.heart.fill",
                                        iconColor: .neonPink,
                                        title: "Daily Mood Check",
                                        subtitle: "Morning energy check-in",
                                        isOn: Binding(
                                            get: { appState.dailyMoodCheckEnabled },
                                            set: { newValue in
                                                appState.dailyMoodCheckEnabled = newValue
                                                scheduleNotification(
                                                    id: "mood_check",
                                                    title: "How's your energy? ⚡",
                                                    body: "Log your morning energy level and start your day right.",
                                                    hour: appState.moodCheckHour,
                                                    enabled: newValue
                                                )
                                            }
                                        )
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        // Data
                        settingsSection(title: "Data") {
                            Button {
                                resetData()
                            } label: {
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.neonPink.opacity(0.15))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.neonPink)
                                    }
                                    Text("Reset All Data")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.neonPink)
                                        .padding(.leading, 10)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.textMuted)
                                }
                                .padding(14)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 18)

                        // App version
                        Text("Pulse Wave v1.0.0")
                            .font(.system(size: 12))
                            .foregroundColor(.textMuted)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .alert("Notification Permission", isPresented: $showNotificationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(notificationAlertMessage)
        }
        .onAppear { withAnimation { appear = true } }
    }

    // MARK: - Profile Summary
    private var profileSummaryCard: some View {
        NeonCard(glowColor: appState.currentMood.color) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(appState.currentMood.color.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(appState.currentMood.color)
                        .shadow(color: appState.currentMood.color.opacity(0.5), radius: 8)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pulse Wave User")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textPrimary)
                    HStack(spacing: 12) {
                        Label("\(appState.sessions.count) sessions", systemImage: "music.note")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textMuted)
                        Label("Mood: \(appState.currentMood.rawValue)", systemImage: appState.currentMood.icon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(appState.currentMood.color)
                    }
                }
                Spacer()
            }
            .padding(16)
        }
    }

    // MARK: - Section Builder
    @ViewBuilder
    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textMuted)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.horizontal, 4)

            NeonCard(glowColor: appState.activeTheme.primaryColor) {
                content()
            }
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appear)
    }

    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    appState.notificationsEnabled = true
                    notificationAlertMessage = "Notifications enabled! You can now set up reminders."
                } else {
                    appState.notificationsEnabled = false
                    notificationAlertMessage = "Please enable notifications in Settings > Pulse Wave to receive reminders."
                }
                showNotificationAlert = true
            }
        }
    }

    private func scheduleNotification(id: String, title: String, body: String, hour: Int, enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func resetData() {
        appState.energyEntries = []
        appState.sessions = []
        appState.playlists = []
        appState.trackNotes = []
        appState.focusSessions = []
        UserDefaults.standard.removeObject(forKey: "pulse_energy_entries")
        UserDefaults.standard.removeObject(forKey: "pulse_sessions")
        UserDefaults.standard.removeObject(forKey: "pulse_playlists")
        UserDefaults.standard.removeObject(forKey: "pulse_track_notes")
        UserDefaults.standard.removeObject(forKey: "pulse_focus_sessions")
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textMuted)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: iconColor))
                .labelsHidden()
        }
        .padding(14)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isOn)
    }
}

// MARK: - Settings Picker Row
struct SettingsPickerRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let options: [String]
    @Binding var selected: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)
            Spacer()
            Picker("", selection: $selected) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .accentColor(iconColor)
        }
        .padding(14)
    }
}
