import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var boot: BootConfiguration!
    private let signalKnitter = SignalKnitter()
    private let echoChaser = EchoChaser()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        signalKnitter.relaySignals = { [weak self] data in
            self?.broadcastSignals(data)
        }
        signalKnitter.relayEchoes = { [weak self] data in
            self?.broadcastEchoes(data)
        }
        
        boot = BootBuilder()
            .withFirebase()
            .withMessaging(delegate: self, notificationDelegate: self)
            .withAppsFlyer(delegate: self, deepLinkDelegate: self)
            .build()
        
        boot.execute()
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            echoChaser.chase(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        boot.kickstart()
    }
    
    private func broadcastSignals(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func broadcastEchoes(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            UserDefaults.standard.set(t, forKey: BeaconKey.fcm)
            UserDefaults.standard.set(t, forKey: BeaconKey.push)
            UserDefaults(suiteName: BeaconConstants.suiteBeacon)?.set(t, forKey: "shared_fcm")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        echoChaser.chase(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        echoChaser.chase(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        echoChaser.chase(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        signalKnitter.acceptSignals(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        signalKnitter.acceptSignals([
            "error": true,
            "error_desc": error.localizedDescription
        ])
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        signalKnitter.acceptEchoes(link.clickEvent)
    }
}

final class BootConfiguration {
    
    var executors: [() -> Void] = []
    var kickstarter: (() -> Void)?
    
    func execute() {
        for executor in executors {
            executor()
        }
    }
    
    func kickstart() {
        kickstarter?()
    }
}

final class BootBuilder {
    
    private let config = BootConfiguration()
    
    @discardableResult
    func withFirebase() -> BootBuilder {
        config.executors.append {
            FirebaseApp.configure()
        }
        return self
    }
    
    @discardableResult
    func withMessaging(
        delegate: MessagingDelegate,
        notificationDelegate: UNUserNotificationCenterDelegate
    ) -> BootBuilder {
        config.executors.append { [weak delegate, weak notificationDelegate] in
            Messaging.messaging().delegate = delegate
            UNUserNotificationCenter.current().delegate = notificationDelegate
            UIApplication.shared.registerForRemoteNotifications()
        }
        return self
    }
    
    @discardableResult
    func withAppsFlyer(
        delegate: AppsFlyerLibDelegate,
        deepLinkDelegate: DeepLinkDelegate
    ) -> BootBuilder {
        config.executors.append { [weak delegate, weak deepLinkDelegate] in
            let sdk = AppsFlyerLib.shared()
            sdk.appsFlyerDevKey = BeaconConstants.trackerKey
            sdk.appleAppID = BeaconConstants.appCode
            sdk.delegate = delegate
            sdk.deepLinkDelegate = deepLinkDelegate
            sdk.isDebug = false
        }
        
        config.kickstarter = {
            if #available(iOS 14, *) {
                AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
                ATTrackingManager.requestTrackingAuthorization { status in
                    DispatchQueue.main.async {
                        AppsFlyerLib.shared().start()
                        UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                    }
                }
            } else {
                AppsFlyerLib.shared().start()
            }
        }
        return self
    }
    
    func build() -> BootConfiguration {
        return config
    }
}

final class SignalKnitter: NSObject {
    
    var relaySignals: (([AnyHashable: Any]) -> Void)?
    var relayEchoes: (([AnyHashable: Any]) -> Void)?
    
    private var signalsBuffer: [AnyHashable: Any] = [:]
    private var echoesBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func acceptSignals(_ data: [AnyHashable: Any]) {
        signalsBuffer = data
        scheduleFuse()
        if !echoesBuffer.isEmpty { performFuse() }
    }
    
    func acceptEchoes(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: BeaconKey.primed) else { return }
        echoesBuffer = data
        relayEchoes?(data)
        fuseTimer?.invalidate()
        if !signalsBuffer.isEmpty { performFuse() }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = signalsBuffer
        for (k, v) in echoesBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        relaySignals?(combined)
    }
}

final class EchoChaser: NSObject {
    
    func chase(_ payload: [AnyHashable: Any]) {
        guard let url = extract(payload) else { return }
        UserDefaults.standard.set(url, forKey: BeaconKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func extract(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String { return url }
        return nil
    }
}
