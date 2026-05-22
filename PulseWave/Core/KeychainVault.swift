import Foundation
import Security

protocol BeaconVault {
    func stash(_ record: BeaconRecord)
    func stashBuoy(url: String, mode: String)
    func markPrimed()
    func thaw() -> BeaconRecord
}

final class KeychainBeaconVault: BeaconVault {
    
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults
    
    init() {
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: BeaconConstants.suiteBeacon) ?? .standard
    }
    
    func stash(_ record: BeaconRecord) {
        let veiled = VeiledBeacon(
            signals: veilDict(record.signals),
            echoes: veilDict(record.echoes),
            buoyURL: record.buoyURL,
            buoyMode: record.buoyMode,
            stillness: record.stillness,
            consentRipple: record.consentRipple,
            consentDamped: record.consentDamped,
            consentTracedAt: record.consentTracedAt
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        do {
            let data = try encoder.encode(veiled)
            writeToKeychain(data: data)
        } catch {
            print("\(BeaconConstants.logRipple) Stash encode failed: \(error)")
        }
    }
    
    func stashBuoy(url: String, mode: String) {
        suiteStore.set(url, forKey: BeaconKey.buoyURL)
        homeStore.set(url, forKey: BeaconKey.buoyURL)
        suiteStore.set(mode, forKey: BeaconKey.buoyMode)
    }
    
    func markPrimed() {
        suiteStore.set(true, forKey: BeaconKey.primed)
        homeStore.set(true, forKey: BeaconKey.primed)
    }
    
    // MARK: - Thaw
    
    func thaw() -> BeaconRecord {
        guard let data = readFromKeychain() else {
            return fallback()
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        do {
            let veiled = try decoder.decode(VeiledBeacon.self, from: data)
            return BeaconRecord(
                signals: unveilDict(veiled.signals),
                echoes: unveilDict(veiled.echoes),
                buoyURL: veiled.buoyURL,
                buoyMode: veiled.buoyMode,
                stillness: veiled.stillness,
                consentRipple: veiled.consentRipple,
                consentDamped: veiled.consentDamped,
                consentTracedAt: veiled.consentTracedAt
            )
        } catch {
            print("\(BeaconConstants.logRipple) Thaw decode failed: \(error)")
            return fallback()
        }
    }
    
    private func fallback() -> BeaconRecord {
        let buoyURL = homeStore.string(forKey: BeaconKey.buoyURL)
            ?? suiteStore.string(forKey: BeaconKey.buoyURL)
        let buoyMode = suiteStore.string(forKey: BeaconKey.buoyMode)
        let primed = suiteStore.bool(forKey: BeaconKey.primed)
        
        return BeaconRecord(
            signals: [:], echoes: [:],
            buoyURL: buoyURL, buoyMode: buoyMode,
            stillness: !primed,
            consentRipple: false, consentDamped: false, consentTracedAt: nil
        )
    }
    
    // MARK: - Keychain primitives
    
    private func writeToKeychain(data: Data) {
        // Удаляем существующую запись
        let delete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: BeaconConstants.keychainService,
            kSecAttrAccount as String: BeaconConstants.keychainAccount
        ]
        SecItemDelete(delete as CFDictionary)
        
        // Добавляем новую
        let add: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: BeaconConstants.keychainService,
            kSecAttrAccount as String: BeaconConstants.keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemAdd(add as CFDictionary, nil)
        if status != errSecSuccess {
            print("\(BeaconConstants.logRipple) Keychain add status: \(status)")
        }
    }
    
    private func readFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: BeaconConstants.keychainService,
            kSecAttrAccount as String: BeaconConstants.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return data
    }
    
    // MARK: - Veiling
    
    private func veilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = veil(v) }
        return result
    }
    
    private func unveilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = unveil(v) ?? v }
        return result
    }
    
    private func veil(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "+", with: "(")
            .replacingOccurrences(of: "/", with: "*")
    }
    
    private func unveil(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "(", with: "+")
            .replacingOccurrences(of: "*", with: "/")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

// MARK: - Veiled Beacon

struct VeiledBeacon: Codable {
    let signals: [String: String]
    let echoes: [String: String]
    let buoyURL: String?
    let buoyMode: String?
    let stillness: Bool
    let consentRipple: Bool
    let consentDamped: Bool
    let consentTracedAt: Date?
}
