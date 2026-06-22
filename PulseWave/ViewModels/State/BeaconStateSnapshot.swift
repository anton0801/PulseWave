import Foundation
import UIKit
import UserNotifications

protocol Pager {
    func page() async -> Bool
    func armPager()
}

final class WardPager: Pager {

    func page() async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let buzzer = OneBuzzer()
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                if let error = error {
                    print("\(Vitals.logHeart) Pager error: \(error)")
                }
                DispatchQueue.main.async {
                    guard buzzer.ring() else { return }
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func armPager() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

final class OneBuzzer {
    private var rang = false
    private let lock = NSLock()

    func ring() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !rang else { return false }
        rang = true
        return true
    }
}
