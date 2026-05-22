import SwiftUI
import Combine

class AppState: ObservableObject {

    // MARK: - Audio
    let audio = PulseAudioEngine()
    // MARK: - Persisted Settings
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("selectedThemeIndex") var selectedThemeIndex: Int = 0
    @AppStorage("soundQuality") var soundQuality: String = "High"
    @AppStorage("visualizerEffects") var visualizerEffects: Bool = true
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
    @AppStorage("focusReminderEnabled") var focusReminderEnabled: Bool = false
    @AppStorage("relaxReminderEnabled") var relaxReminderEnabled: Bool = false
    @AppStorage("dailyMoodCheckEnabled") var dailyMoodCheckEnabled: Bool = false
    @AppStorage("focusReminderHour") var focusReminderHour: Int = 10
    @AppStorage("relaxReminderHour") var relaxReminderHour: Int = 20
    @AppStorage("moodCheckHour") var moodCheckHour: Int = 9

    // MARK: - Current Session State
    @Published var currentMood: Mood = .focus
    @Published var currentEnergyLevel: Double = 0.6
    @Published var isSessionActive: Bool = false
    @Published var activeSessionType: SessionType = .none
    @Published var focusTimerSeconds: Int = 0
    @Published var isFocusTimerRunning: Bool = false

    // MARK: - Active Neon Theme
    @Published var activeTheme: NeonTheme = NeonTheme.defaults[0]

    // MARK: - Data
    @Published var energyEntries: [EnergyEntry] = []
    @Published var sessions: [RhythmSession] = []
    @Published var playlists: [PulsePlaylist] = []
    @Published var trackNotes: [TrackNote] = []
    @Published var focusSessions: [FocusSession] = []
    @Published var savedThemes: [NeonTheme] = NeonTheme.defaults

    private var focusTimer: AnyCancellable?
    private let storageKey_energy   = "pulse_energy_entries"
    private let storageKey_sessions = "pulse_sessions"
    private let storageKey_playlists = "pulse_playlists"
    private let storageKey_notes    = "pulse_track_notes"
    private let storageKey_focus    = "pulse_focus_sessions"
    private let storageKey_themes   = "pulse_saved_themes"

    init() {
        loadAll()
        if energyEntries.isEmpty {
            seedSampleData()
        }
        updateTheme()
    }

    // MARK: - Theme
    func updateTheme() {
        if selectedThemeIndex < savedThemes.count {
            activeTheme = savedThemes[selectedThemeIndex]
        }
    }

    // MARK: - Energy
    func addEnergyEntry(level: Double, mood: Mood, note: String = "") {
        let entry = EnergyEntry(date: Date(), level: level, mood: mood, note: note)
        energyEntries.append(entry)
        saveEnergy()
    }

    func updateCurrentEnergy(_ level: Double) {
        currentEnergyLevel = level
        addEnergyEntry(level: level, mood: currentMood)
    }

    // MARK: - Sessions
    func addSession(_ session: RhythmSession) {
        sessions.insert(session, at: 0)
        saveSessions()
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        saveSessions()
    }

    // MARK: - Playlists
    func addPlaylist(_ playlist: PulsePlaylist) {
        playlists.insert(playlist, at: 0)
        savePlaylists()
    }

    func deletePlaylist(id: UUID) {
        playlists.removeAll { $0.id == id }
        savePlaylists()
    }

    func updatePlaylist(_ playlist: PulsePlaylist) {
        if let idx = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[idx] = playlist
            savePlaylists()
        }
    }

    // MARK: - Track Notes
    func addTrackNote(_ note: TrackNote) {
        trackNotes.insert(note, at: 0)
        saveNotes()
    }

    func deleteTrackNote(id: UUID) {
        trackNotes.removeAll { $0.id == id }
        saveNotes()
    }

    // MARK: - Focus Timer
    func startFocusTimer(duration: Int) {
        focusTimerSeconds = duration * 60
        isFocusTimerRunning = true
        focusTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.focusTimerSeconds > 0 {
                    self.focusTimerSeconds -= 1
                } else {
                    self.stopFocusTimer()
                }
            }
    }

    func stopFocusTimer() {
        focusTimer?.cancel()
        isFocusTimerRunning = false
        audio.stop()
    }

    func pauseFocusTimer() {
        if isFocusTimerRunning {
            focusTimer?.cancel()
            isFocusTimerRunning = false
        } else {
            isFocusTimerRunning = true
            focusTimer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    if self.focusTimerSeconds > 0 {
                        self.focusTimerSeconds -= 1
                    } else {
                        self.stopFocusTimer()
                    }
                }
        }
    }

    // MARK: - Themes
    func saveCustomTheme(_ theme: NeonTheme) {
        savedThemes.append(theme)
        saveThemes()
    }

    func applyTheme(_ index: Int) {
        selectedThemeIndex = index
        activeTheme = savedThemes[index]
    }

    // MARK: - Stats
    func getStatsSummary(days: Int = 7) -> StatsSummary {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let recentSessions = sessions.filter { $0.date > cutoff }
        let recentFocus = focusSessions.filter { $0.date > cutoff && $0.isCompleted }

        var moodCounts: [Mood: Int] = [:]
        recentSessions.forEach { moodCounts[$0.mood, default: 0] += 1 }
        let topMood = moodCounts.max(by: { $0.value < $1.value })?.key ?? .focus

        let totalMinutes = recentSessions.reduce(0) { $0 + $1.duration }
        let recentEnergy = energyEntries.filter { $0.date > cutoff }
        let avgEnergy = recentEnergy.isEmpty ? 0.6 : recentEnergy.map(\.level).reduce(0, +) / Double(recentEnergy.count)

        return StatsSummary(
            minutesListened: totalMinutes,
            moodUsage: moodCounts,
            focusSessions: recentFocus.count,
            avgEnergyLevel: avgEnergy,
            topMood: topMood,
            streakDays: calculateStreak()
        )
    }

    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        for _ in 0..<30 {
            let hasEntry = energyEntries.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if hasEntry {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    func todaySessions() -> [RhythmSession] {
        sessions.filter { Calendar.current.isDateInToday($0.date) }
    }

    func weekEnergyData() -> [EnergyEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return energyEntries.filter { $0.date > cutoff }
    }

    // MARK: - Persistence
    private func loadAll() {
        energyEntries   = load(key: storageKey_energy)   ?? []
        sessions        = load(key: storageKey_sessions) ?? []
        playlists       = load(key: storageKey_playlists) ?? []
        trackNotes      = load(key: storageKey_notes)    ?? []
        focusSessions   = load(key: storageKey_focus)    ?? []
        let themes: [NeonTheme]? = load(key: storageKey_themes)
        savedThemes     = themes ?? NeonTheme.defaults
    }

    private func load<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else { return nil }
        return decoded
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func saveEnergy()    { save(energyEntries, key: storageKey_energy) }
    private func saveSessions()  { save(sessions, key: storageKey_sessions) }
    private func savePlaylists() { save(playlists, key: storageKey_playlists) }
    private func saveNotes()     { save(trackNotes, key: storageKey_notes) }
    private func saveThemes()    { save(savedThemes, key: storageKey_themes) }

    private func seedSampleData() {
        energyEntries = EnergyEntry.sampleWeek()
        sessions = [
            RhythmSession(name: "Morning Focus", mood: .focus, duration: 25, intensity: 0.7, genre: .ambient, date: Date().addingTimeInterval(-3600), isCompleted: true, energyBefore: 0.4, energyAfter: 0.8),
            RhythmSession(name: "Afternoon Chill", mood: .chill, duration: 30, intensity: 0.3, genre: .lofi, date: Date().addingTimeInterval(-7200), isCompleted: true, energyBefore: 0.7, energyAfter: 0.5),
            RhythmSession(name: "Energy Boost", mood: .energy, duration: 20, intensity: 0.9, genre: .electronic, date: Date().addingTimeInterval(-86400), isCompleted: true, energyBefore: 0.3, energyAfter: 0.9),
        ]
        playlists = [
            PulsePlaylist(name: "Deep Focus Flow", mood: .focus, duration: 45, tracksCount: 8, intensity: 0.6, genre: .ambient, createdAt: Date(), tracks: []),
            PulsePlaylist(name: "Midnight Chill", mood: .night, duration: 60, tracksCount: 12, intensity: 0.2, genre: .ambient, createdAt: Date(), tracks: []),
        ]
        saveEnergy(); saveSessions(); savePlaylists()
    }
}

enum SessionType {
    case none, focus, relax, energy
}

@MainActor
final class PulseWaveViewModel: ObservableObject {
        
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    
    private let coordinator: WaveCoordinator
    private var cancellables = Set<AnyCancellable>()
    @Published var showOfflineView = false
    private var deadlineTask: Task<Void, Never>?
    
    private var uiLocked: Bool = false
    
    init() {
        self.coordinator = WaveCoordinator()
        wireUp()
    }
    
    deinit {
        deadlineTask?.cancel()
    }
    
    func acceptConsent() {
        coordinator.acceptConsent {
            self.showPermissionPrompt = false
            return true
        }
    }
    
    func boot() {
        coordinator.warmUp()
        armDeadline()
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        Task {
            coordinator.ingestSignals(data)
            await coordinator.surf()
        }
    }
    
    private func wireUp() {
        coordinator.outcomePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outcome in
                self?.handleOutcome(outcome)
            }
            .store(in: &cancellables)
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleOutcome(_ outcome: WaveOutcome) {
        guard !uiLocked else {
            return
        }
        
        switch outcome {
        case .adrift:
            break
        case .requestConsent:
            showPermissionPrompt = true
        case .openBuoy:
            navigateToWeb = true
        case .driftedToShore:
            navigateToMain = true
        }
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        coordinator.ingestEchoes(data)
    }
    
    func skipConsent() {
        coordinator.deferConsent()
        showPermissionPrompt = false
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            
            let shouldFire = self.coordinator.reportTideExpired()
            if shouldFire {
                self.handleOutcome(.driftedToShore)
            }
        }
    }
}
