import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications

protocol VoltageProbe {
    func probe() async throws -> Bool
}

protocol AttributionFetcher {
    func fetch(deviceID: String) async throws -> [String: Any]
}

protocol BuoyLocator {
    func locate(seed: [String: Any]) async throws -> String
}

protocol ConsentEcho {
    func echo() -> Promise<Bool>
    func armPushTransmitter()
}

final class SupabaseVoltageProbe: VoltageProbe {
    
    func probe() async throws -> Bool {
        return true
    }
}

final class NotificationConsentEcho: ConsentEcho {
    
    func echo() -> Promise<Bool> {
        Promise<Bool> { resolve, reject in
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                if let error = error {
                }
                DispatchQueue.main.async {
                    resolve(granted)
                }
            }
        }
    }
    
    func armPushTransmitter() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

struct FunctionDI {
    let vaultProvider: () -> BeaconVault
    let probeProvider: () -> VoltageProbe
    let fetcherProvider: () -> AttributionFetcher
    let locatorProvider: () -> BuoyLocator
    let echoProvider: () -> ConsentEcho
    
    static func production() -> FunctionDI {
        let vault: BeaconVault = KeychainBeaconVault()
        let probe: VoltageProbe = SupabaseVoltageProbe()
        let fetcher: AttributionFetcher = AppsFlyerAttributionFetcher()
        let locator: BuoyLocator = HTTPBuoyLocator()
        let echo: ConsentEcho = NotificationConsentEcho()
        
        return FunctionDI(
            vaultProvider: { vault },
            probeProvider: { probe },
            fetcherProvider: { fetcher },
            locatorProvider: { locator },
            echoProvider: { echo }
        )
    }
}
