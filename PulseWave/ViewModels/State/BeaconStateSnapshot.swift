import Combine
import Foundation

struct BeaconStateSnapshot {
    var signals: [String: String] = [:]
    var echoes: [String: String] = [:]
    var buoyURL: String? = nil
    var buoyMode: String? = nil
    var stillness: Bool = true
    var anchored: Bool = false
    var rippleHandled: Bool = false
    var consentRipple: Bool = false
    var consentDamped: Bool = false
    var consentTracedAt: Date? = nil
    
    var signalsReady: Bool { !signals.isEmpty }
    var organicCurrent: Bool { signals["af_status"] == "Organic" }
    
    var consentRipe: Bool {
        guard !consentRipple && !consentDamped else { return false }
        if let date = consentTracedAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
    
    static func hydrate(from record: BeaconRecord) -> BeaconStateSnapshot {
        var snap = BeaconStateSnapshot()
        snap.signals = record.signals
        snap.echoes = record.echoes
        snap.buoyURL = record.buoyURL
        snap.buoyMode = record.buoyMode
        snap.stillness = record.stillness
        snap.consentRipple = record.consentRipple
        snap.consentDamped = record.consentDamped
        snap.consentTracedAt = record.consentTracedAt
        return snap
    }
    
    func freeze() -> BeaconRecord {
        BeaconRecord(
            signals: signals, echoes: echoes,
            buoyURL: buoyURL, buoyMode: buoyMode,
            stillness: stillness,
            consentRipple: consentRipple, consentDamped: consentDamped,
            consentTracedAt: consentTracedAt
        )
    }
}
