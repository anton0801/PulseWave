import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

protocol Telemeter {
    func relay(vitals: [String: Any]) async throws -> String
}

final class WardTelemeter: Telemeter {

    private let session: URLSession
    private let baseGap: Double = 89.0
    private let ceiling: Int = 3

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    private var agent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""

    func relay(vitals: [String: Any]) async throws -> String {
        let request = try chartRequest(vitals)

        var wait = baseGap
        var tries = 0
        var last: Error? = nil

        while tries < ceiling {
            do {
                return try await sample(request)
            } catch let beat as Arrhythmia where beat.isSealed {
                throw beat
            } catch let beat as Arrhythmia {
                if case .flutter(let cooldown) = beat {
                    try await rest(cooldown)
                    tries += 1
                    continue
                }
                last = beat
                tries += 1
                if tries < ceiling {
                    try await rest(wait)
                    wait *= 2
                }
            } catch {
                last = error
                tries += 1
                if tries < ceiling {
                    try await rest(wait)
                    wait *= 2
                }
            }
        }

        throw last ?? Arrhythmia.noPulse(stage: "telemeter.exhausted")
    }

    private func chartRequest(_ vitals: [String: Any]) throws -> URLRequest {
        guard let endpoint = URL(string: Vitals.stationEndpoint) else {
            throw Arrhythmia.crossedLead(at: "telemeter.url")
        }

        var body: [String: Any] = vitals
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(Vitals.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: VitalsKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(agent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func sample(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw Arrhythmia.noPulse(stage: "telemeter.response")
        }

        if http.statusCode == 404 {
            throw Arrhythmia.asystole(httpCode: 404)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Arrhythmia.garbledTrace(at: "telemeter.json")
        }

        guard let ok = json["ok"] as? Bool else {
            throw Arrhythmia.garbledTrace(at: "telemeter.missingOk")
        }

        guard ok else {
            throw Arrhythmia.stationDown(reason: "okFalse")
        }

        guard let url = json["url"] as? String, !url.isEmpty else {
            throw Arrhythmia.garbledTrace(at: "telemeter.missingURL")
        }

        return url
    }

    private func rest(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
