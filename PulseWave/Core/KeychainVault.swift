import Foundation

protocol Records {
    func file(_ log: StripLog)
    func markFeed(url: String, mode: String)
    func raisePrimedFlag()
    func pull() -> StripLog
}

final class WardRecords: Records {

    private let fm = FileManager.default
    private let vaultDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.vaultDir = docs.appendingPathComponent(Vitals.monitorVault, isDirectory: true)
        if !fm.fileExists(atPath: vaultDir.path) {
            try? fm.createDirectory(at: vaultDir, withIntermediateDirectories: true)
        }
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: Vitals.suiteMonitor) ?? .standard
    }

    private var stripURL: URL {
        vaultDir.appendingPathComponent(Vitals.stripFile)
    }

    func file(_ log: StripLog) {
        let noisy = NoisyLog(
            pulse: noiseMap(log.pulse),
            traces: noiseMap(log.traces),
            feedURL: log.feedURL,
            feedMode: log.feedMode,
            resting: log.resting,
            consentPaced: log.consentPaced,
            consentFlat: log.consentFlat,
            consentTapAt: log.consentTapAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970

        do {
            let data = try encoder.encode(noisy)
            try data.write(to: stripURL, options: .atomic)
        } catch {
            print("\(Vitals.logHeart) Records file failed: \(error)")
        }

        for store in [suiteStore, homeStore] {
            store.set(log.consentPaced, forKey: VitalsKey.consentPaced)
            store.set(log.consentFlat, forKey: VitalsKey.consentFlat)
            if let date = log.consentTapAt {
                store.set(date.timeIntervalSince1970, forKey: VitalsKey.consentTapAt)
            }
        }
    }

    func markFeed(url: String, mode: String) {
        suiteStore.set(url, forKey: VitalsKey.feedURL)
        homeStore.set(url, forKey: VitalsKey.feedURL)
        suiteStore.set(mode, forKey: VitalsKey.feedMode)
    }

    func raisePrimedFlag() {
        suiteStore.set(true, forKey: VitalsKey.primed)
        homeStore.set(true, forKey: VitalsKey.primed)
    }

    func pull() -> StripLog {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        if fm.fileExists(atPath: stripURL.path),
           let data = try? Data(contentsOf: stripURL),
           let noisy = try? decoder.decode(NoisyLog.self, from: data) {
            return StripLog(
                pulse: cleanMap(noisy.pulse),
                traces: cleanMap(noisy.traces),
                feedURL: noisy.feedURL,
                feedMode: noisy.feedMode,
                resting: noisy.resting,
                consentPaced: noisy.consentPaced,
                consentFlat: noisy.consentFlat,
                consentTapAt: noisy.consentTapAt
            )
        }

        return pullFromMirror()
    }

    private func pullFromMirror() -> StripLog {
        let feedURL = homeStore.string(forKey: VitalsKey.feedURL)
            ?? suiteStore.string(forKey: VitalsKey.feedURL)
        let feedMode = suiteStore.string(forKey: VitalsKey.feedMode)
        let primed = suiteStore.bool(forKey: VitalsKey.primed)

        let paced = suiteStore.bool(forKey: VitalsKey.consentPaced)
            || homeStore.bool(forKey: VitalsKey.consentPaced)
        let flat = suiteStore.bool(forKey: VitalsKey.consentFlat)
            || homeStore.bool(forKey: VitalsKey.consentFlat)
        let tapTs = suiteStore.double(forKey: VitalsKey.consentTapAt)
        let tapAt: Date? = tapTs > 0 ? Date(timeIntervalSince1970: tapTs) : nil

        return StripLog(
            pulse: [:],
            traces: [:],
            feedURL: feedURL,
            feedMode: feedMode,
            resting: !primed,
            consentPaced: paced,
            consentFlat: flat,
            consentTapAt: tapAt
        )
    }

    private func noiseMap(_ dict: [String: String]) -> [String: String] {
        dict.reduce(into: [:]) { acc, pair in acc[pair.key] = addNoise(pair.value) }
    }

    private func cleanMap(_ dict: [String: String]) -> [String: String] {
        dict.reduce(into: [:]) { acc, pair in acc[pair.key] = clean(pair.value) ?? pair.value }
    }

    private func addNoise(_ input: String) -> String {
        Data(input.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "%")
            .replacingOccurrences(of: "/", with: ".")
    }

    private func clean(_ input: String) -> String? {
        let restored = input
            .replacingOccurrences(of: "%", with: "+")
            .replacingOccurrences(of: ".", with: "/")
        guard let data = Data(base64Encoded: restored),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

struct NoisyLog: Codable {
    let pulse: [String: String]
    let traces: [String: String]
    let feedURL: String?
    let feedMode: String?
    let resting: Bool
    let consentPaced: Bool
    let consentFlat: Bool
    let consentTapAt: Date?
}
