import Foundation

struct StripLog: Codable {
    let pulse: [String: String]
    let traces: [String: String]
    let feedURL: String?
    let feedMode: String?
    let resting: Bool
    let consentPaced: Bool
    let consentFlat: Bool
    let consentTapAt: Date?
}

struct Strip {
    var pulse: [String: String] = [:]
    var traces: [String: String] = [:]
    var feedURL: String? = nil
    var feedMode: String? = nil
    var resting: Bool = true
    var charted: Bool = false
    var amplified: Bool = false
    var consentPaced: Bool = false
    var consentFlat: Bool = false
    var consentTapAt: Date? = nil

    var pulsePresent: Bool { !pulse.isEmpty }
    var organicArrhythmia: Bool { pulse["af_status"] == "Organic" }

    var consentRipe: Bool {
        guard !consentPaced && !consentFlat else { return false }
        if let date = consentTapAt {
            return Date().timeIntervalSince(date) / 86400 >= 3
        }
        return true
    }

    static func chart(from log: StripLog) -> Strip {
        var s = Strip()
        s.pulse = log.pulse
        s.traces = log.traces
        s.feedURL = log.feedURL
        s.feedMode = log.feedMode
        s.resting = log.resting
        s.consentPaced = log.consentPaced
        s.consentFlat = log.consentFlat
        s.consentTapAt = log.consentTapAt
        return s
    }

    func log() -> StripLog {
        StripLog(
            pulse: pulse,
            traces: traces,
            feedURL: feedURL,
            feedMode: feedMode,
            resting: resting,
            consentPaced: consentPaced,
            consentFlat: consentFlat,
            consentTapAt: consentTapAt
        )
    }
}

enum Reading: Equatable {
    case tracing
    case promptConsent
    case goLive
    case flatline
}
