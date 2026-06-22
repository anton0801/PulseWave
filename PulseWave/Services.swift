import Foundation

protocol Lead {
    func pickup(deviceID: String) async throws -> [String: Any]
}

final class SensorLead: Lead {

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    func pickup(deviceID: String) async throws -> [String: Any] {
        var comps = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(Vitals.appCode)")
        comps?.queryItems = [
            URLQueryItem(name: "devkey", value: Vitals.leadKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]

        guard let url = comps?.url else {
            throw Arrhythmia.crossedLead(at: "lead.url")
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (bytes, response) = try await session.bytes(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw Arrhythmia.noPulse(stage: "lead.http")
        }

        var buffer = Data()
        for try await chunk in bytes {
            buffer.append(chunk)
        }

        guard let json = try JSONSerialization.jsonObject(with: buffer) as? [String: Any] else {
            throw Arrhythmia.garbledTrace(at: "lead.json")
        }

        return json
    }
}
