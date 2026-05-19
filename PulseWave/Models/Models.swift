import Foundation
import SwiftUI

// MARK: - Energy Entry
struct EnergyEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var level: Double   // 0.0 - 1.0
    var mood: Mood
    var note: String

    static func sampleWeek() -> [EnergyEntry] {
        let calendar = Calendar.current
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            return EnergyEntry(
                date: date,
                level: Double.random(in: 0.3...1.0),
                mood: Mood.allCases.randomElement()!,
                note: ""
            )
        }.reversed()
    }
}

// MARK: - Rhythm Session
struct RhythmSession: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var mood: Mood
    var duration: Int       // minutes
    var intensity: Double   // 0.0 - 1.0
    var genre: Genre
    var date: Date
    var isCompleted: Bool
    var energyBefore: Double
    var energyAfter: Double

    var durationText: String {
        "\(duration) min"
    }
}

// MARK: - Playlist
struct PulsePlaylist: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var mood: Mood
    var duration: Int   // minutes
    var tracksCount: Int
    var intensity: Double
    var genre: Genre
    var createdAt: Date
    var tracks: [TrackNote]

    var intensityLabel: String {
        switch intensity {
        case 0..<0.33: return "Low"
        case 0.33..<0.66: return "Medium"
        default: return "High"
        }
    }
}

// MARK: - Track Note
struct TrackNote: Identifiable, Codable {
    var id: UUID = UUID()
    var trackName: String
    var moodNote: String
    var rating: Int  // 1-5
    var mood: Mood
    var date: Date
}

// MARK: - Focus Session
struct FocusSession: Identifiable, Codable {
    var id: UUID = UUID()
    var duration: Int   // minutes
    var soundType: SoundType
    var date: Date
    var isCompleted: Bool
    var elapsedSeconds: Int
}

// MARK: - Enums
enum Genre: String, CaseIterable, Codable {
    case electronic = "Electronic"
    case ambient    = "Ambient"
    case hiphop     = "Hip-Hop"
    case classical  = "Classical"
    case jazz       = "Jazz"
    case rock       = "Rock"
    case lofi       = "Lo-Fi"
    case nature     = "Nature"
    case binaural   = "Binaural Beats"
}

enum SoundType: String, CaseIterable, Codable {
    case binaural   = "Binaural Beats"
    case lofi       = "Lo-Fi"
    case ambient    = "Ambient"
    case nature     = "Nature Sounds"
    case whitenoise = "White Noise"
    case classical  = "Classical"

    var icon: String {
        switch self {
        case .binaural:   return "waveform.path.ecg"
        case .lofi:       return "music.note"
        case .ambient:    return "cloud.fill"
        case .nature:     return "leaf.fill"
        case .whitenoise: return "waveform"
        case .classical:  return "music.quarternote.3"
        }
    }
}

// MARK: - Neon Theme
struct NeonTheme: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var primaryHex: String
    var secondaryHex: String
    var animationSpeed: Double  // 0.5 - 2.0

    var primaryColor: Color { Color(hex: primaryHex) }
    var secondaryColor: Color { Color(hex: secondaryHex) }

    static let defaults: [NeonTheme] = [
        NeonTheme(name: "Violet Dream", primaryHex: "#8B5CF6", secondaryHex: "#EC4899", animationSpeed: 1.0),
        NeonTheme(name: "Ocean Flow", primaryHex: "#22D3EE", secondaryHex: "#6366F1", animationSpeed: 0.8),
        NeonTheme(name: "Fire Energy", primaryHex: "#F97316", secondaryHex: "#EC4899", animationSpeed: 1.4),
        NeonTheme(name: "Night Forest", primaryHex: "#10B981", secondaryHex: "#22D3EE", animationSpeed: 0.6),
    ]
}

// MARK: - Stats Summary
struct StatsSummary {
    var minutesListened: Int
    var moodUsage: [Mood: Int]
    var focusSessions: Int
    var avgEnergyLevel: Double
    var topMood: Mood
    var streakDays: Int
}
